// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "./IInstrumentManager.sol";
import "./InstrumentManager.sol";
import "./IInstrumentManagerFactory.sol";
import "../Config.sol";

/**
 * @dev Factory of Instrument Manager.
 */
contract InstrumentManagerFactory is IInstrumentManagerFactory {

    function createInstrumentManager(address instrumentAddress, uint256 instrumentId, address fspAddress,
        address configAddress, bytes memory instrumentData) public override returns (IInstrumentManager) {
        
        return new InstrumentManager(instrumentAddress, instrumentId, fspAddress, configAddress, instrumentData);
    }
} 