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

    /**
     * @dev Creates a new issuance instance.
     * @return The created issuance instance.
     */
    function createIssuance() public override returns (Issuance) {
        return new LendingIssuance();
    }
}