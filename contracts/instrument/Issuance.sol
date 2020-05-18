// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../escrow/IIssuanceEscrow.sol";
import "Instrument.sol";

/**
 * @title Base class for issuance.
 */
abstract contract Issuance {
    using Counters for Counters.Counter;

    /**
     * @dev States in issuance lifecycle.
     */
    enum IssuanceState {
        Initiated, Engageable, Cancelled, PartialComplete, Complete
    }

    /**
     * @dev States in engagement lifecycle.
     */
    enum EngagementState {
        Initiated, Active, Cancelled, Complete, Delinquent
    }

    Counters.Counter internal _engagementIds;
    Instrument internal _instrument;
    uint256 internal _issuanceId;
    IIssuanceEscrow internal _issuanceEscrow;
    address internal _makerAddrss; 

    constructor(Instrument instrument, uint256 issuanceId, address makerAddress, address issuanceEscrowAddress) internal {
        _instrument = instrument;
        _issuanceId = issuanceId;
        _makerAddress = makerAddress;
        _issuanceEscrow = IIssuanceEscrow(issuanceEscrowAddress);
    }

    /**
     * @dev Creates a new engagement for the issuance.
     * @param takerAddress Address of the user who engages the issuance.
     * @param takerData Custom properties of the engagemnet.
     * @return ID of the engagement.
     */
    function engage(address takerAddress, bytes takerData) public virtual returns uint256;

    /**
     * @dev Process a custom event. This event could be targeted at an engagement or the whole issuance.
     * @param engagementId ID of the engagement. Not useful if the event is targetted at issuance.
     * @param eventName Name of the custom event.
     * @param eventData Custom properties of the custom event.
     */
    function processEvent(uint256 engagementId, bytes32 eventName, bytes eventData) public virtual;
}