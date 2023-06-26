// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Gomoku.sol";

contract Judger is Gomoku {

    function judge(Board calldata board, int8 row, int8 column) external pure returns(Judge){
        if (_judgeHorizon(board.board, row, column)) return Judge.WIN;
        if (_judgeVertical(board.board, row, column)) return Judge.WIN;
        if (_judgeSlantUp(board.board, row, column)) return Judge.WIN;
        if (_judgeSlantDown(board.board, row, column)) return Judge.WIN;
        if (board.stoneCount == type(uint8).max) return Judge.DRAW;
        return Judge.CONTINUE;
    }

    function _judgeHorizon(uint8[MEASURE_MAX_NUM][MEASURE_MAX_NUM] calldata board, int8 row, int8 column) internal pure returns(bool) {
        uint8 continuesNum = 1;
        continuesNum += _countContinues(board, row, column, 0, 1);
        continuesNum += _countContinues(board, row, column, 0, -1);
        return continuesNum >= 5;
    }

    function _judgeVertical(uint8[MEASURE_MAX_NUM][MEASURE_MAX_NUM] calldata board, int8 row, int8 column) internal pure returns(bool) {
        uint8 continuesNum = 1;
        continuesNum += _countContinues(board, row, column, 1, 0);
        continuesNum += _countContinues(board, row, column, -1, 0);
        return continuesNum >= 5;
    }

    function _judgeSlantUp(uint8[MEASURE_MAX_NUM][MEASURE_MAX_NUM] calldata board, int8 row, int8 column) internal pure returns(bool) {
        uint8 continuesNum = 1;
        continuesNum += _countContinues(board, row, column, -1, 1);
        continuesNum += _countContinues(board, row, column, 1, -1);
        return continuesNum >= 5;
    }

    function _judgeSlantDown(uint8[MEASURE_MAX_NUM][MEASURE_MAX_NUM] calldata board, int8 row, int8 column) internal pure returns(bool) {
        uint8 continuesNum = 1;
        continuesNum += _countContinues(board, row, column, 1, 1);
        continuesNum += _countContinues(board, row, column, -1, -1);
        return continuesNum >= 5;
    }

    function _countContinues(uint8[MEASURE_MAX_NUM][MEASURE_MAX_NUM] calldata board, int8 row, int8 column, int8 dirRow, int8 dirCol) internal pure returns(uint8 continuesNum) {
        int8 movedRow = row + dirRow;
        int8 movedColumn = column + dirCol;

        while(movedRow >= 0 && movedRow < MEASURE_MAX_NUM 
        && movedColumn >= 0 && movedColumn < MEASURE_MAX_NUM 
        && board[uint8(row)][uint8(column)] == board[uint8(movedRow)][uint8(movedColumn)]) {
            continuesNum++;
            movedRow += dirRow;
            movedColumn += dirCol;
        }
    }
}