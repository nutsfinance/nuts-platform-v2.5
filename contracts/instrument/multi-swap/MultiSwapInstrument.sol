// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "../ProxyBasedInstrument.sol";
import "../WhitelistInstrument.sol";

/**
 * @title The multi-swap instrument.
 */
contract MultiSwapInstrument is WhitelistInstrument, ProxyBasedInstrument {

    uint256 private _minIssuanceDuration = 0;
    uint256 private _maxIssuanceDuration = 14 days;

    constructor(bool makerWhitelistEnabled, bool takerWhitelistEnabled, address issuanceAddress)
        WhitelistInstrument(makerWhitelistEnabled, takerWhitelistEnabled) ProxyBasedInstrument(issuanceAddress) public {
    }

    /**
     * @dev Returns a unique type ID for the instrument.
     * Instrument Type ID is used to identify the type of the instrument. Instrument ID is instead assigned by
     * Instrument Manager and used to identify an instance of the instrument.
     */
    function getInstrumentTypeID() public pure override returns (bytes4) {
        return bytes4(keccak256('nuts.finance.multiswap-v1'));
    }

    function setMinIssuanceDuration(uint256 minIssuanceDuration) public onlyAdmin {
        _minIssuanceDuration = minIssuanceDuration;
    }

    function setMaxIssuanceDuration(uint256 maxIssuanceDuration) public onlyAdmin {
        _maxIssuanceDuration = maxIssuanceDuration;
    }

    function isIssuanceDurationValid(uint256 issuanceDuration) public view returns (bool) {
        return issuanceDuration >= _minIssuanceDuration && issuanceDuration <= _maxIssuanceDuration;
    }
}