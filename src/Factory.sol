// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Gomoku.sol";
import "./Judger.sol";

contract Factory is Gomoku {

    Judger judger;

    Game[] games;

    constructor() {
        judger = new Judger();
    }

    function createGame() external returns(uint256) {
        uint256 gameId = games.length;

        Game memory game;
        games.push(game);

        _entryPlayer(gameId, true);
        _changeGameStatus(gameId, Status.STANDBY);
        
        return gameId;
    }

    function entryGame(uint256 gameId) external gameExists(gameId) {
        Game storage game = games[gameId];
        if (game.status != Status.STANDBY) revert("status not standby");
        if (game.player1 == msg.sender) revert("same as player1");

        _entryPlayer(gameId, false);
        _changeGameStatus(gameId, Status.OPEN);
    }

    function getGame(uint256 gameId) public view gameExists(gameId) returns(Game memory) {
        return games[gameId];
    }

    function play(uint256 gameId, int8 row, int8 column) external gameExists(gameId) {

        // check input range
        if (row < 0 || row >= MEASURE_MAX_NUM) revert("row outbound");
        if (column < 0 || column >= MEASURE_MAX_NUM) revert("column outbound");

        Game storage game;
        bool isBlack;
        Stone color;
        address turnPlayer;
        uint8 fixedRow;
        uint8 fixedColumn;
        Judge res;

        game = games[gameId];

        if (game.status != Status.OPEN) revert("status not open");

        // deterimine turn player
        isBlack = game.board.stoneCount % 2 == 0;
        color = isBlack ? Stone.BLACK : Stone.WHITE; 
        turnPlayer = isBlack ? game.player1 : game.player2;

        if (msg.sender != turnPlayer) revert("not your turn");

        // posess the stone
        fixedRow = uint8(row);
        fixedColumn= uint8(column);

        if (game.board.board[fixedRow][fixedColumn] != uint8(Stone.ENPTY)) revert("stone already exists");
        
        game.board.board[fixedRow][fixedColumn] = uint8(color);
        
        if (type(uint8).max != game.board.stoneCount) {
            game.board.stoneCount++;
        }

        emit stonePosessed(gameId, row, column, color);

        // judge the board
        res = judger.judge(game.board, row, column);

        // broadcast the game's result
        if (res != Judge.CONTINUE) {
            _changeGameStatus(gameId, Status.CLOSE);
            if (res == Judge.WIN) {
                emit gameResultFinalized(gameId, res, turnPlayer);
            } else {
                emit gameResultFinalized(gameId, res, address(0));
            }
        }
    }

    modifier gameExists(uint256 gameId) {
        if (gameId >= games.length) revert("game not exist");
        _;
    }

    function _entryPlayer(uint256 gameId, bool isBlack) internal {
        if (isBlack) {
            games[gameId].player1 = msg.sender;
        } else {
            games[gameId].player2 = msg.sender;
        }

        emit gameEntered(gameId, isBlack, msg.sender);
    }

    function _changeGameStatus(uint256 gameId, Status status) internal {
        games[gameId].status = status;

        emit gameStatusChanged(gameId, status);
    }
}
