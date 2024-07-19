// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SNGLottery} from "../src/Lottery.sol";

contract LotteryScript is Script {
    uint subId =
        28818361057403529158291194509988672977170634934970925213270338177665610649622;
    address SNG = 0xB263feAdEA2d754Dc72276A62e3CcCf934669522;
    address coordinator = address(0xd691f04bc0C9a24Edb78af9E005Cf85768F694C9);
    bytes32 s_hash =
        bytes32(
            0x130dba50ad435d4ecc214aad0d5820474137bd68e7e77724144f27c3c377d3d4
        );

    function run() public {
        vm.startBroadcast();
        SNGLottery lottery = new SNGLottery(
            SNG,
            coordinator,
            s_hash,
            subId,
            msg.sender
        );
        console.log("Lottery deployed at", address(lottery));
        lottery.activateLottery(0.1 ether, block.timestamp + 36 hours);
        vm.stopBroadcast();
    }
}
