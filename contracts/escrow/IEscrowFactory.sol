// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "./IInstrumentEscrow.sol";
import "./IIssuanceEscrow.sol";

/**
 * @title Interface for Escrow Factory.
 */
interface IEscrowFactory {

    /**
     * @dev Create new Instrument Escrow.
     * @param wethAddress Address of the WETH9 token.
     * @return Address of created Instrument Escrow.
     */
    function createInstrumentEscrow(address wethAddress) external returns (IInstrumentEscrow);

    /**
     * @dev Create new Issuance Escrow.
     * @param wethAddress Address of the WETH9 token.
     * @return Address of created Issuance Escrow.
     */
    function createIssuanceEscrow(address wethAddress) external returns (IIssuanceEscrow);

}