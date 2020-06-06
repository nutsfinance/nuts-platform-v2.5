// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../lib/data/Transfers.sol";
import "../../lib/protobuf/IssuanceData.sol";
import "../../lib/protobuf/MultiSwapData.sol";
import "../../escrow/InstrumentEscrowInterface.sol";
import "../IssuanceBase.sol";
import "./MultiSwapInstrument.sol";

/**
 * @title 1 to N swap issuance contract.
 */
contract MultiSwapIssuance is IssuanceBase {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _engagementIds;
    Counters.Counter private _payableIds;

    // Multi-swap issuance properties
    MultiSwapIssuanceProperty.Data private _mip;

    // Multi-swap engagement properties
    mapping(uint256 => MultiSwapEngagementProperty.Data) private _meps;

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

        MultiSwapInstrument multiSwapInstrument = MultiSwapInstrument(instrumentAddress);
        require(multiSwapInstrument.isMakerAllowed(makerAddress), "SwapIssuance: Maker not allowed.");
        IssuanceBase._initialize(instrumentManagerAddress, instrumentAddress, issuanceId, issuanceEscrowAddress, makerAddress);

        uint256 issuanceDuration;
        (issuanceDuration, _mip.inputTokenAddress, _mip.outputTokenAddress, _mip.inputAmount, _mip.outputAmount, _mip.minEngagementOutputAmount,
            _mip.maxEngagementOutputAmount) = abi.decode(makerData, (uint256, address, address, uint256, uint256, uint256, uint256));

        // Validates parameters.
        require(_mip.inputTokenAddress != address(0x0), "MultiSwapIssuance: Input token not set");
        require(_mip.outputTokenAddress != address(0x0), "MultiSwapIssuance: Output token not set");
        require(_mip.inputAmount > 0, "MultiSwapIssuance: Input amount not set");
        require(_mip.outputAmount > 0, "MultiSwapIssuance: Output amount not set");
        require(_mip.outputAmount >= _mip.minEngagementOutputAmount && _mip.minEngagementOutputAmount <= _mip.maxEngagementOutputAmount,
            "MultiSwapIssuance: Invalid engagement output range");
        require(multiSwapInstrument.isIssuanceDurationValid(issuanceDuration), "MultiSwapIssuance: Invalid duration");

        // Validate input token balance
        uint256 inputTokenBalance = _instrumentManager.getInstrumentEscrow().getTokenBalance(makerAddress, _mip.inputTokenAddress);
        require(inputTokenBalance >= _mip.inputAmount, "MultiSwapIssuance: Insufficient input balance");

        // Sets common properties
        _issuanceProperty.issuanceDueTimestamp = now.add(issuanceDuration);
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Engageable;
        emit IssuanceCreated(_issuanceProperty.issuanceId, makerAddress, _issuanceProperty.issuanceDueTimestamp);

        // Sets multi-swap issuance property
        _mip.remainingInputAmount = _mip.inputAmount;

        // Scheduling Issuance Due event
        emit EventTimeScheduled(_issuanceProperty.issuanceId, 0, _issuanceProperty.issuanceDueTimestamp, ISSUANCE_DUE_EVENT, "");

        // Transfers principal token
        // Input token inbound transfer: Maker --> Maker
        transfers = new Transfers.Transfer[](1);
        transfers[0] = Transfers.Transfer(Transfers.TransferType.Inbound, makerAddress, makerAddress,
            _mip.inputTokenAddress, _mip.inputAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, 0, Transfers.TransferType.Inbound, makerAddress, makerAddress,
            _mip.inputTokenAddress, _mip.inputAmount, "Input in");

        // Create payable 1: Custodian --> Maker
        _payableIds.increment();
        _createPayable(_payableIds.current(), 0, address(_issuanceEscrow), makerAddress, _mip.inputTokenAddress,
            _mip.inputAmount, _issuanceProperty.issuanceDueTimestamp);
    }

    /**
     * @dev Creates a new engagement for the issuance. Only admin(Instrument Manager) can call this method.
     * @param takerAddress Address of the user who engages the issuance.
     * @param takerData Custom property of the engagement.
     * @return engagementId ID of the engagement.
     * @return transfers Asset transfer actions.
     */
    function engage(address takerAddress, bytes memory takerData)
        public override onlyAdmin returns (uint256 engagementId, Transfers.Transfer[] memory transfers) {
        require(MultiSwapInstrument(_instrumentAddress).isTakerAllowed(takerAddress), "MultiSwapIssuance: Taker not allowed.");
        require(now <= _issuanceProperty.issuanceDueTimestamp, "MultiSwapIssuance: Issuance due");
        require(_issuanceProperty.issuanceState == IssuanceProperty.IssuanceState.Engageable, "MultiSwapIssuance: Issuance not Engageable");

        uint256 outputAmount = abi.decode(takerData, (uint256));
        uint256 inputAmount = outputAmount.mul(_mip.inputAmount).div(_mip.outputAmount);
        require(_mip.remainingInputAmount >= inputAmount, "MultiSwapIssuance: Input exceeded");
        require(outputAmount >= _mip.minEngagementOutputAmount && outputAmount <= _mip.maxEngagementOutputAmount,
            "MultiSwapIssuance: Invalid engagement output");

        // Validates output balance
        uint256 outputTokenBalance = _instrumentManager.getInstrumentEscrow().getTokenBalance(takerAddress, _mip.outputTokenAddress);
        require(outputTokenBalance >= outputAmount, "MultiSwapIssuance: Insufficient output balance");

        _engagementIds.increment();
        engagementId = _engagementIds.current();
        _engagementSet.add(engagementId);

        // Set multi-swap engagement property
        _mip.remainingInputAmount = _mip.remainingInputAmount.sub(inputAmount);

        // Set multi-swap issuance property
        _meps[engagementId].engagementOutputAmount = outputAmount;

        // Set common engagement property
        EngagementProperty.Data storage engagement = _engagements[engagementId];
        engagement.engagementId = engagementId;
        engagement.takerAddress = takerAddress;
        engagement.engagementCreationTimestamp = now;
        engagement.engagementCompleteTimestamp = now;
        engagement.engagementDueTimestamp = now;
        engagement.engagementState = EngagementProperty.EngagementState.Complete;
        emit EngagementCreated(_issuanceProperty.issuanceId, engagementId, takerAddress);
        emit EngagementComplete(_issuanceProperty.issuanceId, engagementId);

        // Set common issuance property
        _issuanceProperty.completionRatio = _mip.inputAmount.sub(_mip.remainingInputAmount).mul(COMPLETION_RATIO_RANGE).div(_mip.inputAmount);
        if (_mip.remainingInputAmount == 0) {
            _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Complete;
            _issuanceProperty.issuanceCompleteTimestamp = now;
            emit IssuanceComplete(_issuanceProperty.issuanceId, _issuanceProperty.completionRatio);
        }

        transfers = new Transfers.Transfer[](2);
        // Output token intra-instrument transfer: Taker -> Maker
        transfers[0] = Transfers.Transfer(Transfers.TransferType.IntraInstrument, takerAddress,
            _issuanceProperty.makerAddress, _mip.outputTokenAddress, outputAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, engagementId, Transfers.TransferType.IntraInstrument, takerAddress,
            _issuanceProperty.makerAddress, _mip.outputTokenAddress, outputAmount, "Output transfer");
        // Inpunt token outbound transfer: Maker -> Taker
        transfers[1] = Transfers.Transfer(Transfers.TransferType.Outbound, _issuanceProperty.makerAddress,
            takerAddress, _mip.inputTokenAddress, inputAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, engagementId, Transfers.TransferType.Outbound, _issuanceProperty.makerAddress,
            takerAddress, _mip.inputTokenAddress, inputAmount, "Input out");

        uint256 currentPayableId = _payableIds.current();
        if (_mip.remainingInputAmount == 0) {
            // If there is no input token left, simply mark payable as paid
            _markPayableAsPaid(currentPayableId);
        } else {
            // Otherwise, create a new payable and reinitiate the current one!
            _payableIds.increment();
            uint256 newPayableId = _payableIds.current();
            _createPayable(newPayableId, engagementId, address(_issuanceEscrow), _issuanceProperty.makerAddress, _mip.inputTokenAddress,
                _mip.remainingInputAmount, _issuanceProperty.issuanceDueTimestamp);
            _reinitiatePayable(currentPayableId, newPayableId);
        }
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
        emit IssuanceComplete(_issuanceProperty.issuanceId, _issuanceProperty.completionRatio);

        transfers = new Transfers.Transfer[](1);
        // Input token outbound transfer: Maker --> Maker
        transfers[0] = Transfers.Transfer(Transfers.TransferType.Outbound, _issuanceProperty.makerAddress, _issuanceProperty.makerAddress,
            _mip.inputTokenAddress, _mip.remainingInputAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, 0, Transfers.TransferType.Outbound,
            _issuanceProperty.makerAddress, _issuanceProperty.makerAddress, _mip.inputTokenAddress, _mip.remainingInputAmount, "Input out");

        // Mark the current payable as paid
        _markPayableAsPaid(_payableIds.current());
    }

    /**
     * @dev Cancels the lending issuance.
     * @param notifierAddress Address of the caller who cancels the issuance.
     */
    function _cancelIssuance(address notifierAddress) private returns (Transfers.Transfer[] memory transfers) {
        // Cancel Issuance must be processed in Engageable state
        require(_issuanceProperty.issuanceState == IssuanceProperty.IssuanceState.Engageable, "MultiSwapIssuance: Cancel issuance not engageable");
        // Only maker can cancel issuance
        require(notifierAddress == _issuanceProperty.makerAddress, "MultiSwapIssuance: Only maker can cancel issuance");
        // Only cancel when there is no engagement
        require(_engagementSet.length() == 0, "MultiSwapIssuance: Already engaged");

        // The issuance is now cancelled
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Cancelled;
        _issuanceProperty.issuanceCancelTimestamp = now;
        emit IssuanceCancelled(_issuanceProperty.issuanceId);

        transfers = new Transfers.Transfer[](1);
        // Input token outbound transfer: Maker --> Maker
        transfers[0] = Transfers.Transfer(Transfers.TransferType.Outbound, _issuanceProperty.makerAddress, _issuanceProperty.makerAddress,
            _mip.inputTokenAddress, _mip.remainingInputAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, 0, Transfers.TransferType.Outbound,
            _issuanceProperty.makerAddress, _issuanceProperty.makerAddress, _mip.inputTokenAddress, _mip.remainingInputAmount, "Input out");

        // Mark the current payable as paid
        _markPayableAsPaid(_payableIds.current());
    }

    /**
     * @dev Returns the issuance-specific data about the issuance.
     */
    function _getIssuanceCustomProperty() internal override view returns (bytes memory) {
        return MultiSwapIssuanceProperty.encode(_mip);
    }

    /**
     * @dev Returns the issuance-specific data about the engagement.
     */
    function _getEngagementCustomProperty(uint256 engagementId) internal override view returns (bytes memory) {
        return MultiSwapEngagementProperty.encode(_meps[engagementId]);
    }
}
