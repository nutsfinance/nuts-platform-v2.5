// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./instrument/InstrumentManagerFactoryInterface.sol";
import "./Config.sol";

contract InstrumentRegistry {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    Counters.Counter private _instrumentIds;
    Config private _config;
    mapping(uint256 => address) _instrumentManagers;

    constructor(address configAddress) public {
        require(configAddress != address(0x0), "InstrumentRegistry: Config not set.");
        _config = Config(configAddress);
    }

    /**
     * @dev MOST IMPORTANT method: Activate new financial instrument.
     * @param version Version of financial instrument to activate.
     * @param instrumentAddress Address of Instrument to activate.
     * @param instrumentData Custom properties for this instrument.
     * @return The ID of the instrument
     */
    function activateInstrument(bytes32 version, address instrumentAddress, bytes memory instrumentData) public returns (uint256) {
        require(instrumentAddress != address(0x0), "InstrumentRegistry: Instrument not set.");
        require(_config.getInstrumentManagerFactory(version) != address(0x0), "InstrumentRegistry: Version not found.");

        _instrumentIds.increment();
        // Create Instrument Manager
        InstrumentManagerFactoryInterface instrumentManagerFactory = InstrumentManagerFactoryInterface(
            _config.getInstrumentManagerFactory(version));
        InstrumentManagerInterface instrumentManager = instrumentManagerFactory.createInstrumentManager(
            instrumentAddress, _instrumentIds.current(), msg.sender, address(_config), instrumentData);

        _instrumentManagers[_instrumentIds.current()] = address(instrumentManager);

        if (_config.getDepositAmount() > 0) {
            IERC20 depositToken = IERC20(_config.getDepositToken());
            // Transfers NUTS token from sender to Instrument Registry.
            depositToken.safeTransferFrom(msg.sender, address(this), _config.getDepositAmount());
            // Sends NUTS token from Instrument Registry to the newly created Instrument Manager.
            depositToken.safeTransfer(address(instrumentManager), _config.getDepositAmount());
        }

        return _instrumentIds.current();
    }

    /**
     * @dev Retrieve Instrument Manager address by Instrument ID.
     */
    function getInstrumentManager(uint256 instrumentId) public view returns (address) {
        return _instrumentManagers[instrumentId];
    }

}