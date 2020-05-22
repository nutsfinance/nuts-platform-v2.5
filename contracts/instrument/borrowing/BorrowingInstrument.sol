// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "../../lib/priceoracle/PriceOracleInterface.sol";
import "../../lib/proxy/UpgradeabilityProxy.sol";
import "../WhitelistInstrument.sol";
import "../IssuanceInterface.sol";

/**
 * @title The borrowing instrument.
 */
contract BorrowingInstrument is WhitelistInstrument {

    PriceOracleInterface private _priceOracle;
    address private _issuanceAddress;

    constructor(bool makerWhitelistEnabled, bool takerWhitelistEnabled, address priceOracleAddress, address issuanceAddress)
        WhitelistInstrument(makerWhitelistEnabled, takerWhitelistEnabled) public {
        require(priceOracleAddress != address(0x0), "BorrowingInstrument: Price oracle not set.");
        require(issuanceAddress != address(0x0), "BorrowingInstrument: Issuance not set.");

        _priceOracle = PriceOracleInterface(priceOracleAddress);
        _issuanceAddress = issuanceAddress;
    }

    function getPriceOracle() public view returns (PriceOracleInterface) {
        return _priceOracle;
    }

    /**
     * @dev Creates a new issuance instance.
     * @param issuanceId ID of the issuance.
     * @param issuanceEscrowAddress Address of the issuance escrow.
     * @param makerAddress Address of the user who creates the issuance.
     * @param makerData Custom properties of the issuance.
     * @return issuance The created issuance instance.
     * @return transfersData Initial token transfer actions.
     */
    function createIssuance(uint256 issuanceId, address issuanceEscrowAddress, address makerAddress,
        bytes memory makerData) public override returns (IssuanceInterface issuance, bytes memory transfersData) {

        UpgradeabilityProxy proxy = new UpgradeabilityProxy(_issuanceAddress);
        issuance = IssuanceInterface(address(proxy));
        transfersData = issuance.initialize(msg.sender, address(this), issuanceId, issuanceEscrowAddress, makerAddress, makerData);
    }
}