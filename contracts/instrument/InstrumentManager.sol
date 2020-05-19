// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../escrow/InstrumentEscrow.sol";
import "../escrow/IssuanceEscrow.sol";
import "./Issuance.sol";
import "./IInstrumentManager.sol";

contract InstrumentManager is IInstrumentManager {

    using Counters for Counters.Counter;

    struct IssuanceProperty {
        Issuance issuance;
        IssuanceEscrow issuanceEscrow;
    }

    address private _instrumentAddress;
    address private _fspAddress;
    address private _depositTokenAddress;
    uint256 private _instrumentId;
    InstrumentEscrow private _instrumentEscrow;
    Counters.Counter private _issuanceIds;
    mapping(uint256 => IssuanceProperty) private _issuances;

    // Instrument expiration
    bool internal _active;
    uint256 internal _terminationTimestamp;         // When the instrument is auto-terminated.
    uint256 internal _overrideTimestamp;            // When the instrument can be manually terminated.

    /**
     * @dev Constructor for Instrument Manager.
     * @param instrumentId ID of the instrument.
     * @param fspAddress Address of the FSP who activates the instrument.
     * @param depositTokenAddress Address of the token used as deposit in activating instrument.
     * @param instrumentData Custom properties of the instrument.
     */
    constructor(address instrumentAddress, uint256 instrumentId, address fspAddress, address depositTokenAddress,
        bytes memory instrumentData) public {
        
        require(instrumentAddress != address(0x0), "InstrumentManager: Instrument not set.");
        require(instrumentId != 0, "InstrumentManager: ID not set.");
        require(fspAddress != address(0x0), "InstrumentManager: FSP not set.");
        require(depositTokenAddress != address(0x0), "InstrumentManager: Deposit token not set.");

        _instrumentAddress = instrumentAddress;
        _instrumentId = instrumentId;
        _fspAddress = fspAddress;
        _depositTokenAddress = depositTokenAddress;
        _active = true;
        (_terminationTimestamp, _overrideTimestamp) = abi.decode(instrumentData, (uint256, uint256));

        // Creates the Instrument Escrow
        _instrumentEscrow = new InstrumentEscrow();

        // Initializes the instrument.
        Instrument(_instrumentAddress).initialize(_instrumentId, _fspAddress, address(_instrumentEscrow));
    }

    /**
     * @dev Deactivates the instrument. Once deactivated, the instrument cannot create new issuance,
     * but existing active issuances are not affected.
     */
    function deactivate() public override {

    }

    /**
     * @dev Creates a new issuance.
     * @param makerData Custom properties of the issuance.
     * @return issuanceId ID of the created issuance.
     */
    function createIssuance(bytes memory makerData) public override returns (uint256 issuanceId) {}

    /**
     * @dev Engages an existing issuance.
     * @param issuanceId ID of the issuance.
     * @param takerData Custom properties of the engagement.
     * @return engagementId ID of the engagement.
     */
    function engageIssuance(uint256 issuanceId, bytes memory takerData) public override returns (uint256 engagementId) {}

    /**
     * @dev Process a custom event on the issuance or the engagement.
     * @param issuanceId ID of the issuance.
     * @param engagementId ID of the engagement. If the event is for issuance, this param is not used.
     * @param eventName Name of the custom event.
     * @param eventData Data of the custom event.
     */
    function processEvent(uint256 issuanceId, uint256 engagementId, bytes32 eventName, bytes memory eventData) public override {}

    /**
     * @dev Returns the instrument contract address.
     * @return The instrument contract address.
     */
    function getInstrumentAddress() public override view returns (address) {
        return _instrumentAddress;
    }

    /**
     * @dev Returns the address of the FSP which activates the instrument.
     * @return Address of the FSP.
     */
    function getFspAddress() public override view returns (address) {
        return _fspAddress;
    }

    /**
     * @dev Returns the ID of the instrument.
     * @return ID of the instrument.
     */
    function getInstrumentId() public override view returns (uint256) {
        return _instrumentId;
    }

    /**
     * @dev Returns the Instrument Escrow of the instrument.
     * @return Instrument Escrow of the instrument.
     */
    function getInstrumentEscrow() public override view returns (IInstrumentEscrow) {
        return _instrumentEscrow;
    }

    /**
     * @dev Returns the total number of issuances.
     * @return Total number of issuances.
     */
    function getIssuanceCount() public override view returns (uint256) {
        return _issuanceIds.current();
    }

    /**
     * @dev Returns the issuance by issuance ID.
     * @param issuanceId ID of the issuance.
     * @return issuance The issuance to lookup.
     */
    function getIssuance(uint256 issuanceId) public override view returns (Issuance issuance) {
        return _issuances[issuanceId].issuance;
    }

    /**
     * @dev Returns the Issuance Escrow by issuance ID.
     * @param issuanceId ID of the issuance.
     * @return issuanceEscrow The Issuance Escrow of the issuance.
     */
    function getIssuanceEscrow(uint256 issuanceId) public override view returns (IIssuanceEscrow issuanceEscrow) {
        return _issuances[issuanceId].issuanceEscrow;
    }
}