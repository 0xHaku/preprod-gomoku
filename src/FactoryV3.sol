// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./IGomokuToken.sol";
import "./Gomoku.sol";
import "./Judger.sol";

/// @title factory of gomoku-game
/// @author 0xHaku
/// @notice You can use this contract for launch and play gomoku-game
contract FactoryV3 is Gomoku, Initializable, UUPSUpgradeable {

    uint256 public constant PLAYFEE = 0.01 ether;
    uint256 public constant WINPRIZEETH = 0.015 ether;
    uint256 public constant WINFACTORYFEE = 0.005 ether;
    uint256 public constant WINPRIZEOMOKU = 1e20;
    uint256 public constant DRAWFEE = 0.02 ether;

    Judger judger;

    /// @dev games are identified by gameId
    Game[] games;

    address public owner;

    IGomokuToken public gomokuToken;

    /// @notice Set the initial value when the contruct is launched
    /// @dev Performed during UUPS deployment
    /// @param gomokuToken_ gomokutoken
    function initialize(address gomokuToken_) public initializer {
        judger = new Judger();
        gomokuToken = IGomokuToken(gomokuToken_);
        owner = msg.sender;
    }

    /// @notice Number of times this contraption has been improved.
    /// @dev Incremented each time a UUPS upgrade is performed
    /// @return version actual version
    function version() external pure returns(uint256) {
        return 3;
    }

    /// @notice You can pay fee and get the game up and running.
    /// @dev Create a game instance and push it to the games array
    /// @return gameId Identify launched games
    function createGame() external payable returns(uint256) {
        if (msg.value != PLAYFEE) revert("diferent play fee");

        uint256 gameId = games.length;

        Game memory game;
        games.push(game);

        _entryPlayer(gameId, true);
        _changeGameStatus(gameId, Status.STANDBY);
        
        return gameId;
    }

    /// @notice You can specify the gameId you want to join and pay fee to join.
    /// @param gameId_ gameId you would like to participate in
    function entryGame(uint256 gameId_) external payable gameExists(gameId_) {
        if (msg.value != PLAYFEE) revert("diferent play fee");

        Game storage game = games[gameId_];
        if (game.status != Status.STANDBY) revert("status not standby");
        if (game.player1 == msg.sender) revert("same as player1");

        _entryPlayer(gameId_, false);
        _changeGameStatus(gameId_, Status.OPEN);
    }

    /// @notice Get the current game information of the specified gameId
    /// @dev Game strust is in Gomoku.sol
    /// @param gameId you would like to get
    /// @return game Game strust
    function getGame(uint256 gameId_) public view gameExists(gameId_) returns(Game memory) {
        return games[gameId_];
    }

    /// @notice Place a stone on the board and judge who wins or loses
    /// @param gameId_ you would like to play
    /// @param row_ Row where you want to place the stone
    /// @param column_ Column where you want to place the stone
    function play(uint256 gameId_, int8 row_, int8 column_) external gameExists(gameId_) {

        // check input range
        if (row_ < 0 || row_ >= MEASURE_MAX_NUM) revert("row outbound");
        if (column_ < 0 || column_ >= MEASURE_MAX_NUM) revert("column outbound");

        Game storage game;
        bool isBlack;
        Stone color;
        address turnPlayer;
        uint8 fixedRow;
        uint8 fixedColumn;
        Judge res;

        game = games[gameId_];

        if (game.status != Status.OPEN) revert("status not open");

        // deterimine turn player
        isBlack = game.board.stoneCount % 2 == 0;
        color = isBlack ? Stone.BLACK : Stone.WHITE; 
        turnPlayer = isBlack ? game.player1 : game.player2;

        if (msg.sender != turnPlayer) revert("not your turn");

        // posess the stone
        fixedRow = uint8(row_);
        fixedColumn= uint8(column_);

        if (game.board.board[fixedRow][fixedColumn] != uint8(Stone.ENPTY)) revert("stone already exists");
        
        game.board.board[fixedRow][fixedColumn] = uint8(color);
        
        if (type(uint8).max != game.board.stoneCount) {
            game.board.stoneCount++;
        }

        emit stonePosessed(gameId_, row_, column_, color);

        // judge the board
        res = judger.judge(game.board, row_, column_);

        // broadcast the game's result
        if (res != Judge.CONTINUE) {
            _changeGameStatus(gameId_, Status.CLOSE);
            if (res == Judge.WIN) {
                payable(turnPlayer).transfer(WINPRIZEETH);
                payable(owner).transfer(WINFACTORYFEE);
                gomokuToken.mint(turnPlayer, WINPRIZEOMOKU);
                emit gameResultFinalized(gameId_, res, turnPlayer);
            } else {
                payable(owner).transfer(DRAWFEE);
                emit gameResultFinalized(gameId_, res, address(0));
            }
        }
    }

    /// @notice Surrender in the game specified.
    /// @dev Win a player who is not the player who surrendered
    /// @param gameId_ you would like to resign
    function resign(uint256 gameId_) external gameExists(gameId_) {
        Game storage game = games[gameId_];

        if (game.status != Status.OPEN) revert("status not open");
        if (msg.sender != game.player1 && msg.sender != game.player2) revert("not player");

        _changeGameStatus(gameId_, Status.CLOSE);
        if (msg.sender == game.player1) {
            emit gameResultFinalized(gameId_, Judge.WIN, game.player2);
        } else {
            emit gameResultFinalized(gameId_, Judge.WIN, game.player1);
        }
    }

    /// @notice Continue only when the specified gameId exists
    /// @param gameId_ you would like to check
    modifier gameExists(uint256 gameId_) {
        if (gameId_ >= games.length) revert("game not exist");
        _;
    }

    /// @notice Enter the specified game
    /// @dev Depending on whether you are the first or the second player, you can register at different places.
    /// @param gameId_ you would like to entry
    /// @param isBlack_ Flag whether the first move is made or not.
    function _entryPlayer(uint256 gameId_, bool isBlack_) internal {
        if (isBlack_) {
            games[gameId_].player1 = msg.sender;
        } else {
            games[gameId_].player2 = msg.sender;
        }

        emit gameEntered(gameId_, isBlack_, msg.sender);
    }

    /// @notice Change the status of the game specified by gameId to the specified one.
    /// @param gameId_ you would like to change
    /// @param status_ 
    function _changeGameStatus(uint256 gameId_, Status status_) internal {
        games[gameId_].status = status_;

        emit gameStatusChanged(gameId_, status_);
    }

    function _authorizeUpgrade(address) internal override {}

    /// @notice Set the initial value when the contruct is upgraded
    /// @dev Performed during UUPS upgrade
    /// @param gomokuToken_ gomokutoken
    function reInitializeUpgrade(address gomokuToken_) external {
        gomokuToken = IGomokuToken(gomokuToken_);
        owner = msg.sender;
    }
}
