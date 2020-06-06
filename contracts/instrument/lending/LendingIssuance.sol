// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../lib/data/Transfers.sol";
import "../../lib/protobuf/IssuanceData.sol";
import "../../lib/protobuf/LendingData.sol";
import "../../lib/priceoracle/PriceOracleInterface.sol";
import "../../escrow/InstrumentEscrowInterface.sol";
import "../IssuanceBase.sol";
import "./LendingInstrument.sol";

/**
 * @title 1 to 1 lending issuance contract.
 */
contract LendingIssuance is IssuanceBase {
    using SafeMath for uint256;

    // Constants
    uint256 internal constant ENGAGEMENT_ID = 1; // Since it's 1 to 1, we use a constant engagement id 1
    uint256 internal constant COLLATERAL_RATIO_DECIMALS = 10**4; // 0.01%
    uint256 internal constant INTEREST_RATE_DECIMALS = 10**6; // 0.0001%

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
     * @return transfers Transfer actions for the issuance.
     */
    function initialize(address instrumentManagerAddress, address instrumentAddress, uint256 issuanceId,
        address issuanceEscrowAddress, address makerAddress, bytes memory makerData)
        public override returns (Transfers.Transfer[] memory transfers) {

        LendingInstrument lendingInstrument = LendingInstrument(instrumentAddress);
        require(lendingInstrument.isMakerAllowed(makerAddress), "LendingIssuance: Maker not allowed.");
        IssuanceBase._initialize(instrumentManagerAddress, instrumentAddress, issuanceId, issuanceEscrowAddress, makerAddress);

        uint256 issuanceDuration;
        (issuanceDuration, _lip.lendingTokenAddress, _lip.collateralTokenAddress, _lip.lendingAmount, _lip.tenorDays,
            _lip.collateralRatio, _lip.interestRate) = abi.decode(makerData, (uint256, address, address, uint256, uint256, uint256, uint256));

        // Validates parameters
        require(_lip.collateralTokenAddress != address(0x0), "LendingIssuance: Collateral token not set.");
        require(_lip.lendingTokenAddress != address(0x0), "LendingIssuance: Lending token not set.");
        require(_lip.lendingAmount > 0, "Lending amount not set");
        
        require(lendingInstrument.isIssuanceDurationValid(issuanceDuration), "LendingIssuance: Invalid duration.");
        require(lendingInstrument.isTenorDaysValid(_lip.tenorDays), "LendingIssuance: Invalid tenor days.");
        require(lendingInstrument.isCollateralRatioValid(_lip.collateralRatio), "LendingIssuance: Invalid collateral ratio.");
        require(lendingInstrument.isInterestRateValid(_lip.interestRate), "LendingIssuance: Invalid interest rate.");

        // Validate principal token balance
        uint256 principalBalance = _instrumentManager.getInstrumentEscrow().getTokenBalance(makerAddress, _lip.lendingTokenAddress);
        require(principalBalance >= _lip.lendingAmount, "LendingIssuance: Insufficient principal balance.");

        // Sets common properties
        _issuanceProperty.issuanceDueTimestamp = now.add(issuanceDuration);
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Engageable;
        emit IssuanceCreated(_issuanceProperty.issuanceId, makerAddress, _issuanceProperty.issuanceDueTimestamp);

        // Sets lending issuance properties
        _lip.interestAmount = _lip.lendingAmount.mul(_lip.tenorDays).mul(_lip.interestRate).div(INTEREST_RATE_DECIMALS);

        // Scheduling Issuance Due event
        emit EventTimeScheduled(_issuanceProperty.issuanceId, 0, _issuanceProperty.issuanceDueTimestamp, ISSUANCE_DUE_EVENT, "");

        // Transfers principal token
        // Principal token inbound transfer: Maker --> Maker
        transfers = new Transfers.Transfer[](1);
        transfers[0] = Transfers.Transfer(Transfers.TransferType.Inbound, makerAddress,
            makerAddress, _lip.lendingTokenAddress, _lip.lendingAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, 0, Transfers.TransferType.Inbound, makerAddress,
            makerAddress, _lip.lendingTokenAddress, _lip.lendingAmount, "Principal in");

        // Create payable 1: Custodian --> Maker
        _createPayable(1, 0, address(_issuanceEscrow), makerAddress, _lip.lendingTokenAddress,
            _lip.lendingAmount, _issuanceProperty.issuanceDueTimestamp);
    }

    /**
     * @dev Creates a new engagement for the issuance. Only admin(Instrument Manager) can call this method.
     * @param takerAddress Address of the user who engages the issuance.
     * @return engagementId ID of the engagement.
     * @return transfers Asset transfer actions.
     */
    function engage(address takerAddress, bytes memory /** takerData */)
        public override onlyAdmin returns (uint256 engagementId, Transfers.Transfer[] memory transfers) {
        require(LendingInstrument(_instrumentAddress).isTakerAllowed(takerAddress), "LendingIssuance: Taker not allowed.");
        require(_issuanceProperty.issuanceState == IssuanceProperty.IssuanceState.Engageable, "Issuance not Engageable");
        require(now <= _issuanceProperty.issuanceDueTimestamp, "Issuance due");
        require(_engagementSet.length() == 0, "Already engaged");

        // Calculate the collateral amount. Collateral is calculated at the time of engagement.
        PriceOracleInterface priceOracle = LendingInstrument(_instrumentAddress).getPriceOracle();
        _lep.collateralAmount = priceOracle.getOutputAmount(_lip.lendingTokenAddress, _lip.collateralTokenAddress,
            _lip.lendingAmount.mul(_lip.collateralRatio).div(COLLATERAL_RATIO_DECIMALS));

        // Validates collateral balance
        uint256 collateralBalance = _instrumentManager.getInstrumentEscrow().getTokenBalance(takerAddress, _lip.collateralTokenAddress);
        require(collateralBalance >= _lep.collateralAmount, "Insufficient collateral balance");

        // Set common engagement property
        EngagementProperty.Data storage engagement = _engagements[ENGAGEMENT_ID];
        engagement.engagementId = ENGAGEMENT_ID;
        engagement.takerAddress = takerAddress;
        engagement.engagementCreationTimestamp = now;
        engagement.engagementDueTimestamp = now.add(_lip.tenorDays * 1 days);
        engagement.engagementState = EngagementProperty.EngagementState.Active;
        emit EngagementCreated(_issuanceProperty.issuanceId, ENGAGEMENT_ID, takerAddress);

        // Set common issuance property
        _issuanceProperty.issuanceState = IssuanceProperty.IssuanceState.Complete;
        _issuanceProperty.issuanceCompleteTimestamp = now;
        _issuanceProperty.completionRatio = COMPLETION_RATIO_RANGE;
        emit IssuanceComplete(_issuanceProperty.issuanceId, COMPLETION_RATIO_RANGE);

        // Sets lending-specific engagement property
        _lep.loanState = LendingEngagementProperty.LoanState.Unpaid;

        engagementId = ENGAGEMENT_ID;
        _engagementSet.add(ENGAGEMENT_ID);

        // Scheduling Lending Engagement Due event
        emit EventTimeScheduled(_issuanceProperty.issuanceId, ENGAGEMENT_ID, engagement.engagementDueTimestamp,
            ENGAGEMENT_DUE_EVENT, "");

        transfers = new Transfers.Transfer[](2);
        // Collateral token inbound transfer: Taker -> Taker
        transfers[0] = Transfers.Transfer(Transfers.TransferType.Inbound, takerAddress, takerAddress,
            _lip.collateralTokenAddress, _lep.collateralAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfers.TransferType.Inbound, takerAddress, takerAddress,
            _lip.collateralTokenAddress, _lep.collateralAmount, "Collateral in");
        // Principal token outbound transfer: Maker --> Taker
        transfers[1] = Transfers.Transfer(Transfers.TransferType.Outbound, _issuanceProperty.makerAddress, takerAddress,
            _lip.lendingTokenAddress, _lip.lendingAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfers.TransferType.Outbound,
            _issuanceProperty.makerAddress, takerAddress, _lip.lendingTokenAddress, _lip.lendingAmount, "Principal out");

        // Create payable 2: Custodian --> Taker
        _createPayable(2, ENGAGEMENT_ID, address(_issuanceEscrow), takerAddress, _lip.collateralTokenAddress,
            _lep.collateralAmount, engagement.engagementDueTimestamp);

        // Create payable 3: Taker --> Maker
        _createPayable(3, ENGAGEMENT_ID, takerAddress, _issuanceProperty.makerAddress, _lip.lendingTokenAddress,
            _lip.lendingAmount, engagement.engagementDueTimestamp);

        // Create payable 4: Taker --> Maker
        _createPayable(4, ENGAGEMENT_ID, takerAddress, _issuanceProperty.makerAddress, _lip.lendingTokenAddress,
            _lip.interestAmount, engagement.engagementDueTimestamp);

        // Mark payable 1 as reinitiated by payable 3
        _reinitiatePayable(1, 3);
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
        // Principal token outbound transfer: Maler --> Maker
        transfers[0] = Transfers.Transfer(Transfers.TransferType.Outbound, _issuanceProperty.makerAddress,
            _issuanceProperty.makerAddress, _lip.lendingTokenAddress, _lip.lendingAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, 0, Transfers.TransferType.Outbound,
            _issuanceProperty.makerAddress, _issuanceProperty.makerAddress, _lip.lendingTokenAddress, _lip.lendingAmount, "Principal out");

        // Mark payable 1 as paid
        _markPayableAsPaid(1);
    }

    /**
     * @dev Processes the Engagement Due event.
     */
    function _processEngagementDue() private returns (Transfers.Transfer[] memory transfers) {
        // Lending Engagement Due will be processed only when:
        // 1. Lending Issuance is in Complete state
        // 2. Lending Engagement is in Active State
        // 3. Lending Engegement loan is in Unpaid State
        // 2. Lending engegement due timestamp has passed
        if (_issuanceProperty.issuanceState != IssuanceProperty.IssuanceState.Complete)  return new Transfers.Transfer[](0);
        EngagementProperty.Data storage engagement = _engagements[ENGAGEMENT_ID];
        if (engagement.engagementState != EngagementProperty.EngagementState.Active ||
            _lep.loanState != LendingEngagementProperty.LoanState.Unpaid ||
            now < engagement.engagementDueTimestamp) {
          return new Transfers.Transfer[](0);
        }

        // The engagement is now complete
        engagement.engagementState = EngagementProperty.EngagementState.Complete;
        engagement.engagementCompleteTimestamp = now;
        _lep.loanState = LendingEngagementProperty.LoanState.Delinquent;
        emit EngagementComplete(_issuanceProperty.issuanceId, ENGAGEMENT_ID);

        transfers = new Transfers.Transfer[](1);
        // Collateral token outbound transfer: Taker --> Maker
        transfers[0] = Transfers.Transfer(Transfers.TransferType.Outbound, engagement.takerAddress, _issuanceProperty.makerAddress,
            _lip.collateralTokenAddress, _lep.collateralAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfers.TransferType.Outbound,
            engagement.takerAddress, _issuanceProperty.makerAddress, _lip.collateralTokenAddress, _lep.collateralAmount, "Collateral out");

        // Mark payable 2 as paid
        _markPayableAsPaid(2);
        // Mark payble 3 & 4 as due
        _markPayableAsDue(3);
        _markPayableAsDue(4);
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
        // Principal token outbound transfer: Makr --> Maker
        transfers[0] = Transfers.Transfer(Transfers.TransferType.Outbound, _issuanceProperty.makerAddress, _issuanceProperty.makerAddress,
            _lip.lendingTokenAddress, _lip.lendingAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, 0, Transfers.TransferType.Outbound,
            _issuanceProperty.makerAddress, _issuanceProperty.makerAddress, _lip.lendingTokenAddress, _lip.lendingAmount, "Principal out");

        // Mark payable 1 as paid
        _markPayableAsPaid(1);
    }

    /**
     * @dev Repays the issuance in full.
     * @param notifierAddress Address of the caller who repays the issuance.
     */
    function _repayLendingEngagement(address notifierAddress) private returns (Transfers.Transfer[] memory transfers) {
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

        transfers = new Transfers.Transfer[](2);
        // Pricipal + Interest intra-instrument transfer: Taker -> Maker
        transfers[0] = Transfers.Transfer(Transfers.TransferType.IntraInstrument, engagement.takerAddress, _issuanceProperty.makerAddress,
            _lip.lendingTokenAddress, repayAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfers.TransferType.IntraInstrument,
            engagement.takerAddress, _issuanceProperty.makerAddress, _lip.lendingTokenAddress, _lip.lendingAmount, "Principal transfer");
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfers.TransferType.IntraInstrument,
            engagement.takerAddress, _issuanceProperty.makerAddress, _lip.lendingTokenAddress, _lip.interestAmount, "Interest transfer");
        // Collateral outbound transfer: Taker --> Taker
        transfers[1] = Transfers.Transfer(Transfers.TransferType.Outbound, engagement.takerAddress, engagement.takerAddress,
            _lip.collateralTokenAddress, _lep.collateralAmount);
        emit AssetTransferred(_issuanceProperty.issuanceId, ENGAGEMENT_ID, Transfers.TransferType.Outbound,
            engagement.takerAddress, engagement.takerAddress, _lip.collateralTokenAddress, _lep.collateralAmount, "Collateral out");

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
