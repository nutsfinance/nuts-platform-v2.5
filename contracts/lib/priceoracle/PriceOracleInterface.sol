// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

interface PriceOracleInterface {
    /**
     * @dev Get the exchange rate between two tokens.
     * Note: Output token price / Input token price = numberator/denominator.
     * @param inputTokenAddress The address of base ERC20 token. ETH should use the WETH address.
     * @param outputTokenAddress The address of quote ERC20 token. ETH should use the WETH address.
     * @return numerator The rate expressed as numerator/denominator.
     * @return denominator The rate expressed as numerator/denominator.
     */
    function getRate(address inputTokenAddress, address outputTokenAddress) external view
        returns (uint256 numerator, uint256 denominator);

    /**
     * @dev Returns the output token amount.
     * Note: Output amount = numerator * output token price / (denominator * input token price)
     * @param inputTokenAddress The address of base ERC20 token. ETH should use the WETH address.
     * @param outputTokenAddress The address of quote ERC20 token. ETH should use the WETH address.
     * @param numerator The input token amount can be represented as numberator/denominator.
     * @param denominator The input token amount can be represented as numberator/denominator.
     * @return The output token amount.
     */
    function getOutputAmount(address inputTokenAddress, address outputTokenAddress, uint256 numerator, uint256 denominator)
        external view returns (uint256);
}