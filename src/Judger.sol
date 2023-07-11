// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Gomoku.sol";
import "./JudgeLibrary.sol";

contract Judger is Gomoku {
    // working against the Board
    using JudgeLibrary for uint8[MEASURE_MAX_NUM][MEASURE_MAX_NUM];
    
    function judge(Board calldata board_, int8 row_, int8 column_) external pure returns(Judge){
        uint8[MEASURE_MAX_NUM][MEASURE_MAX_NUM] memory board = board_.board;
        if (board.judgeHorizon(row_, column_)) return Judge.WIN;
        if (board.judgeVertical(row_, column_)) return Judge.WIN;
        if (board.judgeSlantUp(row_, column_)) return Judge.WIN;
        if (board.judgeSlantDown(row_, column_)) return Judge.WIN;
        if (board_.stoneCount == type(uint8).max) return Judge.DRAW;
        return Judge.CONTINUE;
    }
}