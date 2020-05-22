// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

/**
 * @title Base interface for issuance.
 */
abstract contract IIssuance {
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