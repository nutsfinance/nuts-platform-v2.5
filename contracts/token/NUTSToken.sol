// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NUTS Token contract.
 */
contract NUTSToken is ERC20Capped, Ownable {
    using SafeMath for uint256;

    constructor(string memory name, string memory symbol, uint256 cap)
        ERC20(name, symbol) ERC20Capped(cap) public {}

    /**
     * @dev Mints NUTS token to the account.
     */
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}
