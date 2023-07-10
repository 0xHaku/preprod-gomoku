// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/FactoryV3.sol";
import "../src/GomokuToken.sol";
import "./TestUtil.sol";

contract GameV3Test is Test, TestUtil, FactoryV3 {
    FactoryV3 factory;
    address factoryAddress;
    GomokuToken gomokuTokenMock;
    address gomokuTokenMockAddress;
    address alice;
    address bob;
    address charlie;
    uint256 gameId;

    function setUp() public {
        // goerli fork
        if (block.chainid == 5) {
            factoryAddress = address(
                0xc4755eF5BDD32d98af691E43434f3a19bA53aB5D
            );
            factory = FactoryV3(factoryAddress);
            // localhost fork
        } else if (block.chainid == 31336) {
            factoryAddress = address(
                0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
            );
            factory = FactoryV3(factoryAddress);
            vm.store(
                factoryAddress,
                bytes32(uint256(103)),
                addressToBytes32(address(this))
            );
            gomokuTokenMockAddress = address(
                0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
            );
            gomokuTokenMock = GomokuToken(gomokuTokenMockAddress);
            // mumbai fork
        } else if (block.chainid == 80001) {
            factoryAddress = address(
                0x62753Fd89C49Def15F904DCB4d46531bEb9736A5
            );
            factory = FactoryV3(factoryAddress);
        } else {
            factory = new FactoryV3();
            factoryAddress = address(factory);
            gomokuTokenMock = new GomokuToken(factoryAddress);
            gomokuTokenMockAddress = address(gomokuTokenMock);
            factory.initialize(gomokuTokenMockAddress);
        }

        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);

        vm.prank(alice);
        gameId = factory.createGame{value: 0.01 ether}();
        vm.prank(bob);
        factory.entryGame{value: 0.01 ether}(gameId);
    }

    function test_s_play() public {
        int8 dummyRow = 0;
        int8 dummyColumn = 0;

        vm.prank(alice);
        vm.expectEmit();
        emit stonePosessed(gameId, dummyRow, dummyColumn, Stone.BLACK);
        factory.play(gameId, dummyRow, dummyColumn);

        Game memory game = factory.getGame(gameId);
        assertEq(
            game.board.board[uint8(dummyRow)][uint8(dummyColumn)],
            uint256(Stone.BLACK)
        );
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
        assertEq(
            game.board.board[uint8(dummyRow)][uint8(dummyColumn)],
            uint256(Stone.BLACK)
        );

        vm.prank(bob);
        vm.expectRevert("stone already exists");
        factory.play(gameId, dummyRow, dummyColumn);
    }

    function test_s_resign() public {
        Game memory game = factory.getGame(gameId);

        // player1 resign
        vm.prank(game.player1);
        vm.expectEmit();
        emit gameStatusChanged(gameId, Status.CLOSE);
        emit gameResultFinalized(gameId, Judge.WIN, game.player2);
        factory.resign(gameId);

        uint256 dummyGameId;

        // player2 resign
        vm.prank(alice);
        dummyGameId = factory.createGame{value: 0.01 ether}();
        vm.prank(bob);
        factory.entryGame{value: 0.01 ether}(dummyGameId);

        vm.prank(game.player2);
        vm.expectEmit();
        emit gameStatusChanged(dummyGameId, Status.CLOSE);
        emit gameResultFinalized(dummyGameId, Judge.WIN, game.player1);
        factory.resign(dummyGameId);
    }

    function test_f_resign() public {
        uint256 dummyGameId;

        vm.prank(alice);
        dummyGameId = factory.createGame{value: 0.01 ether}();

        vm.prank(bob);
        vm.expectRevert("status not open");
        factory.resign(dummyGameId);

        vm.prank(bob);
        factory.entryGame{value: 0.01 ether}(dummyGameId);

        vm.prank(charlie);
        vm.expectRevert("not player");
        factory.resign(dummyGameId);
    }

    // testing the post-winning process
    function test_s_win() public {
        address[] memory players = new address[](2);
        players[0] = alice;
        players[1] = bob;
        uint256 befAliceEthBalance = alice.balance;
        uint256 befBobEthBalance = bob.balance;
        uint256 befTestEthBalance = address(this).balance;

        for (uint8 i; i < 8; i++) {
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

        assertEq(alice.balance - befAliceEthBalance, WINPRIZEETH);
        assertEq(bob.balance - befBobEthBalance, 0);
        assertEq(address(this).balance - befTestEthBalance, WINFACTORYFEE);
        assertEq(gomokuTokenMock.balanceOf(alice), WINPRIZEOMOKU);
        assertEq(gomokuTokenMock.balanceOf(bob), 0);
    }

    function test_s_win_horizon_right() public {
        address[] memory players = new address[](2);
        players[0] = alice;
        players[1] = bob;

        for (uint8 i; i < 8; i++) {
            vm.prank(players[i % 2]);
            factory.play(gameId, int8(i % 2), int8(i / 2));
        }
        Game memory game = factory.getGame(gameId);
        assertTrue(game.status == Status.OPEN);

        vm.prank(alice);
        factory.play(gameId, 0, 4);

        game = factory.getGame(gameId);
        assertTrue(game.status == Status.CLOSE);
    }

    function test_s_win_horizon_left() public {
        address[] memory players = new address[](2);
        players[0] = alice;
        players[1] = bob;

        for (uint8 i; i < 8; i++) {
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

        for (uint8 i; i < 8; i++) {
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

        for (uint8 i; i < 8; i++) {
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

        for (uint8 i; i < 8; i++) {
            vm.prank(players[i % 2]);
            factory.play(
                gameId,
                MEASURE_MAX_NUM - 1 - int8(i / 2),
                int8(i / 2) + int8(i % 2)
            );
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

        for (uint8 i; i < 8; i++) {
            vm.prank(players[i % 2]);
            factory.play(
                gameId,
                int8(i / 2) + int8(i % 2),
                MEASURE_MAX_NUM - 1 - int8(i / 2)
            );
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

        for (uint8 i; i < 8; i++) {
            vm.prank(players[i % 2]);
            factory.play(
                gameId,
                MEASURE_MAX_NUM - 1 - int8(i / 2),
                MEASURE_MAX_NUM - 1 - int8(i % 2) - int8(i / 2)
            );
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

        for (uint8 i; i < 8; i++) {
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
        uint256 gamesSlot = 102;
        bytes32 gameSlot = keccak256(
            abi.encodePacked(bytes32(uint256(gamesSlot)))
        );
        uint256 befAliceEthBalance = alice.balance;
        uint256 befBobEthBalance = bob.balance;
        uint256 befTestEthBalance = address(this).balance;

        // forcing the board to fill
        vm.store(
            factoryAddress,
            slideSlot(gameSlot, 2),
            bytes32(uint256(type(uint8).max))
        );

        // last turn
        vm.prank(bob);
        vm.expectEmit();
        emit gameStatusChanged(gameId, Status.CLOSE);
        vm.expectEmit();
        emit gameResultFinalized(gameId, Judge.DRAW, address(0));
        factory.play(gameId, 0, 0);

        Game memory game = factory.getGame(gameId);
        assertTrue(game.status == Status.CLOSE);

        assertEq(alice.balance - befAliceEthBalance, 0);
        assertEq(bob.balance - befBobEthBalance, 0);
        assertEq(address(this).balance - befTestEthBalance, DRAWFEE);
        assertEq(gomokuTokenMock.balanceOf(alice), 0);
        assertEq(gomokuTokenMock.balanceOf(bob), 0);
    }

    receive() external payable {}

    fallback() external payable {}
}
