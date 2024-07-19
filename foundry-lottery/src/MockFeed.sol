// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockFeed {
    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (1, 56621435000, block.timestamp, block.timestamp, 1);
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }
}
