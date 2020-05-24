// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../lib/access/AdminAccess.sol";
import "../lib/token/WETH9.sol";
import "./EscrowInterface.sol";

/**
 * @title Base contract for both instrument and issuance escrow.
 * Note: Only admins can withdraw from or deposit to the Escrow directly.
 * Only owner can grant admin roles.
 */
abstract contract EscrowBase is EscrowInterface, AdminAccess {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * Mapping: Account address => (Token address => Token balance)
     */
    mapping(address => mapping(address => uint256)) private _accountBalances;
    WETH9 internal _weth;

    /**
     * @dev Initializes the owner and weth address.
     */
    function _initialize(address owner, address wethAddress) internal {
        require(address(_weth) == address(0x0), "EscrowBase: Already initialize.");
        require(wethAddress != address(0x0), "EscrowBase: WETH not set.");
        AdminAccess._initialize(owner);
        _weth = WETH9(payable(wethAddress));
    }

    /*******************************************************
     * Implements methods defined in IEscrow.
     *******************************************************/

    /**
     * @dev Get the current ETH balance of an account in the escrow.
     * @param account The account to check ETH balance.
     * @return Current ETH balance of the account.
     */
    function getBalance(address account) public override view returns (uint256) {
        return _accountBalances[account][address(_weth)];
    }

    /**
     * @dev Get the balance of the requested IERC20 token in the escrow.
     * @param account The address to check IERC20 balance.
     * @param token The IERC20 token to check balance.
     * @return The balance of the account.
     */
    function getTokenBalance(address account, address token) public override view returns (uint256) {
        return _accountBalances[account][token];
    }

    /****************************************************************
     * Public methods for Escrow Admin
     ***************************************************************/

    /**
     * @dev Deposits ERC20 tokens from Escrow Admin into an account.
     * Note: The Escrow Admin must set the allowance before hand.
     * @param account The account to deposit ERC20 tokens.
     * @param token The ERC20 token to deposit.
     * @param amount The amount of ERC20 token to deposit.
     */
    function depositByAdmin(address account, address token, uint256 amount) public override onlyAdmin {
        require(account != address(0x0), "EscrowBase: Account not set");
        require(token != address(0x0), "EscrowBase: Token not set");
        require(amount > 0, "EscrowBase: Amount not set");

        // Updates the balance
        _increaseBalance(account,token, amount);

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev Withdraws ERC20 token from an account to Escrow Admin.
     * The transfer action is done inside this function.
     * @param account The account to withdraw ERC20 token.
     * @param token The ERC20 token to withdraw.
     * @param amount The amount of ERC20 tokens to withdraw.
     */
    function withdrawByAdmin(address account, address token, uint256 amount) public override onlyAdmin {
        require(account != address(0x0), "EscrowBase: Account not set");
        require(token != address(0x0), "EscrowBase: Token not set");
        require(amount > 0, "EscrowBase: Amount not set");
        require(getTokenBalance(account, token) >= amount, "EscrowBase: Insufficient Balance");

        // Updates the balance
        _decreaseBalance(account, token, amount);

        IERC20(token).safeTransfer(msg.sender, amount);
    }

    /**
     * @dev Transfer ERC20 token from one account to another in the Escrow.
     * @param source The account that owns the ERC20 token.
     * @param dest The target account that will own the ERC20 token.
     * @param token The ERC20 token address.
     * @param amount The amount of ERC20 token to transfer.
     */
    function transferByAdmin(address source, address dest, address token, uint256 amount) public override onlyAdmin {
        // Updates the balance
        _decreaseBalance(source, token, amount);
        _increaseBalance(dest, token, amount);
    }

    /****************************************************************
     * Internal methods shared by Instrument and Issuance Escrows.
     ***************************************************************/

    /**
     * @dev Increases the balance of an account.
     * @param account The account to increase balance.
     * @param token The token to increase the balance.
     * @param amount The amount to increase.
     */
    function _increaseBalance(address account, address token, uint256 amount)
        internal
    {
        _accountBalances[account][token] = _accountBalances[account][token].add(amount);
        emit BalanceIncreased(account, token, amount);
    }

    /**
     * @dev Decreases the balance of an account.
     * @param account The account to decrease balance.
     * @param token The token to decrease from the balance.
     * @param amount The amount to decrease.
     */
    function _decreaseBalance(address account, address token, uint256 amount)
        internal
    {
        _accountBalances[account][token] = _accountBalances[account][token].sub(amount);
        emit BalanceDecreased(account, token, amount);
    }
}
