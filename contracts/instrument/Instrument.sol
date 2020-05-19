// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../lib/access/AdminAccess.sol";
import "../escrow/IInstrumentEscrow.sol";
import "./Issuance.sol";

/**
 * @title Base class for instrument.
 */
abstract contract Instrument is AdminAccess {

    // Instrument common fields are marked as private so that it's not changeable
    // by child contracts.
    uint256 private _instrumentId;
    address private _fspAddress;
    IInstrumentEscrow private _instrumentEscrow;

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
     * @dev Initializes the instrument.
     * @param instrumentId ID of the instrument.
     * @param fspAddress Address of the FSP who activates the instrument.
     * @param instrumentEscrowAddress Address of the Instrument Escrow.
     */
    function initialize(uint256 instrumentId, address fspAddress, address instrumentEscrowAddress) public virtual {
        require(_instrumentId == 0, "Instrument: Already initialized.");
        require(instrumentId != 0, "Instrument: ID not set.");
        require(fspAddress != address(0x0), "Instrument: FSP not set.");
        require(instrumentEscrowAddress != address(0x0), "Instrument: Instrument Escrow not set.");

        _instrumentId = instrumentId;
        _fspAddress = fspAddress;
        _instrumentEscrow = IInstrumentEscrow(instrumentEscrowAddress);
    }

    /**
     * @dev Creates a new issuance instance.
     * @return The created issuance instance.
     */
    function createIssuance() public virtual returns (Issuance);

    /**
     * @dev Returns the ID of the instrument.
     * @return Instrument ID.
     */
    function getInstrumentId() public view returns (uint256) {
        return _instrumentId;
    }

    /**
     * @dev Returns the address of the FSP who activates the instrument.
     * @return Address of FSP.
     */
    function getFspAddress() public view returns (address) {
        return _fspAddress;
    }

    /**
     * @dev Returns the Instrument Escrow of the instrument.
     * @return The Instrument Escrow for this Instrument.
     */
    function getInstrumentEscrow() public view returns (IInstrumentEscrow) {
        return _instrumentEscrow;
    }
}