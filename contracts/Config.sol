// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Config is Ownable {

    address private _wethAddress;
    address private _escrowFactoryAddress;
    address private _depositTokenAddress;
    uint256 private _depositAmount;
    mapping(bytes32 => address) private _instrumentManagerFactories;

    constructor(address wethAddress, address escrowFactoryAddress, address depositTokenAddress, uint256 depositAmount) public {
        require(wethAddress != address(0x0), "Config: WETH not set.");
        require(escrowFactoryAddress != address(0x0), "Config: Escrow Factory not set.");
        require(depositTokenAddress != address(0x0), "Config: Deposit token not set.");

        _wethAddress = wethAddress;
        _escrowFactoryAddress = _escrowFactoryAddress;
        _depositTokenAddress = depositTokenAddress;
        _depositAmount = depositAmount;
    }

    function getWETH() public view returns (address) {
        return _wethAddress;
    }

    function setWETH(address wethAddress) public onlyOwner {
        require(wethAddress != address(0x0), "Config: WETH not set.");
        _wethAddress = wethAddress;
    }

    function getEscrowFactory() public view returns (address) {
        return _escrowFactoryAddress;
    }

    function setEscrowFactory(address escrowFactoryAddress) public onlyOwner {
        require(escrowFactoryAddress != address(0x0), "Config: Escrow Factory not set.");
        _escrowFactoryAddress = escrowFactoryAddress;
    }

    function getDepositToken() public view returns (address) {
        return _depositTokenAddress;
    }

    function setDepositToken(address depositTokenAddress) public onlyOwner {
        require(depositTokenAddress != address(0x0), "Config: Deposit token not set.");
        _depositTokenAddress = depositTokenAddress;
    }

    function getDepositAmount() public view returns (uint256) {
        return _depositAmount;
    }

    function setDepositAmount(uint256 depositAmount) public onlyOwner {
        _depositAmount = depositAmount;
    }

    function getInstrumentManagerFactory(bytes32 version) public view returns (address) {
        return _instrumentManagerFactories[version];
    }

    function setInstrumentManagerFactory(bytes32 version, address instrumentManagerFactoryAddress) public onlyOwner {
        require(instrumentManagerFactoryAddress != address(0x0), "Config: Instrument Manager Factory not set.");
        _instrumentManagerFactories[version] = instrumentManagerFactoryAddress;
    }
}