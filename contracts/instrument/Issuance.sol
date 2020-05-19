// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../escrow/IIssuanceEscrow.sol";
import "../lib/data/Transfers.sol";
import "../lib/data/SupplementalLineItems.sol";
import "./Instrument.sol";

/**
 * @title Base class for issuance.
 */
abstract contract Issuance {
    using Counters for Counters.Counter;

    /**
     * @dev The event used to schedule contract events after specific time.
     * @param issuanceId The id of the issuance
     * @param engagementId The id of the engagement
     * @param timestamp After when the issuance should be notified
     * @param eventName The name of the custom event
     * @param eventData The payload the custom event
     */
    event EventTimeScheduled(uint256 indexed issuanceId, uint256 indexed engagementId, uint256 timestamp,
        bytes32 eventName, bytes eventData);

    /**
     * @dev The event used to schedule contract events after specific block.
     * @param issuanceId The id of the issuance
     * @param engagementId The id of the engagement
     * @param blockNumber After which block the issuance should be notified
     * @param eventName The name of the custom event
     * @param eventPayload The payload the custom event
     */
    event EventBlockScheduled(uint256 indexed issuanceId, uint256 indexed engagementId, uint256 blockNumber,
        bytes32 eventName, bytes eventPayload);

    event IssuanceCreated(uint256 indexed issuanceId, address indexed makerAddress, uint256 creationTimestamp);

    event IssuanceCancelled(uint256 indexed issuanceId);

    event IssuancePartialComplete(uint256 indexed issuanceId);

    event IssuanceComplete(uint256 indexed issuanceId);

    event EngagementCreated (uint256 indexed issuanceId, uint256 indexed engagementId, address indexed takerAddress, uint256 engagementTimestamp);

    event EngagementCancelled(uint256 indexed issuanceId, uint256 indexed engagementId);

    event EngagementComplete(uint256 indexed issuanceId, uint256 indexed engagementId);

    event EngagementDelinquent(uint256 indexed issuanceId, uint256 indexed engagementId);

    /**
     * @dev The event used to track the creation of a new supplemental line item.
     * @param issuanceId The id of the issuance
     * @param itemId The id of the supplemental line item
     * @param itemType Type of the supplemental line item
     * @param obligatorAddress The obligator of the supplemental line item
     * @param claimorAddress The claimor of the supplemental line item
     * @param tokenAddress The asset type of the supplemental line item
     * @param amount The asset amount of the supplemental line item
     * @param dueTimestamp When is the supplemental line item due
     */
    event SupplementalLineItemCreated(uint256 indexed issuanceId, uint256 indexed itemId, SupplementalLineItem.Type itemType,
        address obligatorAddress, address claimorAddress, address tokenAddress, uint256 amount, uint256 dueTimestamp);

    /**
     * @dev The event used to track the update of an existing supplemental line item
     * @param issuanceId The id of the issuance
     * @param itemId The id of the supplemental line item
     * @param state The new state of the supplemental line item
     * @param reinitiatedTo The target supplemental line item if the current one is reinitiated
     */
    event SupplementalLineItemPaid(uint256 indexed issuanceId, uint256 indexed itemId);

    /**
     * @dev The event used to track the update of an existing supplemental line item
     * @param issuanceId The id of the issuance
     * @param itemId The id of the supplemental line item
     * @param state The new state of the supplemental line item
     * @param reinitiatedTo The target supplemental line item if the current one is reinitiated
     */
    event SupplementalLineItemReinitiated(uint256 indexed issuanceId, uint256 indexed itemId, uint256 reinitiatedTo);

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

    address internal _instrumentAddress;
    uint256 internal _issuanceId;
    IIssuanceEscrow internal _issuanceEscrow;
    address internal _makerAddress;
    IssuanceState internal _state;
    uint256 internal _creationTimestamp;

    Counters.Counter internal _engagementIds;
    Transfers.Transfer[] internal _transfers;
    mapping(uint256 => SupplementalLineItems.Item) internal _supplementalLineItems;

    /**
     * @param instrumentAddress Address of the instrument contract.
     * @param issuanceId ID of the issuance.
     * @param issuanceEscrowAddress Address of the issuance escrow.
     * @param makerAddress Address of the user who creates the issuance.
     */
    constructor(address instrumentAddress, uint256 issuanceId, address issuanceEscrowAddress, address makerAddress) internal {
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
     */
    function engage(address takerAddress, bytes memory takerData) public virtual returns (uint256 engagementId);

    /**
     * @dev Process a custom event. This event could be targeted at an engagement or the whole issuance.
     * @param engagementId ID of the engagement. Not useful if the event is targetted at issuance.
     * @param notifierAddress Address that notifies the custom event.
     * @param eventName Name of the custom event.
     * @param eventData Custom properties of the custom event.
     */
    function processEvent(uint256 engagementId, address notifierAddress, bytes32 eventName, bytes memory eventData) public virtual;


    function getTransferCount() public view returns (uint256) {
        return _transfers.length;
    }

    function getTransfer(uint256 index) public view returns (Transfers.TransferType transferType, address fromAddress,
        address toAddress, address tokenAddress, uint256 amount, bytes32 action) {
        Transfers.Transfer storage transfer = _transfers[index];
        return (transfer.transferType, transfer.fromAddress, transfer.toAddress, transfer.tokenAddress, transfer.amount, transfer.action);
    }
}