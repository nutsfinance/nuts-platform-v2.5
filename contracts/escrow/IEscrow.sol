// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

/**
 * @title Base interface for both instrument and issuance escrows.
 * @dev Abstract contract is used instead of Interface for inheritance.
 */
abstract contract IEscrow {
    /**
     * Balance is increased.
     */
    event BalanceIncreased(address account, address token, uint256 amount);

    /**
     * Balance is decreased.
     */
    event BalanceDecreased(address account, address token, uint256 amount);

    /**
     * @dev Get the current ETH balance of an account in the escrow.
     * @param account The account to check ETH balance.
     * @return Current ETH balance of the account.
     */
    function getBalance(address account) public virtual view returns (uint256);

    /**
     * @dev Get the balance of the requested IERC20 token in the escrow.
     * @param account The address to check IERC20 balance.
     * @param token The IERC20 token to check balance.
     * @return The balance of the account.
     */
    function getTokenBalance(address account, address token)
        public
        virtual
        view
        returns (uint256);

    /**
     * @dev Deposits ETH from Escrow Admin into an account.
     * @param account The account to deposit ETH.
     */
    function depositByAdmin(address account) public virtual payable;

    /**
     * @dev Deposits ERC20 tokens from Escrow Admin into an account.
     * Note: The owner, i.e. Escrow Admin must set the allowance before hand.
     * @param account The account to deposit ERC20 tokens.
     * @param token The ERC20 token to deposit.
     * @param amount The amount of ERC20 token to deposit.
     */
    function depositTokenByAdmin(address account, address token, uint256 amount)
        public virtual;

    /**
     * @dev Withdraw ETH from an account to Escrow Admin.
     * @param account The account to withdraw ETH.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawByAdmin(address account, uint256 amount) public virtual;

    /**
     * @dev Withdraw ERC20 token from an account to Escrow Admin.
     * The transfer action is done inside this function.
     * @param account The account to withdraw ERC20 token.
     * @param token The ERC20 token to withdraw.
     * @param amount The amount of ERC20 tokens to withdraw.
     */
    function withdrawTokenByAdmin(
        address account,
        address token,
        uint256 amount
    ) public virtual;

    /**
     * @dev Transfer ETH from one account to another in the Escrow.
     * @param source The account that owns the ETH.
     * @param dest The target account that will own the ETH.
     * @param amount The amount of ETH to transfer.
     */
    function transferByAdmin(address source, address dest, uint256 amount) public virtual;

    /**
     * @dev Transfer ERC20 token from one account to another in the Escrow.
     * @param source The account that owns the ERC20 token.
     * @param dest The target account that will own the ERC20 token.
     * @param token The ERC20 token address.
     * @param amount The amount of ERC20 token to transfer.
     */
    function transferTokenByAdmin(address source, address dest, address token, uint256 amount) public virtual;
}
