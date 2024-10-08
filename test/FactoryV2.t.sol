// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/FactoryV2.sol";
import "../src/Gomoku.sol";

contract FactoryV2Test is Test, FactoryV2 {
    FactoryV2 factory;
    address factoryAddress;
    address alice;
    address bob;
    address charlie;

    function setUp() public {
        // goerli fork
        if (block.chainid == 5) {
            factoryAddress = address(0xc4755eF5BDD32d98af691E43434f3a19bA53aB5D);
            factory = FactoryV2(factoryAddress);
        // localhost fork
        } else if (block.chainid == 31336) {
            factoryAddress = address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
            factory = FactoryV2(factoryAddress);
        // mumbai fork
        } else if (block.chainid == 80001) {
            factoryAddress = address(0xacc45D1f7811B5eD7C0c4fB1d372168D217C5861);
            factory = FactoryV2(factoryAddress);
        } else {
            factory = new FactoryV2();
            factoryAddress = address(factory);
            factory.initialize();
        }

        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        
        vm.startPrank(alice);
    }

    function test_s_version() public {
        uint256 version = factory.version();
        assertEq(version, 2);
    }

    function test_s_createGame() public {
        uint256 dummyGameId = 0;

        vm.expectEmit();
        emit Gomoku.gameEntered(dummyGameId, true, alice);
        vm.expectEmit();
        emit Gomoku.gameStatusChanged(dummyGameId, Status.STANDBY);
        uint256 gameId = factory.createGame();
        assertEq(dummyGameId, gameId);

        dummyGameId++;

        gameId = factory.createGame();
        assertEq(dummyGameId, gameId);        
    }

    function test_s_getGame() public {
        uint256 gameId = factory.createGame();

        Game memory game = factory.getGame(gameId);

        assertTrue(game.status == Status.STANDBY);
        assertEq(game.player1, alice);
    }

    // all gameId revert by default
    function testFail_getGame(uint256 gameId) public view {
        factory.getGame(gameId);
    }

    function test_s_entryGame() public {
        uint256 gameId = factory.createGame();

        vm.prank(bob);
        vm.expectEmit();
        emit Gomoku.gameEntered(gameId, false, bob);
        vm.expectEmit();
        emit Gomoku.gameStatusChanged(gameId, Status.OPEN);
        factory.entryGame(gameId);

        Game memory game = factory.getGame(gameId);

        assertTrue(game.status == Status.OPEN);
        assertEq(game.player2, bob);
    }

    function test_f_entryGame() public {
        uint256 gameId = factory.createGame();

        uint256 dummyGameId = gameId + 1;
        vm.expectRevert("game not exist");
        factory.entryGame(dummyGameId);

        vm.expectRevert("same as player1");
        factory.entryGame(gameId);

        vm.prank(bob);
        factory.entryGame(gameId);

        vm.prank(charlie);
        vm.expectRevert("status not standby");
        factory.entryGame(gameId);
    }

    function test_f_play() public {
        uint256 gameId = factory.createGame();
        int8 dummyRow = 0;
        int8 dummyColumn = 0;

        vm.expectRevert("status not open");
        factory.play(gameId, dummyRow, dummyColumn);
    }
}