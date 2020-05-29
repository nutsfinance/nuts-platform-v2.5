// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "../lib/data/Transfers.sol";
import "../lib/access/AdminAccess.sol";
import "./IssuanceInterface.sol";

/**
 * @title Base class for instrument.
 */
abstract contract InstrumentBase is AdminAccess {

    constructor() internal {
        // Instruments are not proxied. Therefore, we simply initializes here.
        // The instrument creator is the owner.
        AdminAccess._initialize(msg.sender);
    }

    /**
     * @dev Whether the instrument supports Issuance Escrow.
     * If true, Instrument Manager creates a new Issuance Escrow for each new Issuance.
     * Instrument by default supports Issuance Escrow as most Instrument requires a per-issuance custodian.
     * @return Whether Issuance Escrow is supported
     */
    function supportsIssuanceEscrow() public virtual pure returns (bool) {
        return true;
    }

    /**
     * @dev Whether the issuance can withdraw from or deposit to the Issuance Escrow.
     * If true, the issuance contract can withdraw from or deposit to the Issuance Escrow.
     * If false, the issuance contract can only read from the Issuance Escrow. Only the Instrument
     * Manager can withdraw from or deposit to the Issuance Escrow.
     * Instrument by default does not support issuance transaction for higher security.
     * IMPORTANT: This is an experimental feature and should be used with care.
     * @return Whether issuance transaction is supported.
     */
    function supportsIssuanceTransaction() public virtual pure returns (bool) {
        return false;
    }

    /**
     * @dev Returns a unique type ID for the instrument.
     * Instrument Type ID is used to identify the type of the instrument. Instrument ID is instead assigned by
     * Instrument Manager and used to identify an instance of the instrument.
     */
    function getInstrumentTypeID() public pure virtual returns (bytes4);

    /**
     * @dev Creates a new issuance instance.
     * Note: This method is expected to be invoked by Instrument Manager so that the Instrument Manager
     * is the owner of the created Issuance.
     * @param issuanceId ID of the issuance.
     * @param issuanceEscrowAddress Address of the issuance escrow.
     * @param makerAddress Address of the user who creates the issuance.
     * @param makerData Custom properties of the issuance.
     * @return issuance The created issuance instance.
     * @return transfers Initial token transfer actions.
     */
    function createIssuance(uint256 issuanceId, address issuanceEscrowAddress, address makerAddress,
        bytes memory makerData) public virtual returns (IssuanceInterface issuance, Transfers.Transfer[] memory transfers);
}