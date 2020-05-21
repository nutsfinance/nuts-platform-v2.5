// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "../../lib/protobuf/Transfers.sol";
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
    uint256 private _collateralAmount;
    uint256 private _interestRate;
    uint256 private _interestAmount;
    uint256 private _engagementDueTimestamp;

    // Lending engagement properties

    /**
     * @param instrumentAddress Address of the instrument contract.
     * @param issuanceId ID of the issuance.
     * @param issuanceEscrowAddress Address of the issuance escrow.
     * @param makerAddress Address of the user who creates the issuance.
     */
    constructor(address instrumentAddress, uint256 issuanceId, address issuanceEscrowAddress, address makerAddress)
        Issuance(instrumentAddress, issuanceId, issuanceEscrowAddress, makerAddress) public {}

    /**
     * @dev Initializes the issuance.
     * @param makerData Custom properties of the issuance.
     * @return transfersData Asset transfer actions.
     */
    function initialize(bytes memory makerData) public override returns (bytes memory transfersData) {
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
        IInstrumentEscrow instrumentEscrow = LendingInstrument(_instrumentAddress).getInstrumentEscrow();
        uint256 principalBalance = instrumentEscrow.getTokenBalance(_makerAddress, _lendingToken);
        require(principalBalance >= _lendingAmount, "LendingIssuance: Insufficient principal balance.");

        // Sets common properties
        _engagementDueTimestamp = now.add(ENGAGEMENT_DUE_DAYS);

        // Sets lending properties
        _interestAmount = _lendingAmount.mul(_tenorDays).mul(_interestRate).div(INTEREST_RATE_DECIMALS);

        // Updates to Engageable state
        _state = IssuanceProperty.IssuanceState.Engageable;

        // Emits Scheduled Engagement Due event
        emit EventTimeScheduled(_issuanceId, 0, _engagementDueTimestamp, ENGAGEMENT_DUE_EVENT, "");

        // Emits Issuance Created event
        emit IssuanceCreated(_issuanceId, _makerAddress, now);

        // Transfers principal token
        // Principal token inbound transfer: Maker --> Maker
        Transfers.Data memory transfers = Transfers.Data(
            new Transfer.Data[](1)
        );
        transfers.actions[0] = Transfer.Data({
            transferType: Transfer.TransferType.Inbound,
            fromAddress: _makerAddress,
            toAddress: _makerAddress,
            tokenAddress: _lendingToken,
            amount: _lendingAmount,
            action: "Principal in"
        });
        transfersData = Transfers.encode(transfers);

        // Create payable 1: Custodian --> Maker
        _createPayable(1, ENGAGEMENT_ID, address(_issuanceEscrow), _makerAddress, _lendingToken, _lendingAmount, _engagementDueTimestamp);
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

    /**
     * @dev Returns the issuance-specific data about the issuance.
     */
    function _getIssuanceCustomProperty() internal override view returns (bytes memory) {

    }

    /**
     * @dev Returns the issuance-specific data about the engagement.
     * @param engagementId ID of the engagement
     */
    function _getEngagementCustomProperty(uint256 engagementId) internal override view returns (bytes memory) {
        
    }
}