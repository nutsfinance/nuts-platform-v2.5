// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "../../lib/protobuf/Transfers.sol";
import "../../lib/protobuf/IssuanceData.sol";
import "../../lib/protobuf/LendingData.sol";
import "../../lib/priceoracle/IPriceOracle.sol";
import "../../escrow/IInstrumentEscrow.sol";
import "../Issuance.sol";
import "./LendingInstrument.sol";

/**
 * @title A base contract that provide admin access control.
 */
contract LendingIssuance is Issuance {
    using SafeMath for uint256;

    // Constants
    uint256 internal constant ENGAGEMENT_ID = 1;
    uint256 internal constant ENGAGEMENT_DUE_DAYS = 14 days; // Time available for taker to engage
    uint256 internal constant TENOR_DAYS_MIN = 2; // Minimum tenor is 2 days
    uint256 internal constant TENOR_DAYS_MAX = 90; // Maximum tenor is 90 days
    uint256 internal constant COLLATERAL_RATIO_DECIMALS = 10**4; // 0.01%
    uint256 internal constant COLLATERAL_RATIO_MIN = 5000; // Minimum collateral is 50%
    uint256 internal constant COLLATERAL_RATIO_MAX = 20000; // Maximum collateral is 200%
    uint256 internal constant INTEREST_RATE_DECIMALS = 10**6; // 0.0001%
    uint256 internal constant INTEREST_RATE_MIN = 10; // Mimimum interest rate is 0.0010%
    uint256 internal constant INTEREST_RATE_MAX = 50000; // Maximum interest rate is 5.0000%

    // Lending issuance properties
    address private _lendingToken;
    address private _collateralToken;
    uint256 private _lendingAmount;
    uint256 private _tenorDays;
    uint256 private _collateralRatio;
    uint256 private _interestRate;
    uint256 private _interestAmount;

    // Lending engagement properties
    uint256 private _collateralAmount;
    LendingEngagementProperty.LoanState private _loanState = LendingEngagementProperty.LoanState.LoanStateUnknown;

    // Lending custom events
    bytes32 internal constant REPAY_FULL_EVENT = "repay_full";

    /**
     * @param instrumentAddress Address of the instrument contract.
     * @param issuanceId ID of the issuance.
     * @param issuanceEscrowAddress Address of the issuance escrow.
     * @param makerAddress Address of the user who creates the issuance.
     * @param makerData Custom properties of the issuance.
     */
    constructor(address instrumentAddress, uint256 issuanceId, address issuanceEscrowAddress, address makerAddress, bytes memory makerData)
        Issuance(instrumentAddress, issuanceId, issuanceEscrowAddress, makerAddress) public {
        (_lendingToken, _collateralToken, _lendingAmount, _tenorDays, _collateralRatio, _interestRate) = abi.decode(makerData,
            (address, address, uint256, uint256, uint256, uint256));
        require(_state == IssuanceProperty.IssuanceState.Initiated, "LendingIssuance: Not in Initiated.");
        // Validates parameters.
        require(_collateralToken != address(0x0), "LendingIssuance: Collateral token not set.");
        require(_lendingToken != address(0x0), "LendingIssuance: Lending token not set.");
        require(_lendingAmount > 0, "Lending amount not set");
        require(_tenorDays >= TENOR_DAYS_MIN && _tenorDays <= TENOR_DAYS_MAX, "LendingIssuance: Invalid tenor days.");
        require(_collateralRatio >= COLLATERAL_RATIO_MIN && _collateralRatio <= COLLATERAL_RATIO_MAX,
            "LendingIssuance: Invalid collateral ratio.");
        require(_interestRate >= INTEREST_RATE_MIN && _interestRate <= INTEREST_RATE_MAX,
            "LendingIssuance: Invalid interest rate.");

        // Validate principal token balance
        // IInstrumentEscrow instrumentEscrow = LendingInstrument(_instrumentAddress).getInstrumentEscrow();
        // uint256 principalBalance = instrumentEscrow.getTokenBalance(_makerAddress, _lendingToken);
        // require(principalBalance >= _lendingAmount, "LendingIssuance: Insufficient principal balance.");

        // Sets common properties
        _dueTimestamp = now.add(ENGAGEMENT_DUE_DAYS);

        // Scheduling Issuance Due event
        emit EventTimeScheduled(_issuanceId, 0, _dueTimestamp, ISSUANCE_DUE_EVENT, "");

        // Emits Issuance Created event
        emit IssuanceCreated(_issuanceId, _makerAddress, _dueTimestamp);

        // Sets lending properties
        _interestAmount = _lendingAmount.mul(_tenorDays).mul(_interestRate).div(INTEREST_RATE_DECIMALS);
    }

    /**
     * @dev Initializes the issuance.
     * @return transfersData Asset transfer actions.
     */
    function initialize() public override returns (bytes memory transfersData) {
        require(_state == IssuanceProperty.IssuanceState.Initiated, "LendingIssuance: Not in Initiated.");

        // Updates to Engageable state
        _state = IssuanceProperty.IssuanceState.Engageable;

        // Transfers principal token
        // Principal token inbound transfer: Maker --> Maker
        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](1));
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Inbound, _makerAddress, _makerAddress,
            _lendingToken, _lendingAmount);
        emit AssetTransferred(_issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Inbound, _makerAddress, _makerAddress,
            _lendingToken, _lendingAmount, "Principal in");
        transfersData = Transfers.encode(transfers);

        // Create payable 1: Custodian --> Maker
        _createPayable(1, ENGAGEMENT_ID, address(_issuanceEscrow), _makerAddress, _lendingToken, _lendingAmount, _dueTimestamp);
    }

    /**
     * @dev Creates a new engagement for the issuance.
     * @param takerAddress Address of the user who engages the issuance.
     * @return engagementId ID of the engagement.
     * @return transfersData Asset transfer actions.
     */
    function engage(address takerAddress, bytes memory /** takerData */)
        public override returns (uint256 engagementId, bytes memory transfersData) {

        require(_state == IssuanceProperty.IssuanceState.Engageable, "Issuance not Engageable");
        require(_loanState == LendingEngagementProperty.LoanState.LoanStateUnknown, "Already engaged");

        // Calculate the collateral amount. Collateral is calculated at the time of engagement.
        IPriceOracle priceOracle = IPriceOracle(LendingInstrument(_instrumentAddress).getPriceOracle());
        _collateralAmount = priceOracle.getOutputAmount(_lendingToken, _collateralToken,
            _lendingAmount.mul(_collateralRatio), COLLATERAL_RATIO_DECIMALS);

        // Validates collateral balance
        // uint256 collateralBalance = instrument.getInstrumentEscrow().getTokenBalance(takerAddress, _collateralToken);
        // require(collateralBalance >= _collateralAmount, "Insufficient collateral balance");

        // Set common engagement property
        uint256 engagementDueTimestamp = now.add(_tenorDays * 1 days);
        _engagementSet.add(ENGAGEMENT_ID);
        EngagementProperty.Data memory engagement = EngagementProperty.Data({
            engagementId: ENGAGEMENT_ID,
            takerAddress: takerAddress,
            engagementCreationTimestamp: now,
            engagementDueTimestamp: engagementDueTimestamp,
            engagementCancelTimestamp: 0,
            engagementCompleteTimestamp: 0,
            engagementState: EngagementProperty.EngagementState.Active,
            engagementCustomProperty: new bytes(0)
        });
        _engagements[ENGAGEMENT_ID] = engagement;
        // As lending instrument is 1 to 1, the issuance state is complete one we have one engagement!
        _state = IssuanceProperty.IssuanceState.Complete;
        _completionRatio = 10000;
        emit IssuanceComplete(_issuanceId);

        // Sets lending-specific engagement property
        _loanState = LendingEngagementProperty.LoanState.Unpaid;

        // Scheduling Lending Engagement Due event
        emit EventTimeScheduled(_issuanceId, ENGAGEMENT_ID, engagementDueTimestamp, ENGAGEMENT_DUE_EVENT, "");

        // Emits Engagement Created event
        emit EngagementCreated(_issuanceId, ENGAGEMENT_ID, takerAddress);

        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](2));
        // Collateral token inbound transfer: Taker -> Taker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Inbound, takerAddress, takerAddress,
            _collateralToken, _collateralAmount);
        emit AssetTransferred(_issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Inbound, takerAddress, takerAddress,
            _collateralToken, _collateralAmount, "Collateral in");

        // Create payable 2: Custodian --> Taker
        _createPayable(2, ENGAGEMENT_ID, address(_issuanceEscrow), takerAddress, _collateralToken,
            _collateralAmount, engagementDueTimestamp);

        // Principal token outbound transfer: Maker --> Taker
        transfers.actions[1] = Transfer.Data(Transfer.TransferType.Outbound, _makerAddress, takerAddress,
            _lendingToken, _lendingAmount);
        emit AssetTransferred(_issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Outbound, _makerAddress, takerAddress,
            _lendingToken, _lendingAmount, "Principal out");

        // Create payable 3: Taker --> Maker
        _createPayable(3, ENGAGEMENT_ID, takerAddress, _makerAddress, _lendingToken, _lendingAmount, engagementDueTimestamp);

        // Create payable 4: Taker --> Maker
        _createPayable(4, ENGAGEMENT_ID, takerAddress, _makerAddress, _lendingToken, _interestAmount, engagementDueTimestamp);

        // Mark payable 1 as reinitiated by payable 3
        _reinitiatePayable(1, 3);

        engagementId = ENGAGEMENT_ID;
        transfersData = Transfers.encode(transfers);
    }

    /**
     * @dev Process a custom event. This event could be targeted at an engagement or the whole issuance.
     * @param notifierAddress Address that notifies the custom event.
     * @param eventName Name of the custom event.
     * @return transfersData Asset transfer actions.
     */
    function processEvent(uint256 /** engagementId */, address notifierAddress, bytes32 eventName, bytes memory /** eventData */)
        public override returns (bytes memory transfersData) {
         if (eventName == ISSUANCE_DUE_EVENT) {
            return processIssuanceDue();
        } else if (eventName == ENGAGEMENT_DUE_EVENT) {
            return processEngagementDue();
        } else if (eventName == CANCEL_ISSUANCE_EVENT) {
            return cancelIssuance(notifierAddress);
        } else if (eventName == REPAY_FULL_EVENT) {
            return repayLendingEngagement(notifierAddress);
        } else {
            revert("Unknown event");
        }
    }

    /**
     * @dev Processes the Issuance Due event.
     */
    function processIssuanceDue() private returns (bytes memory transfersData) {
        // Engagement Due will be processed only when:
        // 1. Issuance is in Engageable state, which means there is no Engagement. Otherwise the issuance is in Complete state.
        // 2. Issuance due timestamp is passed
        if (_state != IssuanceProperty.IssuanceState.Engageable || now < _dueTimestamp) return new bytes(0);

        // The issuance is now complete
        _state = IssuanceProperty.IssuanceState.Complete;
        _completeTimestamp = now;
        emit IssuanceComplete(_issuanceId);

        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](1));
        // Principal token outbound transfer: Maler --> Maker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Outbound, _makerAddress, _makerAddress,
            _lendingToken, _lendingAmount);
        emit AssetTransferred(_issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Outbound, _makerAddress, _makerAddress,
            _lendingToken, _lendingAmount, "Principal out");

        // Mark payable 1 as paid
        _markPayableAsPaid(1);

        transfersData = Transfers.encode(transfers);
    }

    /**
     * @dev Processes the Engagement Due event.
     */
    function processEngagementDue() private returns (bytes memory transfersData) {
        // Lending Engagement Due will be processed only when:
        // 1. Lending Issuance is in Complete state
        // 2. Lending Engagement is in Active State
        // 3. Lending Engegement loan is in Unpaid State
        // 2. Lending engegement due timestamp has passed
        if (_state != IssuanceProperty.IssuanceState.Complete)  return new bytes(0);
        EngagementProperty.Data storage engagement = _engagements[ENGAGEMENT_ID];
        if (engagement.engagementState != EngagementProperty.EngagementState.Active ||
            _loanState == LendingEngagementProperty.LoanState.Unpaid ||
            now < engagement.engagementDueTimestamp) return new bytes(0);

        // The engagement is now complete
        engagement.engagementState = EngagementProperty.EngagementState.Complete;
        engagement.engagementCompleteTimestamp = now;
        _loanState = LendingEngagementProperty.LoanState.Delinquent;
        emit EngagementComplete(_issuanceId, ENGAGEMENT_ID);

        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](1));
        // Collateral token outbound transfer: Taker --> Maker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Outbound, engagement.takerAddress, _makerAddress,
            _collateralToken, _collateralAmount);
        emit AssetTransferred(_issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Outbound, engagement.takerAddress, _makerAddress,
            _collateralToken, _collateralAmount, "Collateral out");

        // Mark payable 2 as paid
        _markPayableAsPaid(2);
        transfersData = Transfers.encode(transfers);
    }

    /**
     * @dev Cancels the lending issuance.
     * @param notifierAddress Address of the caller who cancels the issuance.
     */
    function cancelIssuance(address notifierAddress) private returns (bytes memory transfersData) {
        // Cancel Issuance must be processed in Engageable state
        require(_state == IssuanceProperty.IssuanceState.Engageable, "Cancel issuance not engageable");
        // Only maker can cancel issuance
        require(notifierAddress == _makerAddress, "Only maker can cancel issuance");

        // The issuance is now cancelled
        _state = IssuanceProperty.IssuanceState.Cancelled;
        _cancelTimestamp = now;
        emit IssuanceCancelled(_issuanceId);

        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](1));
        // Principal token outbound transfer: Makr --> Maker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Outbound, _makerAddress, _makerAddress,
            _lendingToken, _lendingAmount);
        emit AssetTransferred(_issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Outbound, _makerAddress, _makerAddress,
            _lendingToken, _lendingAmount, "Principal out");

        // Mark payable 1 as paid
        _markPayableAsPaid(1);

        transfersData = Transfers.encode(transfers);
    }

    /**
     * @dev Repays the issuance in full.
     * @param notifierAddress Address of the caller who repays the issuance.
     */
    function repayLendingEngagement(address notifierAddress) private returns (bytes memory transfersData) {
        // Lending Engagement Due will be processed only when:
        // 1. Lending Issuance is in Complete state
        // 2. Lending Engagement is in Active State
        // 3. Lending Engegement loan is in Unpaid State
        // 4. Lending engegement due timestamp is not passed
        EngagementProperty.Data storage engagement = _engagements[ENGAGEMENT_ID];
        require(_state == IssuanceProperty.IssuanceState.Complete, "Issuance not complete");
        require(engagement.engagementState == EngagementProperty.EngagementState.Active, "Engagement not active");
        require(_loanState == LendingEngagementProperty.LoanState.Unpaid, "Loan not unpaid");
        require(now < engagement.engagementDueTimestamp, "Engagement due");
        require(notifierAddress == engagement.takerAddress, "Only taker can repay");

        uint256 repayAmount = _lendingAmount + _interestAmount;
        // Validate principal token balance
        uint256 principalTokenBalance = LendingInstrument(_instrumentAddress).getInstrumentEscrow()
            .getTokenBalance(engagement.takerAddress, _lendingToken);
        require(principalTokenBalance >= repayAmount, "Insufficient principal balance");

        // Sets Engagement common properties
        engagement.engagementState = EngagementProperty.EngagementState.Complete;
        engagement.engagementCompleteTimestamp = now;
        emit EngagementComplete(_issuanceId, ENGAGEMENT_ID);

        // Emits Lending-specific Engagement property
        _loanState = LendingEngagementProperty.LoanState.Repaid;

        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](2));
        // Pricipal + Interest intra-instrument transfer: Taker -> Maker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.IntraInstrument, engagement.takerAddress, _makerAddress,
            _lendingToken, repayAmount);
        emit AssetTransferred(_issuanceId, ENGAGEMENT_ID, Transfer.TransferType.IntraInstrument, engagement.takerAddress, _makerAddress,
            _lendingToken, _lendingAmount, "Principal transfer");
        emit AssetTransferred(_issuanceId, ENGAGEMENT_ID, Transfer.TransferType.IntraInstrument, engagement.takerAddress, _makerAddress,
            _lendingToken, _interestAmount, "Interest transfer");
        // Collateral outbound transfer: Taker --> Taker
        transfers.actions[1] = Transfer.Data(Transfer.TransferType.Outbound, engagement.takerAddress, engagement.takerAddress,
            _collateralToken, _collateralAmount);
        emit AssetTransferred(_issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Outbound, engagement.takerAddress, engagement.takerAddress,
            _collateralToken, _collateralAmount, "Collateral out");
        transfersData = Transfers.encode(transfers);

        // Mark payable 2 as paid
        _markPayableAsPaid(2);
        // Mark payable 3 as paid
        _markPayableAsPaid(3);
        // Mark payable 4 as paid
        _markPayableAsPaid(4);
    }

    /**
     * @dev Returns the issuance-specific data about the issuance.
     */
    function _getIssuanceCustomProperty() internal override view returns (bytes memory) {
        LendingIssuanceProperty.Data memory issuanceProperty = LendingIssuanceProperty.Data({
            lendingTokenAddress: _lendingToken,
            collateralTokenAddress: _collateralToken,
            lendingAmount: _lendingAmount,
            collateralRatio: _collateralRatio,
            interestRate: _interestRate,
            interestAmount: _interestAmount,
            tenorDays: _tenorDays
        });

        return LendingIssuanceProperty.encode(issuanceProperty);
    }

    /**
     * @dev Returns the issuance-specific data about the engagement.
     */
    function _getEngagementCustomProperty(uint256 /** engagementId */) internal override view returns (bytes memory) {
        LendingEngagementProperty.Data memory engagementProperty = LendingEngagementProperty.Data({
            collateralAmount: _collateralAmount,
            loanState: _loanState
        });

        return LendingEngagementProperty.encode(engagementProperty);
    }
}