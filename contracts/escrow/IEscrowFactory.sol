// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "./IInstrumentEscrow.sol";
import "./IIssuanceEscrow.sol";

/**
 * @title Interface for Escrow Factory.
 */
interface IEscrowFactory {

    /**
     * @dev Creates an Instrument Escrow instance.
     */
    function createInstrumentEscrow() external virtual returns (IInstrumentEscrow);

    /**
     * @dev Creates an Issuance Escrow instance.
     */
    function createIssuanceEscrow() external virtual returns (IIssuanceEscrow);
}