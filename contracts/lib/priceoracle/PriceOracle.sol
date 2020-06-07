// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./PriceOracleInterface.sol";
import "../access/AdminAccess.sol";

/**
 * @title Basic price oracle implementation.
 */
contract PriceOracle is PriceOracleInterface, AdminAccess {
    using SafeMath for uint256;

    constructor() public {
        AdminAccess._initialize(msg.sender);
    }

    /**
     * @dev Represent the rate between two tokens.
     * The rate is represented as numerator / denominator.
     */
    struct Rate {
        uint256 numerator;
        uint256 denominator;
    }

    // Input token => (Output token => Rate)
    mapping(address => mapping(address => Rate)) private _rates;

    /**
     * @dev Get the exchange rate between two tokens.
     * Note: Output token price / Input token price = numberator/denominator.
     * @param inputTokenAddress The address of base ERC20 token. ETH should use the WETH address.
     * @param outputTokenAddress The address of quote ERC20 token. ETH should use the WETH address.
     * @return numerator The rate expressed as numerator/denominator.
     * @return denominator The rate expressed as numerator/denominator.
     */
    function getRate(address inputTokenAddress, address outputTokenAddress) public view override
        returns (uint256 numerator, uint256 denominator) {
        if (inputTokenAddress == outputTokenAddress) return (1, 1);
        Rate storage rate = _rates[inputTokenAddress][outputTokenAddress];
        return (rate.numerator, rate.denominator);
    }

    /**
     * @dev Returns the output token amount.
     * Note: Output amount = Input amount * output token price / (Input token price)
     * @param inputTokenAddress The address of base ERC20 token. ETH should use the WETH address.
     * @param outputTokenAddress The address of quote ERC20 token. ETH should use the WETH address.
     * @param inputAmount Amount of input token.
     * @return The output token amount.
     */
    function getOutputAmount(address inputTokenAddress, address outputTokenAddress, uint256 inputAmount)
        public view override returns (uint256) {
        (uint256 numerator, uint256 denominator) = getRate(inputTokenAddress, outputTokenAddress);

        return inputAmount.mul(denominator).div(numerator);
    }

    /**
     * @dev Returns the input token amount.
     * Note: Input amount = Output amount * iutput token price / (Output token price)
     * @param inputTokenAddress The address of base ERC20 token. ETH should use the WETH address.
     * @param outputTokenAddress The address of quote ERC20 token. ETH should use the WETH address.
     * @param outputAmount Amount of output token.
     * @return The input token amount.
     */
    function getInputAmount(address inputTokenAddress, address outputTokenAddress, uint256 outputAmount)
        public view override returns (uint256) {
        (uint256 numerator, uint256 denominator) = getRate(inputTokenAddress, outputTokenAddress);

        return outputAmount.mul(numerator).div(denominator);
    }

    /**
     * @dev Sets the rates between input and output token.
     */
    function setRate(address inputTokenAddress, address outputTokenAddress, uint256 numerator,
        uint256 denominator) public onlyAdmin {
        _rates[inputTokenAddress][outputTokenAddress].numerator = numerator;
        _rates[inputTokenAddress][outputTokenAddress].denominator = denominator;
    }
}
