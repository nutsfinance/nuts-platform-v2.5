// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../lib/protobuf/Transfers.sol";
import "../../lib/protobuf/IssuanceData.sol";
import "../../lib/protobuf/LendingData.sol";
import "../../lib/priceoracle/PriceOracleInterface.sol";
import "../../escrow/InstrumentEscrowInterface.sol";
import "../IssuanceBase.sol";
import "./LendingInstrument.sol";

/**
 * @title A base contract that provide admin access control.
 */
contract LendingIssuance is IssuanceBase {
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
    LendingIssuanceProperty.Data private _lip;

    // Since it's a 1 to 1 lending, we could have at most one engagement
    LendingEngagementProperty.Data private _lep;

    // Lending custom events
    bytes32 internal constant REPAY_FULL_EVENT = "repay_full";

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

        require(LendingInstrument(instrumentAddress).isMakerAllowed(makerAddress), "LendingIssuance: Maker not allowed.");
        IssuanceBase._initialize(instrumentManagerAddress, instrumentAddress, issuanceId, issuanceEscrowAddress, makerAddress);

        (_lip.lendingTokenAddress, _lip.collateralTokenAddress, _lip.lendingAmount,
            _lip.tenorDays, _lip.collateralRatio, _lip.interestRate) = abi
            .decode(makerData, (address, address, uint256, uint256, uint256, uint256));

        // Validates parameters
        require(_lip.collateralTokenAddress != address(0x0), "LendingIssuance: Collateral token not set.");
        require(_lip.lendingTokenAddress != address(0x0), "LendingIssuance: Lending token not set.");
        require(_lip.lendingAmount > 0, "Lending amount not set");
        require(_lip.tenorDays >= TENOR_DAYS_MIN && _lip.tenorDays <= TENOR_DAYS_MAX,
            "LendingIssuance: Invalid tenor days.");
        require(_lip.collateralRatio >= COLLATERAL_RATIO_MIN &&
            _lip.collateralRatio <= COLLATERAL_RATIO_MAX,
            "LendingIssuance: Invalid collateral ratio.");
        require(_lip.interestRate >= INTEREST_RATE_MIN && _lip.interestRate <= INTEREST_RATE_MAX,
            "LendingIssuance: Invalid interest rate.");

        // Validate principal token balance
        uint256 principalBalance = _instrumentManager.getInstrumentEscrow().getTokenBalance(_issuanceProperty.makerAddress, _lip.lendingTokenAddress);
        require(principalBalance >= _lip.lendingAmount, "LendingIssuance: Insufficient principal balance.");

        // Sets common properties
        _issuanceProperty.issuanceDueTimestamp = now.add(ENGAGEMENT_DUE_DAYS);

        // Scheduling Issuance Due event
        emit EventTimeScheduled(_issuanceProperty.issuanceId, 0, _issuanceProperty.issuanceDueTimestamp, ISSUANCE_DUE_EVENT, "");

        // Emits Issuance Created event
        emit IssuanceCreated(_issuanceProperty.issuanceId, _issuanceProperty.makerAddress, _issuanceProperty.issuanceDueTimestamp);

        // Sets lending properties
        _lip.interestAmount = _lip.lendingAmount.mul(_lip.tenorDays).mul(_lip.interestRate).div(INTEREST_RATE_DECIMALS);

        // Updates to Engageable state
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Engageable;

        // Transfers principal token
        // Principal token inbound transfer: Maker --> Maker
        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](1));
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Inbound, _issuanceProperty.makerAddress,
            _issuanceProperty.makerAddress, _lip.lendingTokenAddress, _lip.lendingAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Inbound, _issuanceProperty.makerAddress,
            _issuanceProperty.makerAddress, _lip.lendingTokenAddress, _lip.lendingAmount, "Principal in");
        transfersData = Transfers.encode(transfers);

        // Create payable 1: Custodian --> Maker
        _createPayable(1, ENGAGEMENT_ID, address(_issuanceEscrow), _issuanceProperty.makerAddress, _lip.lendingTokenAddress,
            _lip.lendingAmount, _issuanceProperty.issuanceDueTimestamp);
    }

    /**
     * @dev Creates a new engagement for the issuance. Only admin(Instrument Manager) can call this method.
     * @param takerAddress Address of the user who engages the issuance.
     * @return engagementId ID of the engagement.
     * @return transfersData Asset transfer actions.
     */
    function engage(address takerAddress, bytes memory /** takerData */)
        public override onlyAdmin returns (uint256 engagementId, bytes memory transfersData) {
        require(LendingInstrument(_instrumentAddress).isTakerAllowed(takerAddress), "LendingIssuance: Taker not allowed.");
        require(_issuanceProperty.issuanceState == IssuanceProperty.IssuanceState.Engageable, "Issuance not Engageable");
        require(_engagementSet.length() == 0, "Already engaged");

        // Calculate the collateral amount. Collateral is calculated at the time of engagement.
        PriceOracleInterface priceOracle = LendingInstrument(_instrumentAddress).getPriceOracle();
        _lep.collateralAmount = priceOracle.getOutputAmount(_lip.lendingTokenAddress,
            _lip.collateralTokenAddress, _lip.lendingAmount.mul(_lip.collateralRatio),
            COLLATERAL_RATIO_DECIMALS);

        // Validates collateral balance
        // uint256 collateralBalance = instrument.getInstrumentEscrow().getTokenBalance(takerAddress, _lip.collateralTokenAddress);
        // require(collateralBalance >= _lep.collateralAmount, "Insufficient collateral balance");

        // Set common engagement property
        EngagementProperty.Data storage engagement = _engagements[ENGAGEMENT_ID];
        engagement.engagementId = ENGAGEMENT_ID;
        engagement.takerAddress = takerAddress;
        engagement.engagementCreationTimestamp = now;
        engagement.engagementDueTimestamp = now.add(_lip.tenorDays * 1 days);
        engagement.engagementState = EngagementProperty.EngagementState.Active;

        // Set common issuance property
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Complete;
        _issuanceProperty.completionRatio = 10000;
        emit IssuanceComplete(_issuanceProperty.issuanceId);

        // Sets lending-specific engagement property
        _lep.loanState = LendingEngagementProperty.LoanState.Unpaid;

        _engagementSet.add(ENGAGEMENT_ID);

        // Scheduling Lending Engagement Due event
        emit EventTimeScheduled(_issuanceProperty.issuanceId, ENGAGEMENT_ID, engagement.engagementDueTimestamp,
            ENGAGEMENT_DUE_EVENT, "");

        // Emits Engagement Created event
        emit EngagementCreated(_issuanceProperty.issuanceId, ENGAGEMENT_ID, takerAddress);

        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](2));
        // Collateral token inbound transfer: Taker -> Taker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Inbound, takerAddress, takerAddress,
            _lip.collateralTokenAddress, _lep.collateralAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Inbound, takerAddress, takerAddress,
            _lip.collateralTokenAddress, _lep.collateralAmount, "Collateral in");

        // Create payable 2: Custodian --> Taker
        _createPayable(2, ENGAGEMENT_ID, address(_issuanceEscrow), takerAddress, _lip.collateralTokenAddress,
            _lep.collateralAmount, engagement.engagementDueTimestamp);

        // Principal token outbound transfer: Maker --> Taker
        transfers.actions[1] = Transfer.Data(Transfer.TransferType.Outbound, _issuanceProperty.makerAddress, takerAddress,
            _lip.lendingTokenAddress, _lip.lendingAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Outbound,
            _issuanceProperty.makerAddress, takerAddress, _lip.lendingTokenAddress, _lip.lendingAmount, "Principal out");

        // Create payable 3: Taker --> Maker
        _createPayable(3, ENGAGEMENT_ID, takerAddress, _issuanceProperty.makerAddress, _lip.lendingTokenAddress,
            _lip.lendingAmount, engagement.engagementDueTimestamp);

        // Create payable 4: Taker --> Maker
        _createPayable(4, ENGAGEMENT_ID, takerAddress, _issuanceProperty.makerAddress, _lip.lendingTokenAddress,
            _lip.interestAmount, engagement.engagementDueTimestamp);

        // Mark payable 1 as reinitiated by payable 3
        _reinitiatePayable(1, 3);

        engagementId = ENGAGEMENT_ID;
        transfersData = Transfers.encode(transfers);
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
        } else if (eventName == ENGAGEMENT_DUE_EVENT) {
            return _processEngagementDue();
        } else if (eventName == CANCEL_ISSUANCE_EVENT) {
            return _cancelIssuance(notifierAddress);
        } else if (eventName == REPAY_FULL_EVENT) {
            return _repayLendingEngagement(notifierAddress);
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
        // Principal token outbound transfer: Maler --> Maker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Outbound, _issuanceProperty.makerAddress, _issuanceProperty.makerAddress,
            _lip.lendingTokenAddress, _lip.lendingAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Outbound,
            _issuanceProperty.makerAddress, _issuanceProperty.makerAddress, _lip.lendingTokenAddress, _lip.lendingAmount, "Principal out");

        // Mark payable 1 as paid
        _markPayableAsPaid(1);

        transfersData = Transfers.encode(transfers);
    }

    /**
     * @dev Processes the Engagement Due event.
     */
    function _processEngagementDue() private returns (bytes memory transfersData) {
        // Lending Engagement Due will be processed only when:
        // 1. Lending Issuance is in Complete state
        // 2. Lending Engagement is in Active State
        // 3. Lending Engegement loan is in Unpaid State
        // 2. Lending engegement due timestamp has passed
        if (_issuanceProperty.issuanceState != IssuanceProperty.IssuanceState.Complete)  return new bytes(0);
        EngagementProperty.Data storage engagement = _engagements[ENGAGEMENT_ID];
        if (engagement.engagementState != EngagementProperty.EngagementState.Active ||
            _lep.loanState == LendingEngagementProperty.LoanState.Unpaid ||
            now < engagement.engagementDueTimestamp) return new bytes(0);

        // The engagement is now complete
        engagement.engagementState = EngagementProperty.EngagementState.Complete;
        engagement.engagementCompleteTimestamp = now;
        _lep.loanState = LendingEngagementProperty.LoanState.Delinquent;
        emit EngagementComplete(_issuanceProperty.issuanceId, ENGAGEMENT_ID);

        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](1));
        // Collateral token outbound transfer: Taker --> Maker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Outbound, engagement.takerAddress, _issuanceProperty.makerAddress,
            _lip.collateralTokenAddress, _lep.collateralAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Outbound,
            engagement.takerAddress, _issuanceProperty.makerAddress, _lip.collateralTokenAddress, _lep.collateralAmount, "Collateral out");

        // Mark payable 2 as paid
        _markPayableAsPaid(2);
        transfersData = Transfers.encode(transfers);
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

        // The issuance is now cancelled
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Cancelled;
        _issuanceProperty.issuanceCancelTimestamp = now;
        emit IssuanceCancelled(_issuanceProperty.issuanceId);

        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](1));
        // Principal token outbound transfer: Makr --> Maker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Outbound, _issuanceProperty.makerAddress, _issuanceProperty.makerAddress,
            _lip.lendingTokenAddress, _lip.lendingAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Outbound,
            _issuanceProperty.makerAddress, _issuanceProperty.makerAddress, _lip.lendingTokenAddress, _lip.lendingAmount, "Principal out");

        // Mark payable 1 as paid
        _markPayableAsPaid(1);

        transfersData = Transfers.encode(transfers);
    }

    /**
     * @dev Repays the issuance in full.
     * @param notifierAddress Address of the caller who repays the issuance.
     */
    function _repayLendingEngagement(address notifierAddress) private returns (bytes memory transfersData) {
        // Lending Engagement Due will be processed only when:
        // 1. Lending Issuance is in Complete state
        // 2. Lending Engagement is in Active State
        // 3. Lending Engegement loan is in Unpaid State
        // 4. Lending engegement due timestamp is not passed
        EngagementProperty.Data storage engagement = _engagements[ENGAGEMENT_ID];
        require(_issuanceProperty.issuanceState == IssuanceProperty.IssuanceState.Complete, "Issuance not complete");
        require(engagement.engagementState == EngagementProperty.EngagementState.Active, "Engagement not active");
        require(_lep.loanState == LendingEngagementProperty.LoanState.Unpaid, "Loan not unpaid");
        require(now < engagement.engagementDueTimestamp, "Engagement due");
        require(notifierAddress == engagement.takerAddress, "Only taker can repay");

        uint256 repayAmount = _lip.lendingAmount + _lip.interestAmount;
        // Validate principal token balance
        uint256 principalTokenBalance = _instrumentManager.getInstrumentEscrow()
            .getTokenBalance(engagement.takerAddress, _lip.lendingTokenAddress);
        require(principalTokenBalance >= repayAmount, "Insufficient principal balance");

        // Sets Engagement common properties
        engagement.engagementState = EngagementProperty.EngagementState.Complete;
        engagement.engagementCompleteTimestamp = now;
        emit EngagementComplete(_issuanceProperty.issuanceId, ENGAGEMENT_ID);

        // Emits Lending-specific Engagement property
        _lep.loanState = LendingEngagementProperty.LoanState.Repaid;

        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](2));
        // Pricipal + Interest intra-instrument transfer: Taker -> Maker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.IntraInstrument, engagement.takerAddress, _issuanceProperty.makerAddress,
            _lip.lendingTokenAddress, repayAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.IntraInstrument,
            engagement.takerAddress, _issuanceProperty.makerAddress, _lip.lendingTokenAddress, _lip.lendingAmount, "Principal transfer");
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.IntraInstrument,
            engagement.takerAddress, _issuanceProperty.makerAddress, _lip.lendingTokenAddress, _lip.interestAmount, "Interest transfer");
        // Collateral outbound transfer: Taker --> Taker
        transfers.actions[1] = Transfer.Data(Transfer.TransferType.Outbound, engagement.takerAddress, engagement.takerAddress,
            _lip.collateralTokenAddress, _lep.collateralAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Outbound,
            engagement.takerAddress, engagement.takerAddress, _lip.collateralTokenAddress, _lep.collateralAmount, "Collateral out");
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
        return LendingIssuanceProperty.encode(_lip);
    }

    /**
     * @dev Returns the issuance-specific data about the engagement.
     */
    function _getEngagementCustomProperty(uint256 /** engagementId */) internal override view returns (bytes memory) {
        return LendingEngagementProperty.encode(_lep);
    }
}