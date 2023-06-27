// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library JudgeLibrary {
    int8 public constant MEASURE_MAX_NUM = 16;

    function judgeHorizon(uint8[MEASURE_MAX_NUM][MEASURE_MAX_NUM] memory board_, int8 row_, int8 column_) internal pure returns(bool) {
        uint8 continuesNum = 1;
        continuesNum += _countContinues(board_, row_, column_, 0, 1);
        continuesNum += _countContinues(board_, row_, column_, 0, -1);
        return continuesNum >= 5;
    }

    function judgeVertical(uint8[MEASURE_MAX_NUM][MEASURE_MAX_NUM] memory board_, int8 row_, int8 column_) internal pure returns(bool) {
        uint8 continuesNum = 1;
        continuesNum += _countContinues(board_, row_, column_, 1, 0);
        continuesNum += _countContinues(board_, row_, column_, -1, 0);
        return continuesNum >= 5;
    }

    function judgeSlantUp(uint8[MEASURE_MAX_NUM][MEASURE_MAX_NUM] memory board_, int8 row_, int8 column_) internal pure returns(bool) {
        uint8 continuesNum = 1;
        continuesNum += _countContinues(board_, row_, column_, -1, 1);
        continuesNum += _countContinues(board_, row_, column_, 1, -1);
        return continuesNum >= 5;
    }

    function judgeSlantDown(uint8[MEASURE_MAX_NUM][MEASURE_MAX_NUM] memory board_, int8 row_, int8 column_) internal pure returns(bool) {
        uint8 continuesNum = 1;
        continuesNum += _countContinues(board_, row_, column_, 1, 1);
        continuesNum += _countContinues(board_, row_, column_, -1, -1);
        return continuesNum >= 5;
    }

    function _countContinues(uint8[MEASURE_MAX_NUM][MEASURE_MAX_NUM] memory board_, int8 row_, int8 column_, int8 dirrow_, int8 dirCol_) internal pure returns(uint8 continuesNum) {
        int8 movedRow = row_ + dirrow_;
        int8 movedColumn = column_ + dirCol_;
        uint8 uintRow = uint8(row_);
        uint8 uintColumn = uint8(column_);

        while(movedRow >= 0 && movedRow < MEASURE_MAX_NUM 
        && movedColumn >= 0 && movedColumn < MEASURE_MAX_NUM 
        && board_[uintRow][uintColumn] == board_[uint8(movedRow)][uint8(movedColumn)]) {
            continuesNum++;
            movedRow += dirrow_;
            movedColumn += dirCol_;
        }
    }
}