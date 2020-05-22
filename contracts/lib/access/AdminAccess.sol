// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title A base contract that provide admin access control.
 */
abstract contract AdminAccess is AccessControl {
    // Creates a new role identifier for the owner role
    // Owners can grant/revoke admin roles, and owners are also admin
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // Creates a new role identifier for the admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    function _initialize(address owner) internal virtual {
        // Grant the owner role to the contract creator
        _setupRole(OWNER_ROLE, owner);
        // Grant the admin role to the contract creator as well
        _setupRole(ADMIN_ROLE, owner);
        // Grant the admin of admin role to the contract creator
        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
    }

    /**
     * @dev Throws if called by any account that does not have admin role.
     */
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }
}