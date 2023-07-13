// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

abstract contract TestUtil {
    // calculate slot number with uint256
    function slideSlot(bytes32 baseSlot, uint256 offset) internal pure returns(bytes32) {
        return bytes32(uint256(baseSlot) + offset);
    }

    // left-justify the address in bytes32
    function addressToBytes32(address target) internal pure returns(bytes32) {
        return bytes32(uint256(uint160(target)));
    }
}