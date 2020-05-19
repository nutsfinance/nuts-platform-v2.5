// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "../lib/token/WETH9.sol";
import "./IEscrowFactory.sol";
import "./IInstrumentEscrow.sol";
import "./InstrumentEscrow.sol";
import "./IIssuanceEscrow.sol";
import "./IssuanceEscrow.sol";

/**
 * @title The factory for Instrument Escrow and Issuance Escrow.
 */
contract EscrowFactory is IEscrowFactory {

    WETH9 private _weth;

    constructor(WETH9 weth) public {
        _weth = weth;
    }

    /**
     * @dev Creates an Instrument Escrow instance.
     */
    function createInstrumentEscrow() public override returns (IInstrumentEscrow) {
        return new InstrumentEscrow(_weth);
    }

    /**
     * @dev Creates an Issuance Escrow instance.
     */
    function createIssuanceEscrow() public override returns (IIssuanceEscrow) {
        return new IssuanceEscrow(_weth);
    }
}