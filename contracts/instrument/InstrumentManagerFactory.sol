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

    /**
     * @dev Creates a new instrument manager.
     * @param instrumentAddress Address of the instrument.
     * @param instrumentId Id of the activated instrument.
     * @param fspAddress Address of the FSP who activates the instrument.
     * @param configAddress Address of the NUTS Platform config contract.
     * @param instrumentData Custom property of the instrument.
     */
    function createInstrumentManager(address instrumentAddress, uint256 instrumentId, address fspAddress,
        address configAddress, bytes memory instrumentData) public override returns (InstrumentManagerInterface) {
        
        return new InstrumentManager(instrumentAddress, instrumentId, fspAddress, configAddress, instrumentData);
    }
} 