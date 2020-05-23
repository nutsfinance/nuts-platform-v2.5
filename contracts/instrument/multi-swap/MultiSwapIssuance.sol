// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../lib/protobuf/Transfers.sol";
import "../../lib/protobuf/IssuanceData.sol";
import "../../lib/protobuf/MultiSwapData.sol";
import "../../escrow/InstrumentEscrowInterface.sol";
import "../IssuanceBase.sol";
import "./MultiSwapInstrument.sol";

/**
 * @title A base contract that provide admin access control.
 */
contract MultiSwapIssuance is IssuanceBase {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // Constants
    uint256 internal constant DURATION_MIN = 1; // Minimum duration is 1 day
    uint256 internal constant DURATION_MAX = 90; // Maximum duration is 90 days

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
     * @return transfersData Transfer actions for the issuance.
     */
    function initialize(address instrumentManagerAddress, address instrumentAddress, uint256 issuanceId,
        address issuanceEscrowAddress, address makerAddress, bytes memory makerData)
        public override returns (bytes memory transfersData) {

        require(MultiSwapInstrument(instrumentAddress).isMakerAllowed(makerAddress), "SwapIssuance: Maker not allowed.");
        IssuanceBase._initialize(instrumentManagerAddress, instrumentAddress, issuanceId, issuanceEscrowAddress, makerAddress);

        (_mip.inputTokenAddress, _mip.outputTokenAddress, _mip.inputAmount, _mip.outputAmount, _mip.duration) = abi
            .decode(makerData, (address, address, uint256, uint256, uint256));

        // Validates parameters.
        require(_mip.inputTokenAddress != address(0x0), "Input token not set");
        require(_mip.outputTokenAddress != address(0x0), "Output token not set");
        require(_mip.inputAmount > 0, "Input amount not set");
        require(_mip.outputAmount > 0, "Output amount not set");
        require(_mip.duration >= DURATION_MIN && _mip.duration <= DURATION_MAX, "Invalid duration");

        // Validate input token balance
        uint256 inputTokenBalance = _instrumentManager.getInstrumentEscrow().getTokenBalance(makerAddress, _mip.inputTokenAddress);
        require(inputTokenBalance >= _mip.inputAmount, "Insufficient input balance");

        // Sets common properties
        _issuanceProperty.issuanceDueTimestamp = now.add(_mip.duration);
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Engageable;
        emit IssuanceCreated(_issuanceProperty.issuanceId, makerAddress, _issuanceProperty.issuanceDueTimestamp);

        // Sets multi-swap issuance property
        _mip.remainingInputAmount = _mip.inputAmount;

        // Scheduling Issuance Due event
        emit EventTimeScheduled(_issuanceProperty.issuanceId, 0, _issuanceProperty.issuanceDueTimestamp, ISSUANCE_DUE_EVENT, "");

        // Transfers principal token
        // Input token inbound transfer: Maker --> Maker
        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](1));
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Inbound, makerAddress, makerAddress,
            _mip.inputTokenAddress, _mip.inputAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, 0, Transfer.TransferType.Inbound, makerAddress, makerAddress,
            _mip.inputTokenAddress, _mip.inputAmount, "Input in");
        transfersData = Transfers.encode(transfers);

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
     * @return transfersData Asset transfer actions.
     */
    function engage(address takerAddress, bytes memory takerData)
        public override onlyAdmin returns (uint256 engagementId, bytes memory transfersData) {
        require(MultiSwapInstrument(_instrumentAddress).isTakerAllowed(takerAddress), "SwapIssuance: Taker not allowed.");
        require(now <= _issuanceProperty.issuanceDueTimestamp, "Issuance due");
        require(_issuanceProperty.issuanceState == IssuanceProperty.IssuanceState.Engageable, "Issuance not Engageable");

        uint256 outputAmount = abi.decode(takerData, (uint256));
        uint256 inputAmount = outputAmount.mul(_mip.inputAmount).div(_mip.outputAmount);
        require(_mip.remainingInputAmount >= inputAmount, "Input exceeded");

        // Validates output balance
        uint256 outputTokenBalance = _instrumentManager.getInstrumentEscrow().getTokenBalance(takerAddress, _mip.outputTokenAddress);
        require(outputTokenBalance >= _mip.outputAmount, "Insufficient output balance");

        _engagementIds.increment();
        engagementId = _engagementIds.current();

        // Set multi-swap engagement property
        _mip.remainingInputAmount = _mip.remainingInputAmount.sub(inputAmount);

        // Set multi-swap issuance property
        _meps[engagementId].outputAmount = outputAmount;

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
            emit IssuanceComplete(_issuanceProperty.issuanceId);
        }

        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](2));
        // Output token intra-instrument transfer: Taker -> Maker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.IntraInstrument, takerAddress,
            _issuanceProperty.makerAddress, _mip.outputTokenAddress, outputAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, engagementId, Transfer.TransferType.Inbound, takerAddress,
            _issuanceProperty.makerAddress, _mip.outputTokenAddress, outputAmount, "Output transfer");
        // Inpunt token outbound transfer: Maker -> Taker
        transfers.actions[1] = Transfer.Data(Transfer.TransferType.Outbound, _issuanceProperty.makerAddress,
            takerAddress, _mip.inputTokenAddress, inputAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, engagementId, Transfer.TransferType.Inbound, _issuanceProperty.makerAddress,
            takerAddress, _mip.inputTokenAddress, inputAmount, "Output out");
        transfersData = Transfers.encode(transfers);

        uint256 currentPayableId = _payableIds.current();
        if (_mip.remainingInputAmount == 0) {
            // If there is no input token left, simply mark payable as paid
            _markPayableAsPaid(currentPayableId);
        } else {
            // Otherwise, create a new payable and reinitiate the current one!
            _payableIds.increment();
            uint256 newPayableId = _payableIds.current();
            _reinitiatePayable(currentPayableId, newPayableId);
        }
    }

    /**
     * @dev Process a custom event. This event could be targeted at an engagement or the whole issuance.
     * Only admin(Instrument Manager) can call this method.
     * @param notifierAddress Address that notifies the custom event.
     * @param eventName Name of the custom event.
     * @return transfersData Asset transfer actions.
     */
    function processEvent(uint256 /** engagementId */, address notifierAddress, bytes32 eventName, bytes memory /** eventData */)
        public override onlyAdmin returns (bytes memory transfersData) {
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
    function _processIssuanceDue() private returns (bytes memory transfersData) {
        // Engagement Due will be processed only when:
        // 1. Issuance is in Engageable state, which means there is no Engagement. Otherwise the issuance is in Complete state.
        // 2. Issuance due timestamp is passed
        if (_issuanceProperty.issuanceState != IssuanceProperty.IssuanceState.Engageable
            || now < _issuanceProperty.issuanceDueTimestamp) return new bytes(0);

        // The issuance is now complete
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Complete;
        _issuanceProperty.issuanceCompleteTimestamp = now;
        emit IssuanceComplete(_issuanceProperty.issuanceId);


        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](1));
        // Input token outbound transfer: Maker --> Maker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Outbound, _issuanceProperty.makerAddress, _issuanceProperty.makerAddress,
            _mip.inputTokenAddress, _mip.remainingInputAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, 0, Transfer.TransferType.Outbound,
            _issuanceProperty.makerAddress, _issuanceProperty.makerAddress, _mip.inputTokenAddress, _mip.remainingInputAmount, "Input out");
        transfersData = Transfers.encode(transfers);

        // Mark the current payable as paid
        _markPayableAsPaid(_payableIds.current());
    }

    /**
     * @dev Cancels the lending issuance.
     * @param notifierAddress Address of the caller who cancels the issuance.
     */
    function _cancelIssuance(address notifierAddress) private returns (bytes memory transfersData) {
        // Cancel Issuance must be processed in Engageable state
        require(_issuanceProperty.issuanceState == IssuanceProperty.IssuanceState.Engageable, "Cancel issuance not engageable");
        // Only maker can cancel issuance
        require(notifierAddress == _issuanceProperty.makerAddress, "Only maker can cancel issuance");
        // Only cancel when there is no engagement
        require(_engagementSet.length() == 0, "Already engaged");

        // The issuance is now cancelled
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Cancelled;
        _issuanceProperty.issuanceCancelTimestamp = now;
        emit IssuanceCancelled(_issuanceProperty.issuanceId);

        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](1));
        // Input token outbound transfer: Maker --> Maker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Outbound, _issuanceProperty.makerAddress, _issuanceProperty.makerAddress,
            _mip.inputTokenAddress, _mip.remainingInputAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, 0, Transfer.TransferType.Outbound,
            _issuanceProperty.makerAddress, _issuanceProperty.makerAddress, _mip.inputTokenAddress, _mip.remainingInputAmount, "Input out");
        transfersData = Transfers.encode(transfers);

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
    function _getEngagementCustomProperty(uint256 /** engagementId */) internal override view returns (bytes memory) {
        return new bytes(0);
    }
}