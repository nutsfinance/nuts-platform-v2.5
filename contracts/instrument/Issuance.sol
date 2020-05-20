// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "../escrow/IIssuanceEscrow.sol";
import "../lib/data/Transfers.sol";
import "../lib/data/Payables.sol";
import "./Instrument.sol";

/**
 * @title Base class for issuance.
 */
abstract contract Issuance {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

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
     * @dev The event used to track the creation of a new payable.
     * @param issuanceId The id of the issuance
     * @param itemId The id of the payable
     * @param obligatorAddress The obligator of the payable
     * @param claimorAddress The claimor of the payable
     * @param tokenAddress The asset type of the payable
     * @param amount The asset amount of the payable
     * @param dueTimestamp When is the payable due
     */
    event PayableCreated(uint256 indexed issuanceId, uint256 indexed itemId, address obligatorAddress,
        address claimorAddress, address tokenAddress, uint256 amount, uint256 dueTimestamp);

    /**
     * @dev The event used to track the payment of a payable
     * @param issuanceId The id of the issuance
     * @param itemId The id of the payable
     */
    event PayablePaid(uint256 indexed issuanceId, uint256 indexed itemId);

    /**
     * @dev The event used to track the due of a payable
     * @param issuanceId The id of the issuance
     * @param itemId The id of the payable
     */
    event PayableDue(uint256 indexed issuanceId, uint256 indexed itemId);

    /**
     * @dev The event used to track the update of an existing payable
     * @param issuanceId The id of the issuance
     * @param itemId The id of the payable
     * @param reinitiatedTo The target payable if the current one is reinitiated
     */
    event PayableReinitiated(uint256 indexed issuanceId, uint256 indexed itemId, uint256 reinitiatedTo);

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

    // Common scheduled events
    bytes32 internal constant ISSUANCE_DUE_EVENT = "issuance_due";
    bytes32 internal constant ENGAGEMENT_DUE_EVENT = "engagement_due";

    // Common custom events
    bytes32 internal constant CANCEL_ISSUANCE_EVENT = "cancel_issuance";
    bytes32 internal constant CANCEL_ENGAGEMENT_EVENT = "cancel_engagement";

    address internal _instrumentAddress;
    uint256 internal _issuanceId;
    IIssuanceEscrow internal _issuanceEscrow;
    address internal _makerAddress;
    IssuanceState internal _state;
    uint256 internal _creationTimestamp;

    Counters.Counter internal _engagementIds;
    Transfers.Transfer[] internal _transfers;

    EnumerableSet.UintSet private _payableSet;
    mapping(uint256 => Payables.Payable) internal _payables;

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

    function getPayableCount() public view returns (uint256) {
        return _payableSet.length();
    }

    function getPayable(uint256 index) public view returns (uint256 id, Payables.PayableState state, address obligatorAddress,
        address claimorAddress, address tokenAddress, uint256 amount, uint256 dueTimestamp, uint256 reinitiatedTo) {
        Payables.Payable storage payablee = _payables[_payableSet.at(index)];

        return (payablee.id, payablee.state, payablee.obligatorAddress, payablee.claimorAddress, payablee.tokenAddress,
            payablee.amount, payablee.dueTimestamp, payablee.reinitiatedTo);
    }

    /**
     * @dev Create new payable for the issuance.
     */
    function _createPayable(uint256 id, address obligatorAddress, address claimorAddress, address tokenAddress,
        uint256 amount, uint256 dueTimestamp) internal {
        require(!_payableSet.contains(id), "Issuance: Payable exists.");
        _payableSet.add(id);
        _payables[id] = Payables.Payable({
            id: id,
            state: Payables.PayableState.Unpaid,
            obligatorAddress: obligatorAddress,
            claimorAddress: claimorAddress,
            tokenAddress: tokenAddress,
            amount: amount,
            dueTimestamp: dueTimestamp,
            reinitiatedTo: 0
        });
        emit PayableCreated(_issuanceId, id, obligatorAddress, claimorAddress, tokenAddress, amount, dueTimestamp);
    }

    /**
     * @dev Updates the existing payable as paid
     */
    function _markPayableAsPaid(uint256 id) internal {
        require(_payableSet.contains(id), "Issuance: Payable not exists.");
        _payables[id].state = Payables.PayableState.Paid;
        emit PayablePaid(_issuanceId, id);
    }

    /**
     * @dev Updates the existing payable as due
     */
    function _markPayableAsDue(uint256 id) internal {
        require(_payableSet.contains(id), "Issuance: Payable not exists.");
        _payables[id].state = Payables.PayableState.Due;
        emit PayableDue(_issuanceId, id);
    }

    /**
     * @dev Updates the existing payable as due
     */
    function _reinitiatePayable(uint256 source, uint256 target) internal {
        require(_payableSet.contains(source), "Issuance: Source payable not exists.");
        require(_payableSet.contains(target), "Issuance: Target payable not exists.");
        _payables[source].state = Payables.PayableState.Reinitiated;
        _payables[source].reinitiatedTo = target;
        emit PayableReinitiated(_issuanceId, source, target);
    }
}