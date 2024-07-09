// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

// THESE TESTS ARE to be MADE IN  BSC MAINNET
contract LotteryTest is Test {
    address usdcWhale = 0xadd;
    address sngWhale = 0xadd;

    address upkeeper = makeAddr("upkeeper");

    function setUp() public {
        // set wallets that hold USDC & SNG
        // Create vrf coordinator mock
        // coordinator creates subscription
        // coordinator funds subscription
        // DEPLOY LOTTERY
        // add lottery as a consumer
    }

    function activateLottery() public {
        // buy tickets
        // check if tickets are bought
    }

    modifier lotteryActivated() {
        _;
    }
}
