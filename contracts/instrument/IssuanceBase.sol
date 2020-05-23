// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "../escrow/IssuanceEscrowInterface.sol";
import "../lib/access/AdminAccess.sol";
import "../lib/protobuf/Transfers.sol";
import "../lib/protobuf/Payables.sol";
import "../lib/protobuf/IssuanceData.sol";

import "./InstrumentManagerInterface.sol";
import "./IssuanceInterface.sol";

/**
 * @title Base class for issuance.
 */
abstract contract IssuanceBase is IssuanceInterface, AdminAccess {
    using EnumerableSet for EnumerableSet.UintSet;

    // Constant
    uint256 internal constant COMPLETION_RATIO_RANGE = 10000;

    // Common scheduled events
    bytes32 internal constant ISSUANCE_DUE_EVENT = "issuance_due";
    bytes32 internal constant ENGAGEMENT_DUE_EVENT = "engagement_due";

    // Common custom events
    bytes32 internal constant CANCEL_ISSUANCE_EVENT = "cancel_issuance";
    bytes32 internal constant CANCEL_ENGAGEMENT_EVENT = "cancel_engagement";

    // Instrument manager provides general information, including instrument Id, instrument escrow address and fsp address.
    InstrumentManagerInterface internal _instrumentManager;
    // Instrument provides instrumentd-specific information.
    address internal _instrumentAddress;
    IssuanceEscrowInterface internal _issuanceEscrow;
    IssuanceProperty.Data internal _issuanceProperty;

    // Engagement properties
    EnumerableSet.UintSet internal _engagementSet;
    mapping(uint256 => EngagementProperty.Data) internal _engagements;

    // Payable properties
    EnumerableSet.UintSet private _payableSet;
    mapping(uint256 => Payable.Data) internal _payables;

    /**
     * @param instrumentManagerAddress Address of the instrument manager.
     * @param instrumentAddress Address of the instrument contract.
     * @param issuanceId ID of the issuance.
     * @param issuanceEscrowAddress Address of the issuance escrow.
     * @param makerAddress Address of the user who creates the issuance.
     */
    function _initialize(address instrumentManagerAddress, address instrumentAddress, uint256 issuanceId,
        address issuanceEscrowAddress, address makerAddress) internal {
        
        require(_instrumentAddress == address(0x0), "Issuance: Already initialized.");
        require(instrumentManagerAddress != address(0x0), "Issuance: Instrument Manager must be set.");
        require(instrumentAddress != address(0x0), "Issuance: Instrument must be set.");
        require(issuanceId != 0, "Issuance: ID not set.");
        require(issuanceEscrowAddress != address(0x0), "Issuance: Issuance Escrow not set.");
        require(makerAddress != address(0x0), "Issuance: Maker address not set.");

        // Instrument Manager is the owner of the issuance.
        AdminAccess._initialize(instrumentManagerAddress);

        _instrumentManager = InstrumentManagerInterface(instrumentManagerAddress);
        _instrumentAddress = instrumentAddress;
        _issuanceEscrow = IssuanceEscrowInterface(issuanceEscrowAddress);

        _issuanceProperty.instrumentId = _instrumentManager.getInstrumentId();
        _issuanceProperty.issuanceId = issuanceId;
        _issuanceProperty.makerAddress = makerAddress;
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Initiated;
        _issuanceProperty.issuanceCreationTimestamp = now;
    }

    /**
     * @dev Returns property of this issuance.
     * This is the key method to read on-chain issuance status.
     */
    function getIssuanceProperty() public view returns (bytes memory) {
        // Construct issuance data
        IssuanceProperty.Data memory issuanceProperty = _issuanceProperty;
        issuanceProperty.issuanceCustomProperty = _getIssuanceCustomProperty();

        // Construct paybles data
        issuanceProperty.payables = new Payable.Data[](_payableSet.length());
        for (uint256 i = 0; i < _payableSet.length(); i++) {
            issuanceProperty.payables[i] = _payables[_payableSet.at(i)];
        }

        // Construct engagements data
        issuanceProperty.engagements = new EngagementProperty.Data[](_engagementSet.length());
        for (uint256 i = 0; i < _engagementSet.length(); i++) {
            uint256 engagementId = _engagementSet.at(i);
            issuanceProperty.engagements[i] = _engagements[engagementId];
            issuanceProperty.engagements[i].engagementCustomProperty = _getEngagementCustomProperty(engagementId);
        }

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
    function _createPayable(uint256 payableId, uint256 engagementId, address obligatorAddress, address claimorAddress, address tokenAddress,
        uint256 amount, uint256 payableDueTimestamp) internal {
        require(!_payableSet.contains(payableId), "Issuance: Payable exists.");
        _payableSet.add(payableId);
        Payable.Data storage payablee = _payables[payableId];
        payablee.payableId = payableId;
        payablee.engagementId = engagementId;
        payablee.obligatorAddress = obligatorAddress;
        payablee.claimorAddress = claimorAddress;
        payablee.tokenAddress = tokenAddress;
        payablee.amount = amount;
        payablee.payableDueTimestamp = payableDueTimestamp;
        emit PayableCreated(_issuanceProperty.issuanceId, payableId, engagementId, obligatorAddress, claimorAddress,
            tokenAddress, amount, payableDueTimestamp);
    }

    /**
     * @dev Updates the existing payable as paid
     */
    function _markPayableAsPaid(uint256 payableId) internal {
        require(_payableSet.contains(payableId), "Issuance: Payable not exists.");
        // Removes the payable with the payable id
        _payableSet.remove(payableId);
        delete _payables[payableId];
        emit PayablePaid(_issuanceProperty.issuanceId, payableId);
    }

    /**
     * @dev Updates the existing payable as due
     */
    function _markPayableAsDue(uint256 payableId) internal {
        require(_payableSet.contains(payableId), "Issuance: Payable not exists.");
        // Removes the payable with payable id
        _payableSet.remove(payableId);
        delete _payables[payableId];
        emit PayableDue(_issuanceProperty.issuanceId, payableId);
    }

    /**
     * @dev Updates the existing payable as due
     */
    function _reinitiatePayable(uint256 payableId, uint256 reinitiatedTo) internal {
        require(_payableSet.contains(payableId), "Issuance: Source payable not exists.");
        require(_payableSet.contains(reinitiatedTo), "Issuance: Target payable not exists.");
        // Removes the payable with payable id
        _payableSet.remove(payableId);
        delete _payables[payableId];
        emit PayableReinitiated(_issuanceProperty.issuanceId, payableId, reinitiatedTo);
    }
}