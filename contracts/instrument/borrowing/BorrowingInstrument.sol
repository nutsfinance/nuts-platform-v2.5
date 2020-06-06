// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "../../lib/priceoracle/PriceOracleInterface.sol";
import "../WhitelistInstrument.sol";
import "../ProxyBasedInstrument.sol";

/**
 * @title The borrowing instrument.
 */
contract BorrowingInstrument is WhitelistInstrument, ProxyBasedInstrument {

    PriceOracleInterface private _priceOracle;
    uint256 private _minIssuanceDuration = 0;
    uint256 private _maxIssuanceDuration = 14 days;
    uint256 private _minTenorDays = 2;
    uint256 private _maxTenorDays = 90;
    uint256 private _minCollateralRatio = 5000; // 50%
    uint256 private _maxCollateralRatio = 20000;    // 200%
    uint256 private _minInterestRate = 10;  // 0.0010%
    uint256 private _maxInterestRate = 50000;   // 5.0000%

    constructor(bool makerWhitelistEnabled, bool takerWhitelistEnabled, address priceOracleAddress, address issuanceAddress)
        WhitelistInstrument(makerWhitelistEnabled, takerWhitelistEnabled) ProxyBasedInstrument(issuanceAddress) public {
        require(priceOracleAddress != address(0x0), "BorrowingInstrument: Price oracle not set.");

        _priceOracle = PriceOracleInterface(priceOracleAddress);
    }

    /**
     * @dev Returns a unique type ID for the instrument.
     * Instrument Type ID is used to identify the type of the instrument. Instrument ID is instead assigned by
     * Instrument Manager and used to identify an instance of the instrument.
     */
    function getInstrumentTypeID() public pure override returns (bytes4) {
        return bytes4(keccak256('nuts.finance.borrowing-v1'));
    }

    function setPriceOracle(PriceOracleInterface priceOracle) public onlyAdmin {
        _priceOracle = priceOracle;
    }

    function getPriceOracle() public view returns (PriceOracleInterface) {
        return _priceOracle;
    }

    function setMinIssuanceDuration(uint256 minIssuanceDuration) public onlyAdmin {
        _minIssuanceDuration = minIssuanceDuration;
    }

    function setMaxIssuanceDuration(uint256 maxIssuanceDuration) public onlyAdmin {
        _maxIssuanceDuration = maxIssuanceDuration;
    }

    function isIssuanceDurationValid(uint256 issuanceDuration) public view returns (bool) {
        return issuanceDuration >= _minIssuanceDuration && issuanceDuration <= _maxIssuanceDuration;
    }

    function setMinTenorDays(uint256 minTenorDays) public onlyAdmin {
        _minTenorDays = minTenorDays;
    }

    function setMaxTenorDays(uint256 maxTenorDays) public onlyAdmin {
        _maxTenorDays = maxTenorDays;
    }

    function isTenorDaysValid(uint256 tenorDays) public view returns (bool) {
        return tenorDays >= _minTenorDays && tenorDays <= _maxTenorDays;
    }

    function setMinCollateralRatio(uint256 minCollateralRatio) public onlyAdmin {
        _minCollateralRatio = minCollateralRatio;
    }

    function setMaxCollateralRatio(uint256 maxCollateralRatio) public onlyAdmin {
        _maxCollateralRatio = maxCollateralRatio;
    }

    function isCollateralRatioValid(uint256 collateralRatio) public view returns (bool) {
        return collateralRatio >= _minCollateralRatio && collateralRatio <= _maxCollateralRatio;
    }

    function setMinInterestRate(uint256 minInterestRate) public onlyAdmin {
        _minInterestRate = minInterestRate;
    }

    function setMaxInterestRate(uint256 maxInterestRate) public onlyAdmin {
        _maxInterestRate = maxInterestRate;
    }

    function isInterestRateValid(uint256 interestRate) public view returns (bool) {
        return interestRate >= _minInterestRate && interestRate <= _maxInterestRate;
    }
}