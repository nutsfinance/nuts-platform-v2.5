// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../escrow/IIssuanceEscrow.sol";
import "../lib/data/Transfers.sol";
import "./Instrument.sol";

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
    address internal _instrumentAddress;
    uint256 internal _issuanceId;
    IIssuanceEscrow internal _issuanceEscrow;
    address internal _makerAddress;
    IssuanceState internal _state;
    uint256 internal _creationTimestamp;

    /**
     * @dev Initializes the issuance.
     * @param instrumentAddress Address of the instrument contract.
     * @param issuanceId ID of the issuance.
     * @param issuanceEscrowAddress Address of the issuance escrow.
     * @param makerAddress Address of the user who creates the issuance.
     * @param makerData Custom properties of the issuance.
     * @return transfers Token transfer actions.
     */
    function initialize(address instrumentAddress, uint256 issuanceId, address issuanceEscrowAddress,
        address makerAddress, bytes memory makerData) public virtual returns (Transfers.Transfer[] memory transfers) {
        
        require(_instrumentAddress == address(0x0), "Issuance: Already initialized.");
        require(instrumentAddress != address(0x0), "Issuance: Instrument must be set.");
        require(issuanceId != 0, "Issuance: ID not set.");
        require(issuanceEscrowAddress != address(0x0), "Issuance: Issuance Escrow not set.");
        require(makerAddress != address(0x0), "Issuance: Maker address not set.");

        _instrumentAddress = instrumentAddress;
        _issuanceId = issuanceId;
        _issuanceEscrow = IIssuanceEscrow(issuanceEscrowAddress);
        _makerAddress = makerAddress;
        _state = IssuanceState.Initiated;
        _creationTimestamp = now;
    }

    /**
     * @dev Creates a new engagement for the issuance.
     * @param takerAddress Address of the user who engages the issuance.
     * @param takerData Custom properties of the engagemnet.
     * @return engagementId ID of the engagement.
     * @return transfers Token transfer actions.
     */
    function engage(address takerAddress, bytes memory takerData) public virtual returns (uint256 engagementId, Transfers.Transfer[] memory transfers);

    /**
     * @dev Process a custom event. This event could be targeted at an engagement or the whole issuance.
     * @param engagementId ID of the engagement. Not useful if the event is targetted at issuance.
     * @param eventName Name of the custom event.
     * @param eventData Custom properties of the custom event.
     * @return transfers Token transfer actions.
     */
    function processEvent(uint256 engagementId, bytes32 eventName, bytes memory eventData) public virtual returns (Transfers.Transfer[] memory transfers);
}