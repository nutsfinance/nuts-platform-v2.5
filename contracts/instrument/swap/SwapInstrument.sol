// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "../ProxyBasedInstrument.sol";
import "../WhitelistInstrument.sol";

/**
 * @title The swap instrument.
 */
contract SwapInstrument is WhitelistInstrument, ProxyBasedInstrument {

    constructor(bool makerWhitelistEnabled, bool takerWhitelistEnabled, address issuanceAddress)
        WhitelistInstrument(makerWhitelistEnabled, takerWhitelistEnabled) ProxyBasedInstrument(issuanceAddress) public {
    }
}