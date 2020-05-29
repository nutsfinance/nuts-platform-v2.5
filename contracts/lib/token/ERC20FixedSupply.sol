// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ERC20 token with fixed initial supply.
 */
contract ERC20FixedSupply is ERC20 {

    /**
     * @dev ERC20 with supply set initially.
     * Note that decimals is 18 which is the default value.
     */
    constructor(string memory name, string memory symbol, uint256 supply) ERC20(name, symbol) public {
        _mint(msg.sender, supply);
    }
}