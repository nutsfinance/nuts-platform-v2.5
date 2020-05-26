// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "../../lib/priceoracle/PriceOracleInterface.sol";
import "../ProxyBasedInstrument.sol";
import "../WhitelistInstrument.sol";

/**
 * @title The lending instrument.
 */
contract LendingInstrument is WhitelistInstrument, ProxyBasedInstrument {

    PriceOracleInterface private _priceOracle;

    constructor(bool makerWhitelistEnabled, bool takerWhitelistEnabled, address priceOracleAddress, address issuanceAddress)
        WhitelistInstrument(makerWhitelistEnabled, takerWhitelistEnabled) ProxyBasedInstrument(issuanceAddress) public {
        require(priceOracleAddress != address(0x0), "LendingInstrument: Price oracle not set.");

        _priceOracle = PriceOracleInterface(priceOracleAddress);
    }

    function getPriceOracle() public view returns (PriceOracleInterface) {
        return _priceOracle;
    }
}