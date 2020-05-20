// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "./IInstrumentEscrow.sol";
import "./IIssuanceEscrow.sol";
import "./IEscrowFactory.sol";
import "./InstrumentEscrow.sol";
import "./IssuanceEscrow.sol";

/**
 * @title Factory of Instrument and Issuance Escrows.
 */
contract EscrowFactory is IEscrowFactory {

    /**
     * @dev Create new Instrument Escrow.
     * @param wethAddress Address of the WETH9 token.
     * @return Address of created Instrument Escrow.
     */
    function createInstrumentEscrow(address wethAddress) public override returns (IInstrumentEscrow) {
        return new InstrumentEscrow(wethAddress);
    }

    /**
     * @dev Create new Issuance Escrow.
     * @param wethAddress Address of the WETH9 token.
     * @return Address of created Issuance Escrow.
     */
    function createIssuanceEscrow(address wethAddress) public override returns (IIssuanceEscrow) {
        return IssuanceEscrow(wethAddress);
    }

}