// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Factory.sol";

contract GameTest is Test, Factory {
    using stdStorage for StdStorage;

    Factory factory;
    address factoryAddress;
    address alice;
    address bob;
    address charlie;
    uint256 gameId;

    function setUp() public {
        factory = new Factory();
        factoryAddress = address(factory);
        
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        
        vm.prank(alice);
        gameId = factory.createGame();
        vm.prank(bob);
        factory.entryGame(gameId);
    }

    function test_s_play() public {
        int8 dummyRow = 0;
        int8 dummyColumn = 0;

        vm.prank(alice);
        vm.expectEmit();
        emit stonePosessed(gameId, dummyRow, dummyColumn,Stone.BLACK);
        factory.play(gameId, dummyRow, dummyColumn);

        Game memory game = factory.getGame(gameId);
        assertEq(game.board.board[uint8(dummyRow)][uint8(dummyColumn)], uint256(Stone.BLACK));
    }

    function test_f_play() public {
        int8 dummyRow = 0;
        int8 dummyColumn = 0;
        int8 dummyOverRow = 16;
        int8 dummyOverColumn = 16;
        int8 dummyUnderRow = -1;
        int8 dummyUnderColumn = -1;

        vm.prank(bob);
        vm.expectRevert("not your turn");
        factory.play(gameId, dummyRow, dummyColumn);

        vm.prank(alice);
        vm.expectRevert("row outbound");
        factory.play(gameId, dummyOverRow, dummyColumn);

        vm.prank(alice);
        vm.expectRevert("column outbound");
        factory.play(gameId, dummyRow, dummyOverColumn);

        vm.prank(alice);
        vm.expectRevert("row outbound");
        factory.play(gameId, dummyUnderRow, dummyColumn);

        vm.prank(alice);
        vm.expectRevert("column outbound");
        factory.play(gameId, dummyRow, dummyUnderColumn);

        vm.prank(alice);
        factory.play(gameId, dummyRow, dummyColumn);

        Game memory game = factory.getGame(gameId);
        assertEq(game.board.board[uint8(dummyRow)][uint8(dummyColumn)], uint256(Stone.BLACK));

        vm.prank(bob);
        vm.expectRevert("stone already exists");
        factory.play(gameId, dummyRow, dummyColumn);
    }

    function test_s_win_horizon_right() public {
        address[] memory players = new address[](2);
        players[0] = alice;
        players[1] = bob;

        for(uint8 i; i < 8; i++) {
            vm.prank(players[i % 2]);
            factory.play(gameId, int8(i % 2), int8(i / 2));
        }
        Game memory game = factory.getGame(gameId);
        assertTrue(game.status == Status.OPEN);
        
        vm.prank(alice);
        vm.expectEmit();
        emit gameStatusChanged(gameId, Status.CLOSE);
        vm.expectEmit();
        emit gameResultFinalized(gameId, Judge.WIN, alice);
        factory.play(gameId, 0, 4);

        game = factory.getGame(gameId);
        assertTrue(game.status == Status.CLOSE);
    }

    function test_s_win_horizon_left() public {
        address[] memory players = new address[](2);
        players[0] = alice;
        players[1] = bob;

        for(uint8 i; i < 8; i++) {
            vm.prank(players[i % 2]);
            factory.play(gameId, int8(i % 2), int8(4 - i / 2));
        }
        Game memory game = factory.getGame(gameId);
        assertTrue(game.status == Status.OPEN);
        
        vm.prank(alice);
        factory.play(gameId, 0, 0);

        game = factory.getGame(gameId);
        assertTrue(game.status == Status.CLOSE);
    }

    function test_s_win_vertical_up() public {
        address[] memory players = new address[](2);
        players[0] = alice;
        players[1] = bob;

        for(uint8 i; i < 8; i++) {
            vm.prank(players[i % 2]);
            factory.play(gameId, int8(4 - i / 2), int8(i % 2));
        }
        Game memory game = factory.getGame(gameId);
        assertTrue(game.status == Status.OPEN);
        
        vm.prank(alice);
        factory.play(gameId, 0, 0);

        game = factory.getGame(gameId);
        assertTrue(game.status == Status.CLOSE);
    }

    function test_s_win_vertical_down() public {
        address[] memory players = new address[](2);
        players[0] = alice;
        players[1] = bob;

        for(uint8 i; i < 8; i++) {
            vm.prank(players[i % 2]);
            factory.play(gameId, int8(i / 2), int8(i % 2));
        }
        Game memory game = factory.getGame(gameId);
        assertTrue(game.status == Status.OPEN);
        
        vm.prank(alice);
        factory.play(gameId, 4, 0);

        game = factory.getGame(gameId);
        assertTrue(game.status == Status.CLOSE);
    }

    function test_s_win_slantup_up() public {
        address[] memory players = new address[](2);
        players[0] = alice;
        players[1] = bob;

        for(uint8 i; i < 8; i++) {
            vm.prank(players[i % 2]);
            factory.play(gameId, MEASURE_MAX_NUM - 1 - int8(i / 2), int8(i / 2) + int8(i % 2));
        }
        Game memory game = factory.getGame(gameId);
        assertTrue(game.status == Status.OPEN);
        
        vm.prank(alice);
        factory.play(gameId, 11, 4);

        game = factory.getGame(gameId);
        assertTrue(game.status == Status.CLOSE);
    }

    function test_s_win_slantup_down() public {
        address[] memory players = new address[](2);
        players[0] = alice;
        players[1] = bob;

        for(uint8 i; i < 8; i++) {
            vm.prank(players[i % 2]);
            factory.play(gameId, int8(i / 2) + int8(i % 2), MEASURE_MAX_NUM - 1 - int8(i / 2));
        }
        Game memory game = factory.getGame(gameId);
        assertTrue(game.status == Status.OPEN);
        
        vm.prank(alice);
        factory.play(gameId, 4, 11);

        game = factory.getGame(gameId);
        assertTrue(game.status == Status.CLOSE);
    }

    function test_s_win_slantdown_up() public {
        address[] memory players = new address[](2);
        players[0] = alice;
        players[1] = bob;

        for(uint8 i; i < 8; i++) {
            vm.prank(players[i % 2]);
            factory.play(gameId, MEASURE_MAX_NUM - 1 - int8(i / 2), MEASURE_MAX_NUM - 1 - int8(i % 2) - int8(i / 2));
        }

        Game memory game = factory.getGame(gameId);
        assertTrue(game.status == Status.OPEN);
        
        vm.prank(alice);
        factory.play(gameId, 11, 11);

        game = factory.getGame(gameId);
        assertTrue(game.status == Status.CLOSE);
    }

    function test_s_win_slantdown_down() public {
        address[] memory players = new address[](2);
        players[0] = alice;
        players[1] = bob;

        for(uint8 i; i < 8; i++) {
            vm.prank(players[i % 2]);
            factory.play(gameId, int8(i / 2), int8(i % 2) + int8(i / 2));
        }

        Game memory game = factory.getGame(gameId);
        assertTrue(game.status == Status.OPEN);
        
        vm.prank(alice);
        factory.play(gameId, 4, 4);

        game = factory.getGame(gameId);
        assertTrue(game.status == Status.CLOSE);
    }

    function test_s_draw() public {
        uint256 gamesSlot = 1;
        bytes32 gameSlot = keccak256(abi.encodePacked(bytes32(uint256(gamesSlot))));

        // forcing the board to fill
        vm.store(factoryAddress, slideSlot(gameSlot,2), bytes32(uint256(type(uint8).max)));

        // last turn
        vm.prank(bob);
        vm.expectEmit();
        emit gameStatusChanged(gameId, Status.CLOSE);
        vm.expectEmit();
        emit gameResultFinalized(gameId, Judge.DRAW, address(0));
        factory.play(gameId, 0, 0);

        Game memory game = factory.getGame(gameId);
        assertTrue(game.status == Status.CLOSE);
    }

    // calculate slot number with uint256
    function slideSlot(bytes32 baseSlot, uint256 offset) internal pure returns(bytes32) {
        return bytes32(uint256(baseSlot) + offset);
    }
}