// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IGomokuToken.sol";

contract GomokuToken is ERC20, IGomokuToken {
    address public immutable factory;

    constructor(address factory_) ERC20("Gomoku Token", "GMK") {
        factory = factory_;
    }

    function mint(address to_, uint256 amount_) external {
        if (msg.sender != factory) revert("not factory");

        _mint(to_, amount_);
    }
}