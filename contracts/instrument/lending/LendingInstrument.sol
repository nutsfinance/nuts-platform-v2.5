// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "../../lib/priceoracle/IPriceOracle.sol";
import "../../lib/proxy/UpgradeabilityProxy.sol";
import "../WhitelistInstrument.sol";
import "../IIssuance.sol";
import "./LendingIssuance.sol";

/**
 * @title The lending instrument.
 */
contract LendingInstrument is WhitelistInstrument {

    IPriceOracle private _priceOracle;
    address private _issuanceAddress;

    constructor(bool makerWhitelistEnabled, bool takerWhitelistEnabled, address priceOracleAddress, address issuanceAddress)
        WhitelistInstrument(makerWhitelistEnabled, takerWhitelistEnabled) public {
        require(priceOracleAddress != address(0x0), "LendingInstrument: Price oracle not set.");
        require(issuanceAddress != address(0x0), "LendingInstrument: Issuance not set.");

        _priceOracle = IPriceOracle(priceOracleAddress);
        _issuanceAddress = issuanceAddress;
    }

    function getPriceOracle() public view returns (IPriceOracle) {
        return _priceOracle;
    }

    /**
     * @dev Creates a new issuance instance.
     * @param instrumentManagerAddress Address of the instrument manager.
     * @param issuanceId ID of the issuance.
     * @param issuanceEscrowAddress Address of the issuance escrow.
     * @param makerAddress Address of the user who creates the issuance.
     * @param makerData Custom properties of the issuance.
     * @return The created issuance instance.
     * @return Initial token transfer actions.
     */
    function createIssuance(address instrumentManagerAddress, uint256 issuanceId, address issuanceEscrowAddress,
        address makerAddress, bytes memory makerData) public override returns (IIssuance issuance, bytes memory transfersData) {

        UpgradeabilityProxy proxy = new UpgradeabilityProxy(_issuanceAddress);
        issuance = IIssuance(address(proxy));
        transfersData = issuance.initialize(instrumentManagerAddress, address(this), issuanceId, issuanceEscrowAddress, makerAddress, makerData);
    }
}