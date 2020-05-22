// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../lib/protobuf/Transfers.sol";
import "../../lib/protobuf/IssuanceData.sol";
import "../../lib/protobuf/BorrowingData.sol";
import "../../lib/priceoracle/PriceOracleInterface.sol";
import "../../escrow/InstrumentEscrowInterface.sol";
import "../IssuanceBase.sol";
import "./BorrowingInstrument.sol";

/**
 * @title A base contract that provide admin access control.
 */
contract BorrowingIssuance is IssuanceBase {
    using SafeMath for uint256;

    // Constants
    uint256 internal constant ENGAGEMENT_ID = 1;
    uint256 internal constant ISSUANCE_DUE_DAYS = 14 days; // Time available for taker to engage
    uint256 internal constant TENOR_DAYS_MIN = 2; // Minimum tenor is 2 days
    uint256 internal constant TENOR_DAYS_MAX = 90; // Maximum tenor is 90 days
    uint256 internal constant COLLATERAL_RATIO_DECIMALS = 10**4; // 0.01%
    uint256 internal constant COLLATERAL_RATIO_MIN = 5000; // Minimum collateral is 50%
    uint256 internal constant COLLATERAL_RATIO_MAX = 20000; // Maximum collateral is 200%
    uint256 internal constant INTEREST_RATE_DECIMALS = 10**6; // 0.0001%
    uint256 internal constant INTEREST_RATE_MIN = 10; // Mimimum interest rate is 0.0010%
    uint256 internal constant INTEREST_RATE_MAX = 50000; // Maximum interest rate is 5.0000%

    // Borrowing issuance properties
    BorrowingIssuanceProperty.Data private _bip;

    // Since it's a 1 to 1 borrowing, we could have at most one engagement
    BorrowingEngagementProperty.Data private _bep;

    // Borrowing custom events
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

        require(BorrowingInstrument(instrumentAddress).isMakerAllowed(makerAddress), "BorrowingIssuance: Maker not allowed.");
        IssuanceBase._initialize(instrumentManagerAddress, instrumentAddress, issuanceId, issuanceEscrowAddress, makerAddress);

        (_bip.borrowingTokenAddress, _bip.collateralTokenAddress, _bip.borrowingAmount,
            _bip.tenorDays, _bip.collateralRatio, _bip.interestRate) = abi
            .decode(makerData, (address, address, uint256, uint256, uint256, uint256));

        // Validates parameters
        require(_bip.collateralTokenAddress != address(0x0), "BorrowingIssuance: Collateral token not set.");
        require(_bip.borrowingTokenAddress != address(0x0), "BorrowingIssuance: Borrowing token not set.");
        require(_bip.borrowingAmount > 0, "Borrowing amount not set");
        require(_bip.tenorDays >= TENOR_DAYS_MIN && _bip.tenorDays <= TENOR_DAYS_MAX,
            "BorrowingIssuance: Invalid tenor days.");
        require(_bip.collateralRatio >= COLLATERAL_RATIO_MIN &&
            _bip.collateralRatio <= COLLATERAL_RATIO_MAX,
            "BorrowingIssuance: Invalid collateral ratio.");
        require(_bip.interestRate >= INTEREST_RATE_MIN && _bip.interestRate <= INTEREST_RATE_MAX,
            "BorrowingIssuance: Invalid interest rate.");

        // Calculate the collateral amount. Collateral is calculated at the time of engagement.
        PriceOracleInterface priceOracle = BorrowingInstrument(_instrumentAddress).getPriceOracle();
        _bip.collateralAmount = priceOracle.getOutputAmount(_bip.borrowingTokenAddress,
            _bip.collateralTokenAddress, _bip.borrowingAmount.mul(_bip.collateralRatio),
            COLLATERAL_RATIO_DECIMALS);

        // Validates collateral balance
        uint256 collateralBalance = _instrumentManager.getInstrumentEscrow().getTokenBalance(makerAddress, _bip.collateralTokenAddress);
        require(collateralBalance >= _bip.collateralAmount, "Insufficient collateral balance");

        // Sets common properties
        _issuanceProperty.issuanceDueTimestamp = now.add(ISSUANCE_DUE_DAYS);

        // Scheduling Issuance Due event
        emit EventTimeScheduled(_issuanceProperty.issuanceId, 0, _issuanceProperty.issuanceDueTimestamp, ISSUANCE_DUE_EVENT, "");

        // Emits Issuance Created event
        emit IssuanceCreated(_issuanceProperty.issuanceId, makerAddress, _issuanceProperty.issuanceDueTimestamp);

        // Sets borrowing properties
        _bip.interestAmount = _bip.borrowingAmount.mul(_bip.tenorDays).mul(_bip.interestRate).div(INTEREST_RATE_DECIMALS);

        // Updates to Engageable state
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Engageable;

        // Transfers principal token
        // Principal token inbound transfer: Maker --> Maker
        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](1));
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Inbound, makerAddress,
            makerAddress, _bip.collateralTokenAddress, _bip.collateralAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Inbound, makerAddress,
            makerAddress, _bip.collateralTokenAddress, _bip.collateralAmount, "Collateral in");
        transfersData = Transfers.encode(transfers);

        // Create payable 1: Custodian --> Maker
        _createPayable(1, ENGAGEMENT_ID, address(_issuanceEscrow), makerAddress, _bip.collateralTokenAddress,
            _bip.collateralAmount, _issuanceProperty.issuanceDueTimestamp);
    }

    /**
     * @dev Creates a new engagement for the issuance. Only admin(Instrument Manager) can call this method.
     * @param takerAddress Address of the user who engages the issuance.
     * @return engagementId ID of the engagement.
     * @return transfersData Asset transfer actions.
     */
    function engage(address takerAddress, bytes memory /** takerData */)
        public override onlyAdmin returns (uint256 engagementId, bytes memory transfersData) {
        require(BorrowingInstrument(_instrumentAddress).isTakerAllowed(takerAddress), "BorrowingIssuance: Taker not allowed.");
        require(_issuanceProperty.issuanceState == IssuanceProperty.IssuanceState.Engageable, "Issuance not Engageable");
        require(_engagementSet.length() == 0, "Already engaged");

        // Validates principal balance
        uint256 principalBalance = _instrumentManager.getInstrumentEscrow().getTokenBalance(takerAddress, _bip.borrowingTokenAddress);
        require(principalBalance >= _bip.borrowingAmount, "Insufficient principal balance");

        // Set common engagement property
        EngagementProperty.Data storage engagement = _engagements[ENGAGEMENT_ID];
        engagement.engagementId = ENGAGEMENT_ID;
        engagement.takerAddress = takerAddress;
        engagement.engagementCreationTimestamp = now;
        engagement.engagementDueTimestamp = now.add(_bip.tenorDays * 1 days);
        engagement.engagementState = EngagementProperty.EngagementState.Active;

        // Set common issuance property
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Complete;
        _issuanceProperty.completionRatio = 10000;
        emit IssuanceComplete(_issuanceProperty.issuanceId);

        // Sets borrowing-specific engagement property
        _bep.loanState = BorrowingEngagementProperty.LoanState.Unpaid;

        _engagementSet.add(ENGAGEMENT_ID);

        // Scheduling Borrowing Engagement Due event
        emit EventTimeScheduled(_issuanceProperty.issuanceId, ENGAGEMENT_ID, engagement.engagementDueTimestamp,
            ENGAGEMENT_DUE_EVENT, "");

        // Emits Engagement Created event
        emit EngagementCreated(_issuanceProperty.issuanceId, ENGAGEMENT_ID, takerAddress);

        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](2));
        // Borrowing token intra-instrument transfer: Taker -> Maker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.IntraInstrument, takerAddress, _issuanceProperty.makerAddress,
            _bip.borrowingTokenAddress, _bip.borrowingAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.IntraInstrument, takerAddress,
            _issuanceProperty.makerAddress, _bip.borrowingTokenAddress, _bip.borrowingAmount, "Principal transfer");

        // Create payable 2: Maker --> Taker
        _createPayable(2, ENGAGEMENT_ID, _issuanceProperty.makerAddress, takerAddress, _bip.borrowingTokenAddress,
            _bip.borrowingAmount, engagement.engagementDueTimestamp);

        // Create payable 3: Maker --> Taker
        _createPayable(3, ENGAGEMENT_ID, _issuanceProperty.makerAddress, takerAddress, _bip.borrowingTokenAddress,
            _bip.interestAmount, engagement.engagementDueTimestamp);

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
            return _repayBorrowingEngagement(notifierAddress);
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
        // Collateral token outbound transfer: Maler --> Maker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Outbound, _issuanceProperty.makerAddress, _issuanceProperty.makerAddress,
            _bip.collateralTokenAddress, _bip.collateralAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Outbound,
            _issuanceProperty.makerAddress, _issuanceProperty.makerAddress, _bip.collateralTokenAddress, _bip.collateralAmount, "Collateral out");

        // Mark payable 1 as paid
        _markPayableAsPaid(1);

        transfersData = Transfers.encode(transfers);
    }

    /**
     * @dev Processes the Engagement Due event.
     */
    function _processEngagementDue() private returns (bytes memory transfersData) {
        // Borrowing Engagement Due will be processed only when:
        // 1. Borrowing Issuance is in Complete state
        // 2. Borrowing Engagement is in Active State
        // 3. Borrowing Engegement loan is in Unpaid State
        // 2. Borrowing engegement due timestamp has passed
        if (_issuanceProperty.issuanceState != IssuanceProperty.IssuanceState.Complete)  return new bytes(0);
        EngagementProperty.Data storage engagement = _engagements[ENGAGEMENT_ID];
        if (engagement.engagementState != EngagementProperty.EngagementState.Active ||
            _bep.loanState == BorrowingEngagementProperty.LoanState.Unpaid ||
            now < engagement.engagementDueTimestamp) return new bytes(0);

        // The engagement is now complete
        engagement.engagementState = EngagementProperty.EngagementState.Complete;
        engagement.engagementCompleteTimestamp = now;
        _bep.loanState = BorrowingEngagementProperty.LoanState.Delinquent;
        emit EngagementComplete(_issuanceProperty.issuanceId, ENGAGEMENT_ID);

        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](1));
        // Collateral token outbound transfer: Maker --> Taker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Outbound, _issuanceProperty.makerAddress, engagement.takerAddress,
            _bip.collateralTokenAddress, _bip.collateralAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Outbound,
            _issuanceProperty.makerAddress, engagement.takerAddress, _bip.collateralTokenAddress, _bip.collateralAmount, "Collateral out");

        // Mark payable 1 as paid
        _markPayableAsPaid(1);
        // Mark payble 2 & 3 as due
        _markPayableAsDue(2);
        _markPayableAsDue(3);
        transfersData = Transfers.encode(transfers);
    }

    /**
     * @dev Cancels the borrowing issuance.
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
        // Collateral token outbound transfer: Maker --> Maker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.Outbound, _issuanceProperty.makerAddress, _issuanceProperty.makerAddress,
            _bip.collateralTokenAddress, _bip.collateralAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Outbound,
            _issuanceProperty.makerAddress, _issuanceProperty.makerAddress, _bip.collateralTokenAddress, _bip.collateralAmount, "Collateral out");

        // Mark payable 1 as paid
        _markPayableAsPaid(1);

        transfersData = Transfers.encode(transfers);
    }

    /**
     * @dev Repays the issuance in full.
     * @param notifierAddress Address of the caller who repays the issuance.
     */
    function _repayBorrowingEngagement(address notifierAddress) private returns (bytes memory transfersData) {
        // Borrowing Engagement Due will be processed only when:
        // 1. Borrowing Issuance is in Complete state
        // 2. Borrowing Engagement is in Active State
        // 3. Borrowing Engegement loan is in Unpaid State
        // 4. Borrowing engegement due timestamp is not passed
        EngagementProperty.Data storage engagement = _engagements[ENGAGEMENT_ID];
        require(_issuanceProperty.issuanceState == IssuanceProperty.IssuanceState.Complete, "Issuance not complete");
        require(engagement.engagementState == EngagementProperty.EngagementState.Active, "Engagement not active");
        require(_bep.loanState == BorrowingEngagementProperty.LoanState.Unpaid, "Loan not unpaid");
        require(now < engagement.engagementDueTimestamp, "Engagement due");
        require(notifierAddress == _issuanceProperty.makerAddress, "Only maker can repay");

        uint256 repayAmount = _bip.borrowingAmount + _bip.interestAmount;
        // Validate principal token balance
        uint256 principalTokenBalance = _instrumentManager.getInstrumentEscrow()
            .getTokenBalance(_issuanceProperty.makerAddress, _bip.borrowingTokenAddress);
        require(principalTokenBalance >= repayAmount, "Insufficient principal balance");

        // Sets Engagement common properties
        engagement.engagementState = EngagementProperty.EngagementState.Complete;
        engagement.engagementCompleteTimestamp = now;
        emit EngagementComplete(_issuanceProperty.issuanceId, ENGAGEMENT_ID);

        // Emits Borrowing-specific Engagement property
        _bep.loanState = BorrowingEngagementProperty.LoanState.Repaid;

        Transfers.Data memory transfers = Transfers.Data(new Transfer.Data[](2));
        // Pricipal + Interest intra-instrument transfer: Maker -> Taker
        transfers.actions[0] = Transfer.Data(Transfer.TransferType.IntraInstrument, _issuanceProperty.makerAddress, engagement.takerAddress,
            _bip.borrowingTokenAddress, repayAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.IntraInstrument,
            _issuanceProperty.makerAddress, engagement.takerAddress, _bip.borrowingTokenAddress, _bip.borrowingAmount, "Principal transfer");
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.IntraInstrument,
            _issuanceProperty.makerAddress, engagement.takerAddress, _bip.borrowingTokenAddress, _bip.interestAmount, "Interest transfer");
        // Collateral outbound transfer: Maker --> Maker
        transfers.actions[1] = Transfer.Data(Transfer.TransferType.Outbound, _issuanceProperty.makerAddress, _issuanceProperty.makerAddress,
            _bip.collateralTokenAddress, _bip.collateralAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfer.TransferType.Outbound,
            _issuanceProperty.makerAddress, _issuanceProperty.makerAddress, _bip.collateralTokenAddress, _bip.collateralAmount, "Collateral out");
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
        return BorrowingIssuanceProperty.encode(_bip);
    }

    /**
     * @dev Returns the issuance-specific data about the engagement.
     */
    function _getEngagementCustomProperty(uint256 /** engagementId */) internal override view returns (bytes memory) {
        return BorrowingEngagementProperty.encode(_bep);
    }
}