// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/utils/Counters.sol";

contract InstrumentRegistry {
    using Counters for Counters.Counter;
    Counters.Counter private _instrumentIds;
}