// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../lib/data/Transfers.sol";
import "../../lib/protobuf/IssuanceData.sol";
import "../../lib/protobuf/SwapData.sol";
import "../../escrow/InstrumentEscrowInterface.sol";
import "../IssuanceBase.sol";
import "./SwapInstrument.sol";

/**
 * @title 1 to 1 swap issuance contract.
 */
contract SwapIssuance is IssuanceBase {
    using SafeMath for uint256;

    // Constants
    uint256 internal constant ENGAGEMENT_ID = 1; // Since it's 1 to 1, we use a constant engagement id 1
    uint256 internal constant DURATION_MIN = 1; // Minimum duration is 1 day
    uint256 internal constant DURATION_MAX = 90; // Maximum duration is 90 days

    // Swap issuance properties
    SwapIssuanceProperty.Data private _sip;

    /**
     * @dev Initializes the issuance.
     * @param instrumentManagerAddress Address of the instrument manager.
     * @param instrumentAddress Address of the instrument.
     * @param issuanceId ID of the issuance.
     * @param issuanceEscrowAddress Address of the issuance escrow.
     * @param makerAddress Address of the maker who creates the issuance.
     * @param makerData Custom property of issuance.
     * @return transfers Transfer actions for the issuance.
     */
    function initialize(address instrumentManagerAddress, address instrumentAddress, uint256 issuanceId,
        address issuanceEscrowAddress, address makerAddress, bytes memory makerData)
        public override returns (Transfers.Transfer[] memory transfers) {

        require(SwapInstrument(instrumentAddress).isMakerAllowed(makerAddress), "SwapIssuance: Maker not allowed.");
        IssuanceBase._initialize(instrumentManagerAddress, instrumentAddress, issuanceId, issuanceEscrowAddress, makerAddress);

        (_sip.inputTokenAddress, _sip.outputTokenAddress, _sip.inputAmount, _sip.outputAmount, _sip.duration) = abi
            .decode(makerData, (address, address, uint256, uint256, uint256));

        // Validates parameters.
        require(_sip.inputTokenAddress != address(0x0), "Input token not set");
        require(_sip.outputTokenAddress != address(0x0), "Output token not set");
        require(_sip.inputAmount > 0, "Input amount not set");
        require(_sip.outputAmount > 0, "Output amount not set");
        require(_sip.duration >= DURATION_MIN && _sip.duration <= DURATION_MAX, "Invalid duration");

        // Validate input token balance
        uint256 inputTokenBalance = _instrumentManager.getInstrumentEscrow().getTokenBalance(makerAddress, _sip.inputTokenAddress);
        require(inputTokenBalance >= _sip.inputAmount, "Insufficient input balance");

        // Sets common properties
        _issuanceProperty.issuanceDueTimestamp = now.add(1 days * _sip.duration);
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Engageable;
        emit IssuanceCreated(_issuanceProperty.issuanceId, makerAddress, _issuanceProperty.issuanceDueTimestamp);

        // Scheduling Issuance Due event
        emit EventTimeScheduled(_issuanceProperty.issuanceId, 0, _issuanceProperty.issuanceDueTimestamp, ISSUANCE_DUE_EVENT, "");

        // Transfers principal token
        // Input token inbound transfer: Maker --> Maker
        transfers = new Transfers.Transfer[](1);
        transfers[0] = Transfers.Transfer(Transfers.TransferType.Inbound, makerAddress, makerAddress,
            _sip.inputTokenAddress, _sip.inputAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, 0, Transfers.TransferType.Inbound, makerAddress, makerAddress,
            _sip.inputTokenAddress, _sip.inputAmount, "Input in");

        // Create payable 1: Custodian --> Maker
        _createPayable(1, 0, address(_issuanceEscrow), makerAddress, _sip.inputTokenAddress,
            _sip.inputAmount, _issuanceProperty.issuanceDueTimestamp);
    }

    /**
     * @dev Creates a new engagement for the issuance. Only admin(Instrument Manager) can call this method.
     * @param takerAddress Address of the user who engages the issuance.
     * @return engagementId ID of the engagement.
     * @return transfers Asset transfer actions.
     */
    function engage(address takerAddress, bytes memory /** takerData */)
        public override onlyAdmin returns (uint256 engagementId, Transfers.Transfer[] memory transfers) {
        require(SwapInstrument(_instrumentAddress).isTakerAllowed(takerAddress), "SwapIssuance: Taker not allowed.");
        require(_issuanceProperty.issuanceState == IssuanceProperty.IssuanceState.Engageable, "Issuance not Engageable");
        require(now <= _issuanceProperty.issuanceDueTimestamp, "Issuance due");
        require(_engagementSet.length() == 0, "Already engaged");

        // Validates output balance
        uint256 outputTokenBalance = _instrumentManager.getInstrumentEscrow().getTokenBalance(takerAddress, _sip.outputTokenAddress);
        require(outputTokenBalance >= _sip.outputAmount, "Insufficient output balance");

        engagementId = ENGAGEMENT_ID;
        _engagementSet.add(ENGAGEMENT_ID);

        // Set common engagement property
        EngagementProperty.Data storage engagement = _engagements[ENGAGEMENT_ID];
        engagement.engagementId = ENGAGEMENT_ID;
        engagement.takerAddress = takerAddress;
        engagement.engagementCreationTimestamp = now;
        engagement.engagementCompleteTimestamp = now;
        engagement.engagementDueTimestamp = now;
        engagement.engagementState = EngagementProperty.EngagementState.Complete;
        emit EngagementCreated(_issuanceProperty.issuanceId, ENGAGEMENT_ID, takerAddress);
        emit EngagementComplete(_issuanceProperty.issuanceId, ENGAGEMENT_ID);

        // Set common issuance property
        _issuanceProperty.issuanceCompleteTimestamp = now;
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Complete;
        _issuanceProperty.completionRatio = COMPLETION_RATIO_RANGE;
        emit IssuanceComplete(_issuanceProperty.issuanceId, COMPLETION_RATIO_RANGE);

        transfers = new Transfers.Transfer[](2);
        // Output token intra-instrument transfer: Taker -> Maker
        transfers[0] = Transfers.Transfer(Transfers.TransferType.IntraInstrument, takerAddress,
            _issuanceProperty.makerAddress, _sip.outputTokenAddress, _sip.outputAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfers.TransferType.IntraInstrument, takerAddress,
            _issuanceProperty.makerAddress, _sip.outputTokenAddress, _sip.outputAmount, "Output transfer");
        // Input token outbound transfer: Maker -> Taker
        transfers[1] = Transfers.Transfer(Transfers.TransferType.Outbound, _issuanceProperty.makerAddress,
            takerAddress, _sip.inputTokenAddress, _sip.inputAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfers.TransferType.Outbound, _issuanceProperty.makerAddress,
            takerAddress, _sip.inputTokenAddress, _sip.inputAmount, "Input out");

        // Mark payable 1 as paid
        _markPayableAsPaid(1);
    }

    /**
     * @dev Process a custom event. This event could be targeted at an engagement or the whole issuance.
     * Only admin(Instrument Manager) can call this method.
     * @param notifierAddress Address that notifies the custom event.
     * @param eventName Name of the custom event.
     * @return transfers Asset transfer actions.
     */
    function processEvent(uint256 /** engagementId */, address notifierAddress, bytes32 eventName, bytes memory /** eventData */)
        public override onlyAdmin returns (Transfers.Transfer[] memory transfers) {
         if (eventName == ISSUANCE_DUE_EVENT) {
            return _processIssuanceDue();
        } else if (eventName == CANCEL_ISSUANCE_EVENT) {
            return _cancelIssuance(notifierAddress);
        } else {
            revert("Unknown event");
        }
    }

    /**
     * @dev Processes the Issuance Due event.
     */
    function _processIssuanceDue() private returns (Transfers.Transfer[] memory transfers) {
        // Engagement Due will be processed only when:
        // 1. Issuance is in Engageable state, which means there is no Engagement. Otherwise the issuance is in Complete state.
        // 2. Issuance due timestamp is passed
        if (_issuanceProperty.issuanceState != IssuanceProperty.IssuanceState.Engageable
            || now < _issuanceProperty.issuanceDueTimestamp) return new Transfers.Transfer[](0);

        // The issuance is now complete
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Complete;
        _issuanceProperty.issuanceCompleteTimestamp = now;
        emit IssuanceComplete(_issuanceProperty.issuanceId, 0);

        transfers = new Transfers.Transfer[](1);
        // Input token outbound transfer: Maker --> Maker
        transfers[0] = Transfers.Transfer(Transfers.TransferType.Outbound, _issuanceProperty.makerAddress, _issuanceProperty.makerAddress,
            _sip.inputTokenAddress, _sip.inputAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, 0, Transfers.TransferType.Outbound,
            _issuanceProperty.makerAddress, _issuanceProperty.makerAddress, _sip.inputTokenAddress, _sip.inputAmount, "Input out");

        // Mark payable 1 as paid
        _markPayableAsPaid(1);
    }

    /**
     * @dev Cancels the lending issuance.
     * @param notifierAddress Address of the caller who cancels the issuance.
     */
    function _cancelIssuance(address notifierAddress) private returns (Transfers.Transfer[] memory transfers) {
        // Cancel Issuance must be processed in Engageable state
        require(_issuanceProperty.issuanceState == IssuanceProperty.IssuanceState.Engageable, "Cancel issuance not engageable");
        // Only maker can cancel issuance
        require(notifierAddress == _issuanceProperty.makerAddress, "Only maker can cancel issuance");

        // The issuance is now cancelled
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Cancelled;
        _issuanceProperty.issuanceCancelTimestamp = now;
        emit IssuanceCancelled(_issuanceProperty.issuanceId);

        transfers = new Transfers.Transfer[](1);
        // Input token outbound transfer: Maker --> Maker
        transfers[0] = Transfers.Transfer(Transfers.TransferType.Outbound, _issuanceProperty.makerAddress, _issuanceProperty.makerAddress,
            _sip.inputTokenAddress, _sip.inputAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, 0, Transfers.TransferType.Outbound,
            _issuanceProperty.makerAddress, _issuanceProperty.makerAddress, _sip.inputTokenAddress, _sip.inputAmount, "Input out");

        // Mark payable 1 as paid
        _markPayableAsPaid(1);
    }

    /**
     * @dev Returns the issuance-specific data about the issuance.
     */
    function _getIssuanceCustomProperty() internal override view returns (bytes memory) {
        return SwapIssuanceProperty.encode(_sip);
    }

    /**
     * @dev Returns the issuance-specific data about the engagement.
     */
    function _getEngagementCustomProperty(uint256 /** engagementId */) internal override view returns (bytes memory) {
        return new bytes(0);
    }
}
