// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

/**
 * @title Defines the payables.
 */
library Payables {
    /**
     * @dev State of the payables
     */
    enum PayableState {
        Unpaid, Paid, Due, Reinitiated
    }

    /**
     * @dev Represents one payable.
     */
    struct Payable {
        uint256 id;
        PayableState state;
        address obligatorAddress;
        address claimorAddress;
        address tokenAddress;
        uint256 amount;
        uint256 dueTimestamp;
        uint256 reinitiatedTo;
    }
}
