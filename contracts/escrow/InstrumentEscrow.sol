// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./EscrowBase.sol";
import "./InstrumentEscrowInterface.sol";

/**
 * @title Instrument Escrow that keeps assets that are not yet locked by issuances.
 */
contract InstrumentEscrow is EscrowBase, InstrumentEscrowInterface {

    function initialize(address wethAddress) public {
        super._initialize(wethAddress);
    }

    /**********************************************
     * APIs to deposit and withdraw Ether
     ***********************************************/

    /**
     * @dev Deposits ETHs into the instrument escrow
     */
    function deposit() public override payable {
        address account = msg.sender;
        uint256 amount = msg.value;

        // Updates the balance of WETH
        _increaseBalance(account, address(_weth), amount);
        // Deposits to WETH
        _weth.deposit{value: amount}();

        emit Deposited(account, amount);
    }

    /**
     * @dev Withdraw Ethers from the instrument escrow
     * @param amount The amount of Ethers to withdraw
     */
    function withdraw(uint256 amount) public override {
        address payable account = msg.sender;
        require(getBalance(account) >= amount, "InstrumentEscrow: Insufficient balance.");

        // Updates the balance of WETH
        _decreaseBalance(account, address(_weth), amount);

        // Withdraws ETH from WETH
        _weth.withdraw(amount);
        account.transfer(amount);

        emit Withdrawn(account, amount);
    }

    /***********************************************
     *  APIs to deposit and withdraw IERC20 token
     **********************************************/

    /**
     * @dev Deposit IERC20 token to the instrument escrow.
     * @param token The IERC20 token to deposit.
     * @param amount The amount to deposit.
     */
    function depositToken(address token, uint256 amount) public override {
        address account = msg.sender;
        _increaseBalance(account, token, amount);

        IERC20(token).safeTransferFrom(account, address(this), amount);

        emit TokenDeposited(account, token, amount);
    }

    /**
     * @dev Withdraw IERC20 token from the instrument escrow.
     * @param token The IERC20 token to withdraw.
     * @param amount The amount to withdraw.
     */
    function withdrawToken(address token, uint256 amount) public override {
        address account = msg.sender;
        require(
            getTokenBalance(account, token) >= amount,
            "InstrumentEscrow: Insufficient balance."
        );
        _decreaseBalance(account, token, amount);

        IERC20(token).safeTransfer(account, amount);

        emit TokenWithdrawn(account, token, amount);
    }
}
