// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../lib/priceoracle/PriceOracleInterface.sol";

contract PriceOracleMock is PriceOracleInterface {
    using SafeMath for uint256;

    struct Rate {
        uint256 numerator;
        uint256 denominator;
    }

    mapping(address => mapping(address => Rate)) private _rates;

    function getRate(address inputTokenAddress, address outputTokenAddress) public view override
        returns (uint256 numerator, uint256 denominator) {
        if (inputTokenAddress == outputTokenAddress) return (1, 1);
        Rate storage rate = _rates[inputTokenAddress][outputTokenAddress];
        return (rate.numerator, rate.denominator);
    }

    function getOutputAmount(address inputTokenAddress, address outputTokenAddress, uint256 inputAmount)
        public view override returns (uint256) {
        (uint256 numerator, uint256 denominator) = getRate(inputTokenAddress, outputTokenAddress);

        return inputAmount.mul(denominator).div(numerator);
    }

    function setRate(address inputTokenAddress, address outputTokenAddress, uint256 numerator, uint256 denominator) public {
        _rates[inputTokenAddress][outputTokenAddress].numerator = numerator;
        _rates[inputTokenAddress][outputTokenAddress].denominator = denominator;
    }
}
