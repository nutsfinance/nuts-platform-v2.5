// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "./InstrumentManagerInterface.sol";
import "./InstrumentManager.sol";
import "./InstrumentManagerFactoryInterface.sol";
import "../Config.sol";

/**
 * @dev Factory of Instrument Manager.
 */
contract InstrumentManagerFactory is InstrumentManagerFactoryInterface {

    function createInstrumentManager(address instrumentAddress, uint256 instrumentId, address fspAddress,
        address configAddress, bytes memory instrumentData) public override returns (InstrumentManagerInterface) {
        
        return new InstrumentManager(instrumentAddress, instrumentId, fspAddress, configAddress, instrumentData);
    }
} 