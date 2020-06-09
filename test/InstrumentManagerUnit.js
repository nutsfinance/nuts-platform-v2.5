const InstrumentManager = artifacts.require('InstrumentManager');
const InstrumentRegistry = artifacts.require('InstrumentRegistry');
const NUTSTokenMock = artifacts.require('NUTSToken');
const Config = artifacts.require("Config");
const WETH9 = artifacts.require("WETH9");
const EscrowFactory = artifacts.require('EscrowFactory');
const InstrumentManagerFactory = artifacts.require('InstrumentManagerFactory');
const PriceOracle = artifacts.require('PriceOracle');
const Token = artifacts.require('ERC20Mock');
const BorrowingInstrument = artifacts.require("BorrowingInstrument");
const BorrowingIssuance = artifacts.require("BorrowingIssuance");
const assert = require('assert');
const { BN, constants, balance, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

const EMPTY_ADDRESS = '0x0000000000000000000000000000000000000000';
let instrumentManager;
let borrowingInstrument;
let config;
contract('InstrumentManager', ([owner, account1, account2, account3, account4, account5]) => {
    beforeEach(async () => {
      let weth9 = await WETH9.new();
      let instrumentManagerFactory = await InstrumentManagerFactory.new();
      let nutsToken = await NUTSTokenMock.new(web3.utils.fromAscii("NUTS Token Test"), web3.utils.fromAscii("NUTSTEST"), 20000);
      let priceOracle = await PriceOracle.new();
      let escrowFactory = await EscrowFactory.new();
      config = await Config.new(weth9.address, escrowFactory.address, nutsToken.address, 0);
      let instrumentRegistry = await InstrumentRegistry.new(config.address);
      let borrowingIssuance = await BorrowingIssuance.new();
      borrowingInstrument = await BorrowingInstrument.new(false, false, priceOracle.address, borrowingIssuance.address);
      instrumentManager = await InstrumentManager.new(borrowingInstrument.address, 1, account1, config.address, web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['1', '1']));
    }),
    it('invalid constructor', async() => {
      let borrowingInstrumentParameters = web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']);
      await expectRevert(InstrumentManager.new(EMPTY_ADDRESS, 1, account1, account2, borrowingInstrumentParameters), "InstrumentManager: Instrument not set.");
      await expectRevert(InstrumentManager.new(borrowingInstrument.address, 0, account1, account2, borrowingInstrumentParameters), "InstrumentManager: ID not set.");
      await expectRevert(InstrumentManager.new(borrowingInstrument.address, 1, EMPTY_ADDRESS, account2, borrowingInstrumentParameters), "InstrumentManager: FSP not set.");
      await expectRevert(InstrumentManager.new(borrowingInstrument.address, 1, account1, EMPTY_ADDRESS, borrowingInstrumentParameters), "InstrumentManager: Config not set.");
    }),
    it('deactivated', async() => {
      await instrumentManager.deactivate({from: account1});
      await expectRevert(instrumentManager.deactivate({from: account1}), "InstrumentManager: Already deactivated.");
      await expectRevert(instrumentManager.createIssuance([], {from: account2}), "Instrument deactivated");
    }),
    it('deactivate', async() => {
      instrumentManager = await InstrumentManager.new(borrowingInstrument.address, 1, account1, config.address, web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
      await expectRevert(instrumentManager.deactivate({from: account1}), "InstrumentManager: Cannot deactivate.");
      instrumentManager = await InstrumentManager.new(borrowingInstrument.address, 1, account1, config.address, web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '1']));
      await expectRevert(instrumentManager.deactivate({from: account2}), "InstrumentManager: Cannot deactivate.");
      instrumentManager = await InstrumentManager.new(borrowingInstrument.address, 1, account1, config.address, web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['1', '9590280014']));
      await instrumentManager.deactivate({from: account2});
      instrumentManager = await InstrumentManager.new(borrowingInstrument.address, 1, account1, config.address, web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '1']));
      await instrumentManager.deactivate({from: account1});
    })
 });
