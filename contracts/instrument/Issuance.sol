// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "../escrow/IIssuanceEscrow.sol";
import "../lib/access/AdminAccess.sol";
import "../lib/protobuf/Transfers.sol";
import "../lib/protobuf/Payables.sol";
import "../lib/protobuf/IssuanceData.sol";
import "./Instrument.sol";

/**
 * @title Base class for issuance.
 */
abstract contract Issuance is AdminAccess {
    using EnumerableSet for EnumerableSet.UintSet;

    /*******************************************************
     * Timer Oracle related events.
     *******************************************************/

    /**
     * @dev The event used to schedule contract events after specific time.
     */
    event EventTimeScheduled(uint256 indexed issuanceId, uint256 indexed engagementId, uint256 timestamp,
        bytes32 eventName, bytes eventData);

    /**
     * @dev The event used to schedule contract events after specific block.
     */
    event EventBlockScheduled(uint256 indexed issuanceId, uint256 indexed engagementId, uint256 blockNumber,
        bytes32 eventName, bytes eventPayload);

    /*******************************************************
     * Issuance lifecycle related events.
     *******************************************************/

    event IssuanceCreated(uint256 indexed issuanceId, address indexed makerAddress, uint256 issuanceDueTimestamp);

    event IssuanceCancelled(uint256 indexed issuanceId);

    event IssuanceComplete(uint256 indexed issuanceId);

    /*******************************************************
     * Engagement lifecycle related events.
     *******************************************************/

    event EngagementCreated (uint256 indexed issuanceId, uint256 indexed engagementId, address indexed takerAddress);

    event EngagementCancelled(uint256 indexed issuanceId, uint256 indexed engagementId);

    event EngagementComplete(uint256 indexed issuanceId, uint256 indexed engagementId);

    /*******************************************************
     * Payable lifecycle related events.
     *******************************************************/

    /**
     * @dev The event used to track the creation of a new payable.
     */
    event PayableCreated(uint256 indexed issuanceId, uint256 indexed itemId, uint256 indexed engagementId, address obligatorAddress,
        address claimorAddress, address tokenAddress, uint256 amount, uint256 dueTimestamp);

    /**
     * @dev The event used to track the payment of a payable
     */
    event PayablePaid(uint256 indexed issuanceId, uint256 indexed itemId);

    /**
     * @dev The event used to track the due of a payable
     */
    event PayableDue(uint256 indexed issuanceId, uint256 indexed itemId);

    /**
     * @dev The event used to track the update of an existing payable
     */
    event PayableReinitiated(uint256 indexed issuanceId, uint256 indexed itemId, uint256 reinitiatedTo);

    /**
     * @dev Asset is transferred.
     */
    event AssetTransferred(uint256 indexed issuanceId, uint256 indexed engagementId, Transfer.TransferType transferType,
        address fromAddress, address toAddress, address tokenAddress, uint256 amount, bytes32 action);

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
    IssuanceProperty.IssuanceState internal _state;
    uint256 internal _creationTimestamp;
    uint256 internal _cancelTimestamp;
    uint256 internal _dueTimestamp;
    uint256 internal _completeTimestamp;
    uint256 internal _completionRatio;

    EnumerableSet.UintSet internal _engagementSet;       // We provide engagement ids in Issuance.
    mapping(uint256 => EngagementProperty.Data) internal _engagements;

    EnumerableSet.UintSet private _payableSet;
    mapping(uint256 => Payable.Data) internal _payables;

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
        _state = IssuanceProperty.IssuanceState.Initiated;
        _creationTimestamp = now;
    }

    /**
     * @dev Initializes the issuance.
     * @return transferData Asset transfer actions.
     */
    function initialize() public virtual returns (bytes memory transferData);

    /**
     * @dev Creates a new engagement for the issuance.
     * @param takerAddress Address of the user who engages the issuance.
     * @param takerData Custom properties of the engagemnet.
     * @return engagementId ID of the engagement.
     * @return transfersData Asset transfer actions.
     */
    function engage(address takerAddress, bytes memory takerData)
        public virtual returns (uint256 engagementId, bytes memory transfersData);

    /**
     * @dev Process a custom event. This event could be targeted at an engagement or the whole issuance.
     * @param engagementId ID of the engagement. Not useful if the event is targetted at issuance.
     * @param notifierAddress Address that notifies the custom event.
     * @param eventName Name of the custom event.
     * @param eventData Custom properties of the custom event.
     * @return transfersData Asset transfer actions.
     */
    function processEvent(uint256 engagementId, address notifierAddress, bytes32 eventName, bytes memory eventData)
        public virtual returns (bytes memory transfersData);

    /**
     * @dev Returns property of this issuance.
     * This is the key method to read on-chain issuance status.
     */
    function getIssuanceProperty() public view returns (bytes memory) {
        // Construct paybles data
        Payable.Data[] memory payables = new Payable.Data[](_payableSet.length());
        for (uint256 i = 0; i < _payableSet.length(); i++) {
            payables[i] = _payables[_payableSet.at(i)];
        }

        // Construct engagements data
        EngagementProperty.Data[] memory engagements = new EngagementProperty.Data[](_engagementSet.length());
        for (uint256 i = 0; i < _engagementSet.length(); i++) {
            engagements[i] = _engagements[_engagementSet.at(i)];
            engagements[i].engagementCustomProperty = _getEngagementCustomProperty(_engagementSet.at(i));
        }

        // Construct issuance data
        IssuanceProperty.Data memory issuanceProperty = IssuanceProperty.Data({
            issuanceId: _issuanceId,
            instrumentId: Instrument(_instrumentAddress).getInstrumentId(),
            makerAddress: _makerAddress,
            issuanceCreationTimestamp: _creationTimestamp,
            issuanceDueTimestamp: _dueTimestamp,
            issuanceCancelTimestamp: _cancelTimestamp,
            issuanceCompleteTimestamp: _completeTimestamp,
            completionRatio: _completionRatio,
            issuanceState: _state,
            issuanceCustomProperty: _getIssuanceCustomProperty(),
            engagements: engagements,
            payables: payables
        });

        return IssuanceProperty.encode(issuanceProperty);
    }

    /**
     * @dev Returns the issuance-specific data about the issuance.
     */
    function _getIssuanceCustomProperty() internal virtual view returns (bytes memory);

    /**
     * @dev Returns the issuance-specific data about the engagement.
     * @param engagementId ID of the engagement
     */
    function _getEngagementCustomProperty(uint256 engagementId) internal virtual view returns (bytes memory);

    /**
     * @dev Create new payable for the issuance.
     */
    function _createPayable(uint256 id, uint256 engagementId, address obligatorAddress, address claimorAddress, address tokenAddress,
        uint256 amount, uint256 dueTimestamp) internal {
        require(!_payableSet.contains(id), "Issuance: Payable exists.");
        _payableSet.add(id);
        _payables[id] = Payable.Data({
            payableId: id,
            engagementId: engagementId,
            obligatorAddress: obligatorAddress,
            claimorAddress: claimorAddress,
            tokenAddress: tokenAddress,
            amount: amount,
            payableDueTimestamp: dueTimestamp
        });
        emit PayableCreated(_issuanceId, id, engagementId, obligatorAddress, claimorAddress, tokenAddress, amount, dueTimestamp);
    }

    /**
     * @dev Updates the existing payable as paid
     */
    function _markPayableAsPaid(uint256 id) internal {
        require(_payableSet.contains(id), "Issuance: Payable not exists.");
        // Removes the payable with id
        _payableSet.remove(id);
        delete _payables[id];
        emit PayablePaid(_issuanceId, id);
    }

    /**
     * @dev Updates the existing payable as due
     */
    function _markPayableAsDue(uint256 id) internal {
        require(_payableSet.contains(id), "Issuance: Payable not exists.");
        // Removes the payable with id
        _payableSet.remove(id);
        delete _payables[id];
        emit PayableDue(_issuanceId, id);
    }

    /**
     * @dev Updates the existing payable as due
     */
    function _reinitiatePayable(uint256 id, uint256 reinitiatedTo) internal {
        require(_payableSet.contains(id), "Issuance: Source payable not exists.");
        require(_payableSet.contains(reinitiatedTo), "Issuance: Target payable not exists.");
        // Removes the payable with id
        _payableSet.remove(id);
        delete _payables[id];
        emit PayableReinitiated(_issuanceId, id, reinitiatedTo);
    }
}