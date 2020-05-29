// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

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

    /**
     * @dev Returns a unique type ID for the instrument.
     * Instrument Type ID is used to identify the type of the instrument. Instrument ID is instead assigned by
     * Instrument Manager and used to identify an instance of the instrument.
     */
    function getInstrumentTypeID() public pure override returns (bytes4) {
        return bytes4(keccak256('nuts.finance.lending-v1'));
    }

    function getPriceOracle() public view returns (PriceOracleInterface) {
        return _priceOracle;
    }
}