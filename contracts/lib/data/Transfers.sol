// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

/**
 * @title Defines the token transfer action.
 */
library Transfers {
    /**
     * @dev Type of transfer action.
     */
    enum TransferType {
        Inbound,            // Instrument Escrow -> Issuance Escrow
        Outbound,           // Issuance Escrow -> Instrument Escrow
        IntraInstrument,    // Transfer inside Instrument Escrow
        IntraIssuance       // Transfer inside Issuance Escrow
    }

    /**
     * @dev Represents one token transfer action.
     */
    struct Transfer {
        TransferType transferType;
        address fromAddress;
        address toAddress;
        address tokenAddress;
        uint256 amount;
        bytes32 action;
    }
}