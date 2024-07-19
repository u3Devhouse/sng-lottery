// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
// Chainlink VRF
import {VRFCoordinatorV2Mock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
// SNG Contract with changed imports for testing
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Contract to TEST
import {SNGLottery} from "../src/Lottery.sol";

contract DeployTestnetLottery is Script {
    uint256 subId =
        112495794514388988048304204483916397068383292277567464431633199703381586549251;
    bytes32 s_hash =
        0x8596b430971ac45bdf6088665b9ad8e8630c9d5049ab54b14dff711bee7c0e26;
    address coordinator = 0xDA3b641D438362C440Ac5458c57e00a712b66700;
    address SNG = 0x73749b142a7870e2772a7807AeC32feB448290Ea;

    function run() public {
        vm.startBroadcast();
        SNGLottery lottery = new SNGLottery(
            SNG,
            coordinator,
            s_hash,
            subId,
            msg.sender
        );

        IERC20(SNG).approve(address(lottery), type(uint256).max);
        uint[] memory dist = new uint[](0);
        lottery.addToPot(10_000 ether, 1, dist);
        lottery.activateLottery(0.1 ether, block.timestamp + 36 hours);
        vm.stopBroadcast();
    }
}
