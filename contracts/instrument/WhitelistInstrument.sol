// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "./InstrumentBase.sol";

/**
 * @title Instrument that has maker and taker white list.
 */
abstract contract WhitelistInstrument is InstrumentBase {

    bool private _makerWhitelistEnabled;
    bool private _takerWhitelistEnabled;
    mapping(address => bool) private _makerWhitelist;
    mapping(address => bool) private _takerWhitelist;

    constructor(bool makerWhitelistEnabled, bool takerWhitelistEnabled) internal {
        _makerWhitelistEnabled = makerWhitelistEnabled;
        _takerWhitelistEnabled = takerWhitelistEnabled;
    }

    function setMakerAllowed(address maker, bool allowed) public onlyAdmin {
        _makerWhitelist[maker] = allowed;
    }

    function setTakerAllowed(address taker, bool allowed) public onlyAdmin {
        _takerWhitelist[taker] = allowed;
    }

    /**
     * @dev Whether this maker is allowed to create a new Issuance.
     * Maker is allowed if maker white list is not enabled, or the maker is in the whitelist.
     */
    function isMakerAllowed(address maker) public view returns (bool) {
        return !_makerWhitelistEnabled ||  _makerWhitelist[maker];
    }

    /**
     * @dev Whether this taker is allowed to engage an Issuance.
     * Taker is allowed if taker white list is not enabled, or the taker is in the whitelist.
     */
    function isTakerAllowed(address taker) public view returns (bool) {
        return !_takerWhitelistEnabled ||  _takerWhitelist[taker];
    }
}