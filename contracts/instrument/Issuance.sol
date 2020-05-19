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

    address internal _instrumentAddress;
    uint256 internal _issuanceId;
    IIssuanceEscrow internal _issuanceEscrow;
    address internal _makerAddress;
    IssuanceState internal _state;
    uint256 internal _creationTimestamp;

    Counters.Counter internal _engagementIds;
    Transfers.Transfer[] internal _transfers;

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