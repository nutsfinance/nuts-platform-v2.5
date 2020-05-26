// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "../ProxyBasedInstrument.sol";
import "../WhitelistInstrument.sol";

/**
 * @title The multi-swap instrument.
 */
contract MultiSwapInstrument is WhitelistInstrument, ProxyBasedInstrument {

    constructor(bool makerWhitelistEnabled, bool takerWhitelistEnabled, address issuanceAddress)
        WhitelistInstrument(makerWhitelistEnabled, takerWhitelistEnabled) ProxyBasedInstrument(issuanceAddress) public {
    }
}