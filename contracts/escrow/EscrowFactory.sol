// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "../lib/proxy/UpgradeabilityProxy.sol";
import "./IInstrumentEscrow.sol";
import "./IIssuanceEscrow.sol";
import "./IEscrowFactory.sol";
import "./InstrumentEscrow.sol";
import "./IssuanceEscrow.sol";

/**
 * @title Factory of Instrument and Issuance Escrows.
 */
contract EscrowFactory is IEscrowFactory {
    InstrumentEscrow private _instrumentEscrow;
    IssuanceEscrow private _issuanceEscrow;

    constructor() public {
        _instrumentEscrow = new InstrumentEscrow();
        _issuanceEscrow = new IssuanceEscrow();
    }

    /**
     * @dev Create new Instrument Escrow.
     * @param wethAddress Address of the WETH9 token.
     * @return Address of created Instrument Escrow.
     */
    function createInstrumentEscrow(address wethAddress) public override returns (IInstrumentEscrow) {
        UpgradeabilityProxy proxy = new UpgradeabilityProxy(address(_instrumentEscrow));
        InstrumentEscrow instrumentEscrow = InstrumentEscrow(address(proxy));
        instrumentEscrow.initialize(wethAddress);

        return instrumentEscrow;
    }

    /**
     * @dev Create new Issuance Escrow.
     * @param wethAddress Address of the WETH9 token.
     * @return Address of created Issuance Escrow.
     */
    function createIssuanceEscrow(address wethAddress) public override returns (IIssuanceEscrow) {
        UpgradeabilityProxy proxy = new UpgradeabilityProxy(address(_issuanceEscrow));
        IssuanceEscrow issuanceEscrow = IssuanceEscrow(address(proxy));
        issuanceEscrow.initialize(wethAddress);

        return issuanceEscrow;
    }

}