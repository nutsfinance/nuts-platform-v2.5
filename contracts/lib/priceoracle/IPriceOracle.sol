// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

interface IPriceOracle {
    /**
     * @dev Get the exchange rate between two tokens.
     * @param baseTokenAddress The address of base ERC20 token. ETH has a special address defined in Constants.getEthAddress()
     * @param quoteTokenAddress The address of quote ERC20 token. ETH has a special address defined in Constants.getEthAddress()
     * @return numerator The rate expressed as numerator/denominator.
     * @return denominator The rate expressed as numerator/denominator.
     */
    function getRate(address baseTokenAddress, address quoteTokenAddress)
        external
        view
        returns (uint256 numerator, uint256 denominator);
}
