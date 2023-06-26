// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Gomoku {
    int8 public constant MEASURE_MAX_NUM = 16;
    
    enum Stone {
        ENPTY,
        BLACK,
        WHITE
    }

    enum Judge {
        CONTINUE,
        WIN,
        DRAW
    }

    struct Game {
        address player1;
        address player2;
        Status status;
        Board board;
    }

    enum Status {
        STANDBY,
        OPEN,
        CLOSE
    }

    struct Board {
        uint8 stoneCount;
        uint8[MEASURE_MAX_NUM][MEASURE_MAX_NUM] board;
    }

    event gameCreated(uint256 indexed gameId, address player1);
    event gameEntered(uint256 indexed gameId, address player2);
    event gameStatusChanged(uint256 indexed gameId, Status);
    event stonePosessed(uint256 indexed gameId, int8 row, int8 column, Stone color);
}