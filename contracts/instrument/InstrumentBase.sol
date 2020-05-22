// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../lib/access/AdminAccess.sol";
import "../escrow/IInstrumentEscrow.sol";
import "./IIssuance.sol";

/**
 * @title Base class for instrument.
 */
abstract contract InstrumentBase is AdminAccess {

    constructor() internal {
        // Instruments are not proxied. Therefore, we simply initializes here.
        _initialize(msg.sender);
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
     * Instrument by default does not support issuance transaction for high security.
     * @return Whether issuance transaction is supported.
     */
    function supportsIssuanceTransaction() public virtual pure returns (bool) {
        return false;
    }

    /**
     * @dev Creates a new issuance instance.
     * @param instrumentManagerAddress Address of the instrument manager.
     * @param issuanceId ID of the issuance.
     * @param issuanceEscrowAddress Address of the issuance escrow.
     * @param makerAddress Address of the user who creates the issuance.
     * @param makerData Custom properties of the issuance.
     * @return The created issuance instance.
     * @return Initial token transfer actions.
     */
    function createIssuance(address instrumentManagerAddress, uint256 issuanceId, address issuanceEscrowAddress,
        address makerAddress, bytes memory makerData) public virtual returns (IIssuance, bytes memory);
}