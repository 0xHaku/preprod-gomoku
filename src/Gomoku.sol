// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title define the basic structureof gomoku-game
/// @author 0xHaku
/// @notice You can use this contract for launch and play gomoku-game
/// @dev games are identified by gameId
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

    event gameEntered(uint256 indexed gameId, bool isBlack, address player);
    event gameStatusChanged(uint256 indexed gameId, Status status);
    // player is zero when judge is draw
    event gameResultFinalized(uint256 indexed gameId, Judge res, address player);
    event stonePosessed(uint256 indexed gameId, int8 row, int8 column, Stone color);
}