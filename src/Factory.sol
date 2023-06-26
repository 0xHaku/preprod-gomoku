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
        game.player1 = msg.sender;
        games.push(game);

        emit gameCreated(gameId, msg.sender);
        emit gameStatusChanged(gameId, Status.STANDBY);
        
        return gameId;
    }

    function entryGame(uint256 gameId) external gameExists(gameId) {
        Game storage game = games[gameId];
        if (game.status != Status.STANDBY) revert("status not standby");
        if (game.player1 == msg.sender) revert("same as player1");

        game.player2 = msg.sender;
        game.status = Status.OPEN;

        emit gameEntered(gameId, msg.sender);
        emit gameStatusChanged(gameId, Status.OPEN);
    }

    function getGame(uint256 gameId) public view gameExists(gameId) returns(Game memory) {
        return games[gameId];
    }

    function play(uint256 gameId, int8 row, int8 column) external gameExists(gameId) {
        Game storage game = games[gameId];

        if (game.status != Status.OPEN) revert("status not open");
        bool isBlack = game.board.stoneCount % 2 == 0;
        Stone color = isBlack ? Stone.BLACK : Stone.WHITE; 
        address turnPlayer = isBlack ? game.player1 : game.player2;
        if (msg.sender != turnPlayer) revert("not your turn");

        if (row < 0 || row >= MEASURE_MAX_NUM) revert("row outbound");
        if (column < 0 || column >= MEASURE_MAX_NUM) revert("column outbound");

        uint8 fixedRow = uint8(row);
        uint8 fixedColumn = uint8(column);

        if (game.board.board[fixedRow][fixedColumn] != uint8(Stone.ENPTY)) revert("stone already exists");
        
        game.board.board[fixedRow][fixedColumn] = uint8(color);
        
        Judge res = judger.judge(game.board, row, column);

        if (res != Judge.CONTINUE) game.status = Status.CLOSE;

        if (type(uint8).max != game.board.stoneCount) {
            game.board.stoneCount++;
        }

        emit stonePosessed(gameId, row, column, color);
    }

    modifier gameExists(uint256 gameId) {
        if (gameId >= games.length) revert("game not exist");
        _;
    }
}
