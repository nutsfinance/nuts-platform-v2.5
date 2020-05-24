// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title NUTS Token contract.
 */
contract NUTSToken is ERC20Capped, ERC20Burnable, ERC20Pausable, AccessControl {
    using SafeMath for uint256;

    // Creates a new role identifier for the owner role
    // Owners can grant/revoke admin roles
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // Creates a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public constant NAME = "NUTS Token";
    string public constant SYMBOL = "NUTS";

    // Cap for individual minter.
    mapping(address => uint256) private _minterCaps;
    // Number of token minted by individual minter.
    mapping(address => uint256) private _minterAmount;

    constructor(uint256 cap) ERC20(NAME, SYMBOL) ERC20Capped(cap) public {
        // Grant the owner role to the contract creator
        _setupRole(OWNER_ROLE, msg.sender);
        // Grant the admin of minter role to the owner role
        _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
    }

    /**
     * @dev Throws if called by any account that does not have owner role.
     */
    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, msg.sender), "Caller is not an owner");
        _;
    }

    /**
     * @dev Pause the transfer of NUTS token. Only owner can pause.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the transfer of NUTS token. Only owner can unpause.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Grants a new minter and sets its minting cap.
     */
    function setMinter(address account, uint256 cap) public onlyOwner {
        grantRole(MINTER_ROLE, account);
        _minterCaps[account] = cap;
    }

    /**
     * @dev Mints NUTS token to the account.
     */
    function mint(address account, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(_minterAmount[msg.sender].add(amount) <= _minterCaps[msg.sender], "Minter cap exceeded");

        _minterAmount[msg.sender] = _minterAmount[msg.sender].add(amount);

        _mint(account, amount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     * - the minting cap is not exceeded.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Capped, ERC20Pausable) {
        ERC20Capped._beforeTokenTransfer(from, to, amount);
        ERC20Pausable._beforeTokenTransfer(from, to, amount);
    }
}
