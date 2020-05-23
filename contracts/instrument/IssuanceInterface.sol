// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "../lib/protobuf/Transfers.sol";

/**
 * @title Base interface for issuance.
 */
abstract contract IssuanceInterface {
    
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

    /**
     * @dev Initializes the issuance.
     * @param instrumentManagerAddress Address of the instrument manager.
     * @param instrumentAddress Address of the instrument.
     * @param issuanceId ID of the issuance.
     * @param issuanceEscrowAddress Address of the issuance escrow.
     * @param makerAddress Address of the maker who creates the issuance.
     * @param makerData Custom property of issuance.
     * @return transfersData Transfer actions for the issuance.
     */
    function initialize(address instrumentManagerAddress, address instrumentAddress, uint256 issuanceId,
        address issuanceEscrowAddress, address makerAddress, bytes memory makerData)
        public virtual returns (bytes memory transfersData);

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
}