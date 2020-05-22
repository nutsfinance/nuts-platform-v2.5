// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "./InstrumentManagerInterface.sol";
import "../Config.sol";

/**
 * @dev Interface for Instrument Manager Factory.
 */
abstract contract InstrumentManagerFactoryInterface {

    function createInstrumentManager(address instrumentAddress, uint256 instrumentId, address fspAddress,
        address configAddress, bytes memory instrumentData) public virtual returns (InstrumentManagerInterface);

} 