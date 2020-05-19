// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

/**
 * @title Defines the supplemental line items.
 */
library SupplementalLineItems {
    /**
     * @dev Type of line item.
     */
    enum ItemType {
        Payable
    }

    /**
     * @dev Represents one supplemental line item.
     */
    struct Item {
        uint256 id;
        ItemType itemType;
        address obligatorAddress;
        address claimorAddress;
        address tokenAddress;
        uint256 amount;
        uint256 dueTimestamp;
    }
}
