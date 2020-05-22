// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "./EscrowInterface.sol";

/**
 * @title Interface for Instrument Escrow.
 * @dev This is the interface with which external users interact with Instrument Escrow.
 */
abstract contract InstrumentEscrowInterface is EscrowInterface {
    /**
     * ETH is deposited into instrument escrow.
     * @param depositer The address who deposits ETH.
     * @param amount The deposit token amount.
     */
    event Deposited(address indexed depositer, uint256 amount);

    /**
     * ETH is withdrawn from instrument escrow.
     * @param withdrawer The address who withdraws ETH.
     * @param amount The withdrawal token amount.
     */
    event Withdrawn(address indexed withdrawer, uint256 amount);

    /**
     * Token is deposited into instrument escrow.
     * @param depositer The address who deposits token.
     * @param token The deposit token address.
     * @param amount The deposit token amount.
     */
    event TokenDeposited(
        address indexed depositer,
        address indexed token,
        uint256 amount
    );

    /**
     * Token is withdrawn from instrument escrow.
     * @param withdrawer The address who withdraws token.
     * @param token The withdrawal token address.
     * @param amount The withdrawal token amount.
     */
    event TokenWithdrawn(
        address indexed withdrawer,
        address indexed token,
        uint256 amount
    );

    /**********************************************
     * APIs to deposit and withdraw Ether
     ***********************************************/

    /**
     * @dev Deposits ETHs into the instrument escrow
     */
    function deposit() public virtual payable;

    /**
     * @dev Withdraw Ethers from the instrument escrow
     * @param amount The amount of Ethers to withdraw
     */
    function withdraw(uint256 amount) public virtual;

    /***********************************************
     *  APIs to deposit and withdraw IERC20 token
     **********************************************/

    /**
     * @dev Deposit IERC20 token to the instrument escrow.
     * @param token The IERC20 token to deposit.
     * @param amount The amount to deposit.
     */
    function depositToken(address token, uint256 amount) public virtual;

    /**
     * @dev Withdraw IERC20 token from the instrument escrow.
     * @param token The IERC20 token to withdraw.
     * @param amount The amount to withdraw.
     */
    function withdrawToken(address token, uint256 amount) public virtual;

}
