// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "./InstrumentManagerInterface.sol";
import "../Config.sol";

/**
 * @dev Interface for Instrument Manager Factory.
 */
abstract contract InstrumentManagerFactoryInterface {

    /**
     * @dev Creates a new instrument manager.
     * @param instrumentAddress Address of the instrument.
     * @param instrumentId Id of the activated instrument.
     * @param fspAddress Address of the FSP who activates the instrument.
     * @param configAddress Address of the NUTS Platform config contract.
     * @param instrumentData Custom property of the instrument.
     */
    function createInstrumentManager(address instrumentAddress, uint256 instrumentId, address fspAddress,
        address configAddress, bytes memory instrumentData) public virtual returns (InstrumentManagerInterface);

} 