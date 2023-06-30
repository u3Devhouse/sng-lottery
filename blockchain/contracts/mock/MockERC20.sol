// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract MockToken is ERC20PresetFixedSupply {
    constructor()
        ERC20PresetFixedSupply(
            "MockToken",
            "MT",
            1_000_000_000_000 ether,
            msg.sender
        )
    {}
}
