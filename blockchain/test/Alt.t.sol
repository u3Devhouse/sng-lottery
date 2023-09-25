// SPDX-License-Identifier: MIT

import "forge-std/Test.sol";

import {BlazeLottery} from "../contracts/Lottery.sol";

contract AltTest is Test {
    address user1 = makeAddr("user1");
    BlazeLottery lottery;

    function setUp() public {
        lottery = BlazeLottery(0x3D43F33396eC7126aB5b9e7ecA250464d6e80e94);
        vm.deal(user1, 1 ether);
    }

    function test_ethBuy() public {
        uint64[] memory tickets = new uint64[](2);
        tickets[0] = 65300609560;
        tickets[1] = 163378954791;
        (uint ethAmount, , , , , , , ) = lottery.acceptedTokens(address(0));
        ethAmount *= 2;
        vm.prank(user1);
        lottery.buyTicketsWithAltTokens{value: ethAmount}(tickets, address(0));
    }

    function test_potRollover() public {}
}
