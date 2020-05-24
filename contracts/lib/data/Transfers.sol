// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

/**
 * @title Library to represent token transfers.
 */
library Transfers {
    /**
     * @dev Type of transfer action.
     */
    enum TransferType {
        Inbound,                    // Instrument Escrow -> Issuance Escrow
        Outbound,                   // Issuance Escrow -> Instrument Escrow
        IntraIssuance,              // Transfer inside Issance Escrow
        IntraInstrument             // Transfer inside Instrument Escrow
    }

    /**
     * @dev Represent a single token transfer action triggerred from issuance.
     * As it's triggered from Instrument, the transfer is either from Issuance Escrow
     * to Instrument Escrow, or inside the same Issuance Escrow.
     */
    struct Transfer {
        TransferType transferType;
        address fromAddress;        // Where the token is transferred from.
        address toAddress;          // Where the token is transferred to.
        address tokenAddress;
        uint256 amount;
    }
}
