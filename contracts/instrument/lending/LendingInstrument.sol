// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "../../lib/priceoracle/IPriceOracle.sol";
import "../WhitelistInstrument.sol";
import "../Issuance.sol";
import "./LendingIssuance.sol";

/**
 * @title The lending instrument.
 */
contract LendingInstrument is WhitelistInstrument {

    IPriceOracle private _priceOracle;

    constructor(bool makerWhitelistEnabled, bool takerWhitelistEnabled, address priceOracleAddress)
        WhitelistInstrument(makerWhitelistEnabled, takerWhitelistEnabled) public {
        require(priceOracleAddress != address(0x0), "LendingInstrument: Price oracle not set.");
        _priceOracle = IPriceOracle(priceOracleAddress);
    }

    function getPriceOracle() public view returns (IPriceOracle) {
        return _priceOracle;
    }

    /**
     * @dev Creates a new lending issuance instance.
     * @param issuanceId ID of the issuance.
     * @param issuanceEscrowAddress Address of the issuance escrow.
     * @param makerAddress Address of the user who creates the issuance.
     * @return The created issuance instance.
     */
    function createIssuance(uint256 issuanceId, address issuanceEscrowAddress, address makerAddress)
        public override returns (Issuance) {

        return new LendingIssuance(address(this), issuanceId, issuanceEscrowAddress, makerAddress);
    }
}