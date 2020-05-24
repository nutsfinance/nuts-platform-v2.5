// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../escrow/EscrowFactoryInterface.sol";
import "../escrow/InstrumentEscrowInterface.sol";
import "../escrow/IssuanceEscrowInterface.sol";
import "../lib/access/AdminAccess.sol";
import "../lib/token/WETH9.sol";
import "../lib/protobuf/Transfers.sol";
import "../Config.sol";
import "./IssuanceInterface.sol";
import "./InstrumentManagerInterface.sol";
import "./InstrumentBase.sol";

contract InstrumentManager is InstrumentManagerInterface {

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    struct IssuanceProperty {
        IssuanceInterface issuance;
        IssuanceEscrowInterface issuanceEscrow;
        uint256 creationTimestamp;
    }

    address private _wethAddress;
    address private _escrowFactoryAddress;
    address private _depositTokenAddress;
    address private _instrumentAddress;
    address private _fspAddress;
    uint256 private _instrumentId;
    InstrumentEscrowInterface private _instrumentEscrow;
    Counters.Counter private _issuanceIds;
    mapping(uint256 => IssuanceProperty) private _issuances;

    // Instrument expiration
    bool internal _active;
    uint256 internal _terminationTimestamp;         // When the instrument is auto-terminated.
    uint256 internal _overrideTimestamp;            // When the instrument can be manually terminated.

    /**
     * @dev Constructor for Instrument Manager.
     * @param instrumentId ID of the instrument.
     * @param fspAddress Address of the FSP who activates the instrument.
     * @param configAddress Address of the config contract.
     * @param instrumentData Custom properties of the instrument.
     */
    constructor(address instrumentAddress, uint256 instrumentId, address fspAddress, address configAddress,
        bytes memory instrumentData) public {
        
        require(instrumentAddress != address(0x0), "InstrumentManager: Instrument not set.");
        require(instrumentId != 0, "InstrumentManager: ID not set.");
        require(fspAddress != address(0x0), "InstrumentManager: FSP not set.");
        require(configAddress != address(0x0), "InstrumentManager: Config not set.");

        _instrumentAddress = instrumentAddress;
        _instrumentId = instrumentId;
        _fspAddress = fspAddress;
        _wethAddress = Config(configAddress).getWETH();
        _escrowFactoryAddress = Config(configAddress).getEscrowFactory();
        _depositTokenAddress = Config(configAddress).getDepositToken();
        _active = true;
        (_terminationTimestamp, _overrideTimestamp) = abi.decode(instrumentData, (uint256, uint256));

        // Creates the Instrument Escrow
        _instrumentEscrow = EscrowFactoryInterface(_escrowFactoryAddress).createInstrumentEscrow(_wethAddress);
    }

    /**
     * @dev Deactivates the instrument. Once deactivated, the instrument cannot create new issuance,
     * but existing active issuances are not affected.
     */
    function deactivate() public override {
        require(_active, "InstrumentManager: Already deactivated.");
        require((now >= _overrideTimestamp && msg.sender == _fspAddress) || now >= _terminationTimestamp,
            "InstrumentManager: Cannot deactivate.");

        // Checks whether this instrument has any deposit.
        ERC20Burnable depositToken = ERC20Burnable(_depositTokenAddress);
        uint256 depositAmount = depositToken.balanceOf(address(this));
        if (depositAmount > 0) {
            // Burns the deposited token.
            depositToken.burn(depositAmount);
        }

        _active = false;
        emit InstrumentDeactivated(_instrumentId);
    }

    /**
     * @dev Creates a new issuance.
     * @param makerData Custom properties of the issuance.
     * @return issuanceId ID of the created issuance.
     */
    function createIssuance(bytes memory makerData) public override returns (uint256 issuanceId) {
        // Makers can create new issuance if:
        // 1. The instrument is active, i.e. is not deactivated by FSP,
        // 2. And the instrument has not reached its termination timestamp.
        require(_active && (now <= _terminationTimestamp), "Instrument deactivated");

        _issuanceIds.increment();
        uint256 newIssuanceId = _issuanceIds.current();
        InstrumentBase instrument = InstrumentBase(_instrumentAddress);

        // Checks whether Issuance Escrow is supported.
        IssuanceEscrowInterface issuanceEscrow = IssuanceEscrowInterface(0);
        if (instrument.supportsIssuanceEscrow()) {
            issuanceEscrow = EscrowFactoryInterface(_escrowFactoryAddress).createIssuanceEscrow(_wethAddress);
        }

        // Creates and initializes the issuance instance.
        (IssuanceInterface issuance, bytes memory transferData) = instrument.createIssuance(newIssuanceId,
            address(issuanceEscrow), msg.sender, makerData);
        _issuances[newIssuanceId] = IssuanceProperty({
            issuance: issuance,
            issuanceEscrow: issuanceEscrow,
            creationTimestamp: now
        });
        // If the instrument supports issuance escrow transaction, grant the admin role of issuance escrow to issuance
        if (instrument.supportsIssuanceTransaction()) {
            issuanceEscrow.grantAdmin(address(issuance));
        }
        emit IssuanceCreated(newIssuanceId, msg.sender, address(issuance), address(issuanceEscrow));

        processTransfers(newIssuanceId, transferData);

        return newIssuanceId;
    }

    /**
     * @dev Engages an existing issuance.
     * @param issuanceId ID of the issuance.
     * @param takerData Custom properties of the engagement.
     * @return engagementId ID of the engagement.
     */
    function engageIssuance(uint256 issuanceId, bytes memory takerData) public override returns (uint256) {
        IssuanceInterface issuance = _issuances[issuanceId].issuance;
        (uint256 engagementId, bytes memory transfersData) = issuance.engage(msg.sender, takerData);

        processTransfers(issuanceId, transfersData);

        return engagementId;
    }

    /**
     * @dev Process a custom event on the issuance or the engagement.
     * @param issuanceId ID of the issuance.
     * @param engagementId ID of the engagement. If the event is for issuance, this param is not used.
     * @param eventName Name of the custom event.
     * @param eventData Data of the custom event.
     */
    function processEvent(uint256 issuanceId, uint256 engagementId, bytes32 eventName, bytes memory eventData) public override {
        IssuanceInterface issuance = _issuances[issuanceId].issuance;
        bytes memory transfersData = issuance.processEvent(engagementId, msg.sender, eventName, eventData);
        processTransfers(issuanceId, transfersData);
    }

    /**
     * @dev Returns the instrument contract address.
     * @return The instrument contract address.
     */
    function getInstrumentAddress() public override view returns (address) {
        return _instrumentAddress;
    }

    /**
     * @dev Returns the address of the FSP which activates the instrument.
     * @return Address of the FSP.
     */
    function getFspAddress() public override view returns (address) {
        return _fspAddress;
    }

    /**
     * @dev Returns the ID of the instrument.
     * @return ID of the instrument.
     */
    function getInstrumentId() public override view returns (uint256) {
        return _instrumentId;
    }

    /**
     * @dev Returns the Instrument Escrow of the instrument.
     * @return Instrument Escrow of the instrument.
     */
    function getInstrumentEscrow() public override view returns (InstrumentEscrowInterface) {
        return _instrumentEscrow;
    }

    /**
     * @dev Returns the total number of issuances.
     * @return Total number of issuances.
     */
    function getIssuanceCount() public override view returns (uint256) {
        return _issuanceIds.current();
    }

    /**
     * @dev Returns the issuance by issuance ID.
     * @param issuanceId ID of the issuance.
     * @return issuance The issuance to lookup.
     */
    function getIssuance(uint256 issuanceId) public override view returns (IssuanceInterface) {
        return _issuances[issuanceId].issuance;
    }

    /**
     * @dev Returns the Issuance Escrow by issuance ID.
     * @param issuanceId ID of the issuance.
     * @return issuanceEscrow The Issuance Escrow of the issuance.
     */
    function getIssuanceEscrow(uint256 issuanceId) public override view returns (IssuanceEscrowInterface) {
        return _issuances[issuanceId].issuanceEscrow;
    }

    /**
     * @dev Processes the transfers for an issuance.
     * @param issuanceId The ID of the issuance to process transfers.
     */
    function processTransfers(uint256 issuanceId, bytes memory transfersData) private {
        IssuanceEscrowInterface issuanceEscrow = _issuances[issuanceId].issuanceEscrow;
        Transfers.Data memory transfers = Transfers.decode(transfersData);
        for (uint256 i = 0; i < transfers.actions.length; i++) {
            // (Transfers.TransferType transferType, address fromAddress, address toAddress, address tokenAddress,
            //     uint256 amount, bytes32 action) = issuance.getTransfer(i);
            Transfer.Data memory transfer = transfers.actions[i];

            if (transfer.transferType == Transfer.TransferType.Inbound) {
                // Withdraw ERC20 token from Instrument Escrow
                _instrumentEscrow.withdrawByAdmin(transfer.fromAddress, transfer.tokenAddress, transfer.amount);
                // IMPORTANT: Set allowance before deposit
                IERC20(transfer.tokenAddress).safeApprove(address(issuanceEscrow), transfer.amount);
                // Deposit ERC20 token to Issuance Escrow
                issuanceEscrow.depositByAdmin(transfer.toAddress, transfer.tokenAddress, transfer.amount);
            } else if (transfer.transferType == Transfer.TransferType.Outbound) {
                // First withdraw ERC20 token from Issuance Escrow to owner
                issuanceEscrow.withdrawByAdmin(transfer.fromAddress, transfer.tokenAddress, transfer.amount);
                // (Important!!!)Then set allowance for Instrument Escrow
                IERC20(transfer.tokenAddress).safeApprove(address(_instrumentEscrow), transfer.amount);
                // Then deposit the ERC20 token from owner to Instrument Escrow
                _instrumentEscrow.depositByAdmin(transfer.toAddress, transfer.tokenAddress, transfer.amount);
            } else if (transfer.transferType == Transfer.TransferType.IntraInstrument) {
                _instrumentEscrow.transferByAdmin(transfer.fromAddress, transfer.toAddress, transfer.tokenAddress, transfer.amount);
            } else {
                issuanceEscrow.transferByAdmin(transfer.fromAddress, transfer.toAddress, transfer.tokenAddress, transfer.amount);
            }

            emit TokenTransferred(issuanceId, transfer.transferType, transfer.fromAddress, transfer.toAddress,
                transfer.tokenAddress, transfer.amount);
        }
    }
}