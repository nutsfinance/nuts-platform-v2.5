// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "./InstrumentBase.sol";

/**
 * @title Instrument that charges maker and/or taker.
 */
abstract contract FeebasedInstrument is InstrumentBase {

    address private _makerFeeTokenAddress;
    address private _takerFeeTokenAddress;
    uint256 private _makerFeeAmount;
    uint256 private _takerFeeAmount;
    address private _feeRecepientAddress;

    /**
     * @param makerFeeTokenAddress The token that maker needs to pay.
     * @param makerFeeAmount The amount that maker needs to pay.
     * @param takerFeeTokenAddress The token that taker needs to pay.
     * @param takerFeeAmount The amount that taker needs to pay.
     * @param feeRecepientAddress Recepient of the maker and taker fee.
     */
    constructor(address makerFeeTokenAddress, uint256 makerFeeAmount, address takerFeeTokenAddress, uint256 takerFeeAmount,
        address feeRecepientAddress) internal {
        _makerFeeTokenAddress = makerFeeTokenAddress;
        _makerFeeAmount = makerFeeAmount;
        _takerFeeTokenAddress = takerFeeTokenAddress;
        _takerFeeAmount = takerFeeAmount;
        _feeRecepientAddress = feeRecepientAddress;
    }

    function setMakerFeeToken(address makerFeeTokenAddress) public onlyAdmin {
        _makerFeeTokenAddress = makerFeeTokenAddress;
    }

    function setMakerFeeAmount(uint256 makerFeeAmount) public onlyAdmin {
        _makerFeeAmount = makerFeeAmount;
    }

    function setTakerFeeToken(address takerFeeTokenAddress) public onlyAdmin {
        _takerFeeTokenAddress = takerFeeTokenAddress;
    }

    function setTakerFeeAmount(uint256 takerFeeAmount) public onlyAdmin {
        _takerFeeAmount = takerFeeAmount;
    }

    function setFeeRecepientAddress(address feeRecepientAddress) public onlyAdmin {
        _feeRecepientAddress = feeRecepientAddress;
    }

    function getMakerFee() public view returns (address, uint256) {
        return (_makerFeeTokenAddress, _makerFeeAmount);
    }

    function getTakerFee() public view returns (address, uint256) {
        return (_takerFeeTokenAddress, _takerFeeAmount);
    }

    function getFeeRecepient() public view returns (address) {
        return _feeRecepientAddress;
    }
}