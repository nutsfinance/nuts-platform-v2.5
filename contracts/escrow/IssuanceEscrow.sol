// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "./EscrowBase.sol";
import "./IssuanceEscrowInterface.sol";

/**
 * @title Issuance Escrow that keeps assets that are locked by issuance.
 */
contract IssuanceEscrow is EscrowBase, IssuanceEscrowInterface {
    function initialize(address wethAddress) public {
        super._initialize(wethAddress);
    }
}
