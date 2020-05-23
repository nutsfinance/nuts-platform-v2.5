// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "../lib/proxy/UpgradeabilityProxy.sol";
import "./InstrumentBase.sol";

/**
 * @title Instrument that uses Proxy to create new issuance.
 */
contract ProxyBasedInstrument is InstrumentBase {

    address internal _issuanceAddress;

    constructor(address issuanceAddress) public {
        require(issuanceAddress != address(0x0), "ProxyBasedInstrument: Issuance not set.");
        _issuanceAddress = issuanceAddress;
    }

    /**
     * @dev Creates a new issuance instance.
     * @param issuanceId ID of the issuance.
     * @param issuanceEscrowAddress Address of the issuance escrow.
     * @param makerAddress Address of the user who creates the issuance.
     * @param makerData Custom properties of the issuance.
     * @return issuance The created issuance instance.
     * @return transfersData Initial token transfer actions.
     */
    function createIssuance(uint256 issuanceId, address issuanceEscrowAddress, address makerAddress,
        bytes memory makerData) public override virtual returns (IssuanceInterface issuance, bytes memory transfersData) {

        UpgradeabilityProxy proxy = new UpgradeabilityProxy(_issuanceAddress);
        issuance = IssuanceInterface(address(proxy));
        transfersData = issuance.initialize(msg.sender, address(this), issuanceId, issuanceEscrowAddress, makerAddress, makerData);
    }
}

