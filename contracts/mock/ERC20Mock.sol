// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title A mock ERC20 with fixed supply.
 */
contract ERC20Mock is ERC20 {
    constructor(uint8 decimals) ERC20("Test Token", "Test") public {
        _mint(msg.sender, 1000000000000);
        _setupDecimals(decimals);
    }
}
