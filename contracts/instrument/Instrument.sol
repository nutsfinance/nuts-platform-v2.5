// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/utils/Counters.sol";
import "Issuance.sol";

/**
 * @title Base class for instrument.
 */
abstract contract Instrument {

    using Counters for Counters.Counter;
    
    Counters.Counter private _issuanceIds;
    mapping(uint256 => Issuance) private _issuances;

    /**
     * @dev Whether the instrument supports Issuance Escrow.
     * If true, Instrument Manager creates a new Issuance Escrow for each new Issuance.
     * @return Whether Issuance Escrow is supported
     */
    function supportsIssuanceEscrow() public virtual pure returns bool;

    /**
     * @dev Creates a new issuance instance.
     * @param issuanceEscrowAddress The address of the created Issuance Escrow. 0 if Issuance Escrow is not supported.
     * @param makerAddress The address of the maker.
     * @param makerData Custom properties of the issuance.
     * @return ID of the created issuance.
     */
    function createIssuance(address issuanceEscrowAddress, address makerAddress, bytes makerData) public returns uint256 {
        _issuanceIds.increment();
        uint256 newIssuanceId = _issuanceIds.current();
        _issuances[newIssuanceId] = _createIssuanceInstance(newIssuanceId, issuanceEscrowAddress, makerAddress, makerData);

        return newIssuanceId;
    }

    /**
     * @dev Returns the total number of issuances created.
     * @return The number of created issuance.
     */
    function getIssuanceCount() public view returns uint256 {
        return _issuanceIds.current();
    }

    /**
     * @dev Looks up issuance by issuance ID.
     * @param issuanceId ID of the issuance to lookup.
     * @return The issuance instance.
     */
    function getIssuance(uint256 issuanceId) public view returns Issuance {
        return _issuances[issuanceId];
    }

    /**
     * @dev The hook method to create the actual issuance instance.
     * @param issuanceId ID of the created issuance.
     * @param issuanceEscrowAddress The address of the created Issuance Escrow. 0 if Issuance Escrow is not supported.
     * @param makerAddress The address of the maker.
     * @param makerData Custom properties of the issuance.
     * @return The created issuance instace.
     */
    function _createIssuanceInstance(uint256 issuanceId, address issuanceEscrowAddress, address makerAddress, bytes makerData) internal virtual returns Issuance;
}