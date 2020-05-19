// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "../Issuance.sol";

/**
 * @title A base contract that provide admin access control.
 */
contract LendingIssuance is Issuance {

    /**
     * @param instrumentAddress Address of the instrument contract.
     * @param issuanceId ID of the issuance.
     * @param issuanceEscrowAddress Address of the issuance escrow.
     * @param makerAddress Address of the user who creates the issuance.
     * @param makerData Custom properties of the issuance.
     */
    constructor(address instrumentAddress, uint256 issuanceId, address issuanceEscrowAddress, address makerAddress, bytes memory makerData)
        Issuance(instrumentAddress, issuanceId, issuanceEscrowAddress, makerAddress) public {

    }

    /**
     * @dev Creates a new engagement for the issuance.
     * @param takerAddress Address of the user who engages the issuance.
     * @param takerData Custom properties of the engagemnet.
     * @return engagementId ID of the engagement.
     */
    function engage(address takerAddress, bytes memory takerData) public override returns (uint256 engagementId) {

    }

    /**
     * @dev Process a custom event. This event could be targeted at an engagement or the whole issuance.
     * @param engagementId ID of the engagement. Not useful if the event is targetted at issuance.
     * @param notifierAddress Address that notifies the custom event.
     * @param eventName Name of the custom event.
     * @param eventData Custom properties of the custom event.
     */
    function processEvent(uint256 engagementId, address notifierAddress, bytes32 eventName, bytes memory eventData) public override {

    }
}