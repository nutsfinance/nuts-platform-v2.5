// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "./IInstrumentManager.sol";
import "../Config.sol";

/**
 * @dev Interface for Instrument Manager Factory.
 */
abstract contract IInstrumentManagerFactory {

    function createInstrumentManager(address instrumentAddress, uint256 instrumentId, address fspAddress,
        address configAddress, bytes memory instrumentData) public virtual returns (IInstrumentManager);

} 