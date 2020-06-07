// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../lib/access/AdminAccess.sol";

/**
 * @title A mock ERC20 with fixed supply.
 */
contract ERC20Mock is ERC20, AdminAccess {
    constructor(uint8 decimals) ERC20("Test Token", "Test") public {
        uint256 wad = 10**uint256(decimals);
        _mint(msg.sender, 1000000000000 * wad);
        _setupDecimals(decimals);
        AdminAccess._initialize(msg.sender);
    }

    function mint(address account, uint256 amount) public onlyAdmin {
        _mint(account, amount);
    }
}
