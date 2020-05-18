// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

library Constant {
    /**
     * @dev Defines a special address to represent ETH.
     */
    function getEthAddress() internal pure returns (address) {
        return address(-1);
    }

}
