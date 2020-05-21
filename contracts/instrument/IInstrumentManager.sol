// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "../escrow/IInstrumentEscrow.sol";
import "../escrow/IIssuanceEscrow.sol";
import "../lib/protobuf/Transfers.sol";
import "./Issuance.sol";
import "./Instrument.sol";

abstract contract IInstrumentManager {
    /**
     * @dev The instrument is activated.
     */
    event InstrumentActivated(uint256 indexed instrumentId, address indexed instrumentAddress,
        address fspAddress, address instrumentEscrowAddress);

    /**
     * @dev The instrument is deactivated.
     */
    event InstrumentDeactivated(uint256 indexed instrumentId);

    /**
     * @dev Token is transferred.
     */
    event TokenTransferred(uint256 indexed issuanceId, Transfer.TransferType transferType, address fromAddress,
        address toAddress, address tokenAddress, uint256 amount);

    /**
     * @dev Deactivates the instrument. Once deactivated, the instrument cannot create new issuance,
     * but existing active issuances are not affected.
     */
    function deactivate() public virtual;

    /**
     * @dev Creates a new issuance.
     * @param makerData Custom properties of the issuance.
     * @return issuanceId ID of the created issuance.
     */
    function createIssuance(bytes memory makerData) public virtual returns (uint256 issuanceId);

    /**
     * @dev Engages an existing issuance.
     * @param issuanceId ID of the issuance.
     * @param takerData Custom properties of the engagement.
     * @return engagementId ID of the engagement.
     */
    function engageIssuance(uint256 issuanceId, bytes memory takerData) public virtual returns (uint256 engagementId);

    /**
     * @dev Process a custom event on the issuance or the engagement.
     * @param issuanceId ID of the issuance.
     * @param engagementId ID of the engagement. If the event is for issuance, this param is not used.
     * @param eventName Name of the custom event.
     * @param eventData Data of the custom event.
     */
    function processEvent(uint256 issuanceId, uint256 engagementId, bytes32 eventName, bytes memory eventData) public virtual;

    /**
     * @dev Returns the address of the instrument contract.
     * @return The instrument contract address.
     */
    function getInstrumentAddress() public virtual view returns (address);

    /**
     * @dev Returns the address of the FSP which activates the instrument.
     * @return Address of the FSP.
     */
    function getFspAddress() public virtual view returns (address);

    /**
     * @dev Returns the ID of the instrument.
     * @return ID of the instrument.
     */
    function getInstrumentId() public virtual view returns (uint256);

    /**
     * @dev Returns the Instrument Escrow of the instrument.
     * @return Instrument Escrow of the instrument.
     */
    function getInstrumentEscrow() public virtual view returns (IInstrumentEscrow);

    /**
     * @dev Returns the total number of issuances.
     * @return Total number of issuances.
     */
    function getIssuanceCount() public virtual view returns (uint256);

    /**
     * @dev Returns the issuance by issuance ID.
     * @param issuanceId ID of the issuance.
     * @return The issuance to lookup.
     */
    function getIssuance(uint256 issuanceId) public virtual view returns (Issuance);

    /**
     * @dev Returns the Issuance Escrow by issuance ID.
     * @param issuanceId ID of the issuance.
     * @return The Issuance Escrow of the issuance.
     */
    function getIssuanceEscrow(uint256 issuanceId) public virtual view returns (IIssuanceEscrow);
}