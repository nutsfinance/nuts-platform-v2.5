// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "./Instrument.sol";

/**
 * @title Instrument that charges maker and/or taker.
 */
abstract contract FeebasedInstrument is Instrument {

    address private _makerFeeToken;
    address private _takerFeeToken;
    uint256 private _makerFeeAmount;
    uint256 private _takerFeeAmount;

    constructor(address makerFeeToken, uint256 makerFeeAmount, address takerFeeToken, uint256 takerFeeAmount) public {
        _makerFeeToken = makerFeeToken;
        _makerFeeAmount = makerFeeAmount;
        _takerFeeToken = takerFeeToken;
        _takerFeeAmount = takerFeeAmount;
    }

    function setMakerFeeToken(address makerFeeToken) public onlyAdmin {
        _makerFeeToken = makerFeeToken;
    }

    function setMakerFeeAmount(uint256 makerFeeAmount) public onlyAdmin {
        _makerFeeAmount = makerFeeAmount;
    }

    function setTakerFeeToken(address takerFeeToken) public onlyAdmin {
        _takerFeeToken = takerFeeToken;
    }

    function setTakerFeeAmount(uint256 takerFeeAmount) public onlyAdmin {
        _takerFeeAmount = takerFeeAmount;
    }

    function getMakerFee() public view returns (address, uint256) {
        return (_makerFeeToken, _makerFeeAmount);
    }

    function getTakerFee() public view returns (address, uint256) {
        return (_takerFeeToken, _takerFeeAmount);
    }
}