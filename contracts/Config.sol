// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Config is Ownable {

    address private _wethAddress;
    address private _depositTokenAddress;
    uint256 private _depositAmount;

    constructor(address wethAddress, address depositTokenAddress, uint256 depositAmount) public {
        _wethAddress = wethAddress;
        _depositTokenAddress = depositTokenAddress;
        _depositAmount = depositAmount;
    }

    function getWETH() public view returns (address) {
        return _wethAddress;
    }

    function setWETH(address wethAddress) public onlyOwner {
        _wethAddress = wethAddress;
    }

    function getDepositToken() public view returns (address) {
        return _depositTokenAddress;
    }

    function setDepositToken(address depositTokenAddress) public onlyOwner {
        _depositTokenAddress = depositTokenAddress;
    }

    function getDepositAmount() public view returns (uint256) {
        return _depositAmount;
    }

    function setDepositAmount(uint256 depositAmount) public onlyOwner {
        _depositAmount = depositAmount;
    }
}