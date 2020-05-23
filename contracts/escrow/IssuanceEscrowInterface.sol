// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "./EscrowInterface.sol";

/**
 * @dev Interface for Issuance Escrow.
 * Defines additional methods for Issuance Escrow.
 */
abstract contract IssuanceEscrowInterface is EscrowInterface {

    /**
     * @dev Grants an admin role to the account.
     * @param account The address of the new admin.
     */
    function grantAdmin(address account) public virtual;
}
