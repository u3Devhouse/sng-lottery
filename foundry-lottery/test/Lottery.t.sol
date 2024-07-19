// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
// Chainlink VRF
import {VRFCoordinatorV2Mock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
// SNG Contract with changed imports for testing
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Contract to TEST
import {SNGLottery} from "../src/Lottery.sol";

// THESE TESTS ARE to be MADE IN  BSC MAINNET
contract LotteryTest is Test {
    address usdcWhale = 0x8894E0a0c962CB723c1976a4421c95949bE2D4E3;
    address sngWhale = 0xA9C8a2207B1C7D42DC3d95d8bCA6658789B6dc52;
    address USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    IERC20 SNG = IERC20(0xB263feAdEA2d754Dc72276A62e3CcCf934669522);
    address team = makeAddr("team");

    address upkeeper = makeAddr("upkeeper");
    VRFCoordinatorV2Mock coordinator;
    SNGLottery lottery;
    bytes32 s_hash =
        0x130dba50ad435d4ecc214aad0d5820474137bd68e7e77724144f27c3c377d3d4;

    fallback() external payable {}

    receive() external payable {}

    function setUp() public {
        // Create vrf coordinator mock
        coordinator = new VRFCoordinatorV2Mock(1000, 1000);
        // coordinator creates subscription
        uint64 subId = coordinator.createSubscription();
        // coordinator funds subscription
        coordinator.fundSubscription(subId, 1000 ether);
        // DEPLOY LOTTERY
        lottery = new SNGLottery(
            address(SNG),
            address(coordinator),
            s_hash,
            subId,
            team
        );
        // add lottery as a consumer
        coordinator.addConsumer(subId, address(lottery));

        // allow lottery to spend funds
        vm.prank(sngWhale);
        SNG.approve(address(lottery), 1_000_000 ether);

        vm.deal(sngWhale, 100 ether);
    }

    function test_shouldNotAllowToTriggerEndRound() public {
        vm.expectRevert();
        lottery.endRound();
    }

    function test_shouldNotAllowToTriggerUpkeep() public {
        vm.expectRevert();
        bytes memory upkeepData = abi.encode(false, [0, 0, 0]);
        lottery.performUpkeep(upkeepData);
    }

    function test_distributionAmounts() public {
        uint[] memory dist = new uint[](0);
        vm.prank(sngWhale);
        lottery.addToPot(30 ether, 1, dist);
        uint[] memory distribution = lottery.roundDistribution(1);
        assertEq(distribution.length, 3);
        assertEq(distribution[0], 10 ether);
        assertEq(distribution[1], 10 ether);
        assertEq(distribution[2], 10 ether);

        assertEq(SNG.balanceOf(address(lottery)), 30 ether);
    }

    function test_addWithCustomDistribution() public {
        uint256[] memory customDist = new uint256[](3);
        customDist[0] = 10;
        customDist[1] = 20;
        customDist[2] = 70;
        vm.prank(sngWhale);
        lottery.addToPot(100 ether, 1, customDist);
        uint[] memory distribution = lottery.roundDistribution(1);
        assertEq(distribution[0], 10 ether);
        assertEq(distribution[1], 20 ether);
        assertEq(distribution[2], 70 ether);
        assertEq(SNG.balanceOf(address(lottery)), 100 ether);
    }

    modifier lotteryActivated() {
        uint[] memory dist = new uint[](0);
        vm.prank(sngWhale);
        lottery.addToPot(10_000 ether, 1, dist);

        lottery.activateLottery(2 ether, block.timestamp + 1 days);
        _;
    }

    function test_buyTicketsWithNative() public lotteryActivated {
        uint64[] memory tickets = new uint64[](1);
        tickets[0] = 0x0a0b0c0d01;
        lottery.buyTickets{value: 1 ether}(tickets, address(0));

        (
            uint64[] memory _userTickets,
            bool[] memory claimed,
            uint total_tickets
        ) = lottery.getUserTickets(address(this), 1);
        assertEq(total_tickets, 1);
        assertEq(_userTickets[0], 0x0a0b0c0d01);
        assertEq(claimed[0], false);
    }
}
