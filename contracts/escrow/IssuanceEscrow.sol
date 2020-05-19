// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "../lib/token/WETH9.sol";
import "./EscrowBase.sol";
import "./IIssuanceEscrow.sol";

/**
 * @title Issuance Escrow that keeps assets that are locked by issuance.
 */
contract IssuanceEscrow is EscrowBase, IIssuanceEscrow {
    constructor(WETH9 weth) EscrowBase(weth) public {}
}
