const { BN, constants, balance, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const assert = require('assert');
const LogParser = require(__dirname + "/LogParser.js");

const InstrumentManagerFactory = artifacts.require('InstrumentManagerFactory');
const InstrumentManager = artifacts.require('InstrumentManager');
const InstrumentManagerInterface = artifacts.require('InstrumentManagerInterface');
const BorrowingInstrument = artifacts.require("BorrowingInstrument");
const BorrowingIssuance = artifacts.require("BorrowingIssuance");
const PriceOracle = artifacts.require('PriceOracle');
const InstrumentEscrowInterface = artifacts.require('InstrumentEscrowInterface');
const IssuanceEscrowInterface = artifacts.require('IssuanceEscrowInterface');
const InstrumentRegistry = artifacts.require('InstrumentRegistry');
const NUTSTokenMock = artifacts.require('NUTSToken');
const TokenMock = artifacts.require('ERC20Mock');
const EscrowFactory = artifacts.require('EscrowFactory');
const IssuanceEscrow = artifacts.require('IssuanceEscrow');
const InstrumentEscrow = artifacts.require('InstrumentEscrow');
const Config = artifacts.require("Config");
const WETH9 = artifacts.require("WETH9");

const EMPTY_ADDRESS = '0x0000000000000000000000000000000000000000';

contract('InstrumentRegistry', ([owner, proxyAdmin, timerOracle, fsp, maker1, taker1, maker2, taker2, maker3, taker3]) => {
  it('invalid constructor', async () => {
    await expectRevert(InstrumentRegistry.new(EMPTY_ADDRESS), "InstrumentRegistry: Config not set.");
  }),
  it('invalid activate instrument', async () => {
    let weth9 = await WETH9.new();
    let escrowFactory = await EscrowFactory.new();
    let nutsToken = await NUTSTokenMock.new(web3.utils.fromAscii("NUTS Token Test"), web3.utils.fromAscii("NUTSTEST"), 20000);
    let config = await Config.new(weth9.address, escrowFactory.address, nutsToken.address, 0);
    let instrumentRegistry = await InstrumentRegistry.new(config.address);
    await expectRevert(instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), EMPTY_ADDRESS, web3.utils.fromAscii(""), {from: fsp}), 'InstrumentRegistry: Instrument not set.');
    await expectRevert(instrumentRegistry.activateInstrument(web3.utils.fromAscii("2"), owner, web3.utils.fromAscii(""), {from: fsp}), 'InstrumentRegistry: Version not found.');
  }),
  it('new instrument deposit cost', async () => {
    weth9 = await WETH9.new();
    const escrowFactory = await EscrowFactory.new();
    const nutsToken = await NUTSTokenMock.new(web3.utils.fromAscii("NUTS Token Test"), web3.utils.fromAscii("NUTSTEST"), 20000, {from: owner});
    await nutsToken.mint(fsp, 200, {from: owner});
    const config = await Config.new(weth9.address, escrowFactory.address, nutsToken.address, 1);
    const instrumentRegistry = await InstrumentRegistry.new(config.address);

    // Deploy Instrument Manager Factory.
    const instrumentManagerFactory = await InstrumentManagerFactory.new();
    await config.setInstrumentManagerFactory(web3.utils.fromAscii("v2.5"), instrumentManagerFactory.address);

    // Deploy the Price Oracle.
    const priceOracle = await PriceOracle.new();

    // Deploy Borrowing Instrument.
    const borrowingIssuance = await BorrowingIssuance.new();
    const borrowingInstrument = await BorrowingInstrument.new(false, false, priceOracle.address, borrowingIssuance.address);
    await nutsToken.approve(instrumentRegistry.address, 10000, {from: fsp});
    let txn = await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), borrowingInstrument.address,
      web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']), {from: fsp});
    let abis = [].concat(NUTSTokenMock.abi, InstrumentRegistry.abi);
    let events = LogParser.logParser(txn.receipt.rawLogs, abis);
    let receipt = {logs: events};
    expectEvent(receipt, 'Transfer', {
      from: fsp,
      to: instrumentRegistry.address,
      value: '1'
    });
  }),
  it('issuance terminated token returned', async () => {
    weth9 = await WETH9.new();
    const escrowFactory = await EscrowFactory.new();
    const nutsToken = await NUTSTokenMock.new(web3.utils.fromAscii("NUTS Token Test"), web3.utils.fromAscii("NUTSTEST"), 20000, {from: owner});
    await nutsToken.mint(fsp, 200, {from: owner});
    const config = await Config.new(weth9.address, escrowFactory.address, nutsToken.address, 1);
    const instrumentRegistry = await InstrumentRegistry.new(config.address);

    // Deploy Instrument Manager Factory.
    const instrumentManagerFactory = await InstrumentManagerFactory.new();
    await config.setInstrumentManagerFactory(web3.utils.fromAscii("v2.5"), instrumentManagerFactory.address);

    // Deploy the Price Oracle.
    const priceOracle = await PriceOracle.new();

    // Deploy Borrowing Instrument.
    const borrowingIssuance = await BorrowingIssuance.new();
    const borrowingInstrument = await BorrowingInstrument.new(false, false, priceOracle.address, borrowingIssuance.address);
    await nutsToken.approve(instrumentRegistry.address, 10000, {from: fsp});
    await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), borrowingInstrument.address,
      web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['1', '1']), {from: fsp});
    let instrumentManagerAddress = await instrumentRegistry.getInstrumentManager(1);
    let instrumentManager = await InstrumentManager.at(instrumentManagerAddress);
    let txn = await instrumentManager.deactivate();
    let abis = [].concat(NUTSTokenMock.abi, InstrumentRegistry.abi, InstrumentManager.abi);
    let events = LogParser.logParser(txn.receipt.rawLogs, abis);
    let receipt = {logs: events};
    expectEvent(receipt, 'Transfer', {
      from: instrumentManagerAddress,
      to: fsp,
      value: '1'
    });
  })
});
