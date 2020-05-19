// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "./Instrument.sol";

/**
 * @title Instrument that has maker and taker white list.
 */
abstract contract WhitelistInstrument is Instrument {

    bool private _makerWhitelistEnabled;
    bool private _takerWhitelistEnabled;
    mapping(address => bool) private _makerWhitelist;
    mapping(address => bool) private _takerWhitelist;

    constructor(bool makerWhitelistEnabled, bool takerWhitelistEnabled) public {
        _makerWhitelistEnabled = makerWhitelistEnabled;
        _takerWhitelistEnabled = takerWhitelistEnabled;
    }

    function setMakerAllowed(address maker, bool allowed) public onlyAdmin {
        _makerWhitelist[maker] = allowed;
    }

    function setTakerAllowed(address taker, bool allowed) public onlyAdmin {
        _takerWhitelist[taker] = allowed;
    }

    function isMakerAllowed(address maker) public view returns (bool) {
        return !_makerWhitelistEnabled ||  _makerWhitelist[maker];
    }

    function isTakerAllowed(address taker) public view returns (bool) {
        return !_takerWhitelistEnabled ||  _takerWhitelist[taker];
    }
}