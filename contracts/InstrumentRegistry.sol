// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./instrument/InstrumentManagerFactoryInterface.sol";
import "./Config.sol";

/**
 * @title The registry for all instruments.
 */
contract InstrumentRegistry {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    /**
     * @dev The instrument is activated.
     */
    event InstrumentActivated(uint256 indexed instrumentId, address indexed fspAddress,
        address indexed instrumentAddress, address instrumentManagerAddress, address instrumentEscrowAddress);

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
        uint256 instrumentId = _instrumentIds.current();
        InstrumentManagerFactoryInterface instrumentManagerFactory = InstrumentManagerFactoryInterface(
            _config.getInstrumentManagerFactory(version));
        InstrumentManagerInterface instrumentManager = instrumentManagerFactory.createInstrumentManager(
            instrumentAddress, instrumentId, msg.sender, address(_config), instrumentData);

        _instrumentManagers[instrumentId] = address(instrumentManager);
        emit InstrumentActivated(instrumentId, msg.sender, instrumentAddress, address(instrumentManager),
            address(instrumentManager.getInstrumentEscrow()));

        if (_config.getDepositAmount() > 0) {
            IERC20 depositToken = IERC20(_config.getDepositToken());
            // Transfers NUTS token from sender to Instrument Registry first
            // as user approves Instrument Registry instead of the newly created Instrument Manager.
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