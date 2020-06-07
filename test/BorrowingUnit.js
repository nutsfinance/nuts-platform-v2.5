const { BN, constants, balance, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const assert = require('assert');
const SolidityEvent = require("web3");
const LogParser = require(__dirname + "/LogParser.js");
const protobuf = require(__dirname + "/../protobuf-js-messages");
const Payables = require(__dirname + "/Payables.js");

const WETH9 = artifacts.require("WETH9");
const EscrowFactory = artifacts.require("EscrowFactory");
const NUTSToken = artifacts.require("NUTSToken");
const Config = artifacts.require("Config");
const InstrumentManagerFactory = artifacts.require("InstrumentManagerFactory");
const InstrumentRegistry = artifacts.require("InstrumentRegistry");
const PriceOracle = artifacts.require("PriceOracle");
const BorrowingInstrument = artifacts.require("BorrowingInstrument");
const BorrowingIssuance = artifacts.require("BorrowingIssuance");
const ERC20Mock = artifacts.require("ERC20Mock");
const InstrumentManager = artifacts.require("InstrumentManager");
const InstrumentEscrow = artifacts.require("InstrumentEscrow");
const IssuanceEscrow = artifacts.require("IssuanceEscrow");
const InstrumentEscrowInterface = artifacts.require('InstrumentEscrowInterface');
const IssuanceEscrowInterface = artifacts.require('IssuanceEscrowInterface');

let collateralToken;
let borrowingToken;
let instrumentManagerAddress;
let instrumentEscrowAddress;
let borrowing;
let instrumentManager;
let instrumentEscrow;
let weth9;

function getAbis() {
  return [].concat(BorrowingInstrument.abi, BorrowingIssuance.abi, ERC20Mock.abi, IssuanceEscrow.abi, InstrumentEscrow.abi, InstrumentManager.abi);
}

contract('Borrowing', ([owner, proxyAdmin, timerOracle, fsp, maker1, taker1, maker2, taker2, maker3, taker3]) => {
  beforeEach(async () => {
    weth9 = await WETH9.new();
    const escrowFactory = await EscrowFactory.new();
    const nutsToken = await NUTSToken.new(20000);
    const config = await Config.new(weth9.address, escrowFactory.address, nutsToken.address, 0);
    const instrumentRegistry = await InstrumentRegistry.new(config.address);

    // Deploy Instrument Manager Factory.
    const instrumentManagerFactory = await InstrumentManagerFactory.new();
    await config.setInstrumentManagerFactory(web3.utils.fromAscii("v2.5"), instrumentManagerFactory.address);

    // Deploy the Price Oracle.
    const priceOracle = await PriceOracle.new();

    // Deploy Borrowing Instrument.
    const borrowingIssuance = await BorrowingIssuance.new();
    const borrowingInstrument = await BorrowingInstrument.new(false, false, priceOracle.address, borrowingIssuance.address);
    console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
    await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), borrowingInstrument.address,
      web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));

    borrowingToken = await ERC20Mock.new(18);
    collateralToken = await ERC20Mock.new(18);
    console.log("Borrowing token address:" + borrowingToken.address);
    console.log("Collateral token address:" + collateralToken.address);
    await priceOracle.setRate(borrowingToken.address, collateralToken.address, 1, 100);
    await priceOracle.setRate(collateralToken.address, borrowingToken.address, 100, 1);
    instrumentManagerAddress = await instrumentRegistry.getInstrumentManager(1);
    instrumentManager = await InstrumentManager.at(instrumentManagerAddress);
    instrumentEscrowAddress = await instrumentManager.getInstrumentEscrow();
    console.log('Borrowing instrument manager address: ' + instrumentManagerAddress);
    console.log('Borrowing instrument escrow address: ' + instrumentEscrowAddress);

    instrumentEscrow = await InstrumentEscrow.at(instrumentEscrowAddress);
    console.log("maker1: " + maker1);
    console.log("taker1: " + taker1);
  }),
  it('invalid parameters', async () => {
    await collateralToken.transfer(maker1, 2000000);
    await collateralToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 2000000, {from: maker1});

    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, '0x0000000000000000000000000000000000000000', collateralToken.address, 0, 15000, 20, 10000]);
    await expectRevert(instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1}), 'BorrowingIssuance: Borrowing token not set.');

    borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, '0x0000000000000000000000000000000000000000', 20000, 15000, 1, 10000]);
    await expectRevert(instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1}), 'BorrowingIssuance: Collateral token not set.');

    borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [1296000, borrowingToken.address, collateralToken.address, 20000, 15000, 1, 10000]);
    await expectRevert(instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1}), 'BorrowingIssuance: Invalid duration.');

    borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, collateralToken.address,
        borrowingToken.address, 0, 15000, 20, 10000]);
    await expectRevert(instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1}), 'Borrowing amount not set');

    borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, collateralToken.address,
        borrowingToken.address, 20000, 1, 15000, 10000]);
    await expectRevert(instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1}), 'BorrowingIssuance: Invalid tenor days.');

    borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, collateralToken.address,
        borrowingToken.address, 20000, 91, 15000, 10000]);
    await expectRevert(instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1}), 'BorrowingIssuance: Invalid tenor days.');

    borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, collateralToken.address,
        borrowingToken.address, 20000, 20, 4999, 10000]);
    await expectRevert(instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1}), 'BorrowingIssuance: Invalid collateral ratio.');

    borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, collateralToken.address,
        borrowingToken.address, 20000, 20, 20001, 10000]);
    await expectRevert(instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1}), 'BorrowingIssuance: Invalid collateral ratio.');

    borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, collateralToken.address,
        borrowingToken.address, 20000, 20, 15000, 9]);
    await expectRevert(instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1}), 'BorrowingIssuance: Invalid interest rate.');

    borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, collateralToken.address,
        borrowingToken.address, 20000, 20, 15000, 50001]);
    await expectRevert(instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1}), 'BorrowingIssuance: Invalid interest rate.');
  }),
  it('valid parameters but insufficient fund', async () => {
    await collateralToken.transfer(maker1, 1000000);
    await collateralToken.approve(instrumentEscrowAddress, 1000000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 1000000, {from: maker1});

    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, collateralToken.address, 10000, 20, 20000, 10000]);
    await expectRevert(instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1}), 'Insufficient collateral balance');
  }),
  it('valid parameters', async () => {
    let abis = getAbis();
    await collateralToken.transfer(maker1, 2000000);
    await collateralToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 2000000, {from: maker1});
    assert.equal(2000000, await instrumentEscrow.getTokenBalance(maker1, collateralToken.address));

    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, collateralToken.address, 10000, 20, 20000, 10000]);
    let createdIssuance = await instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1});
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);

    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);
    let issuance = await BorrowingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    let payables = properties.getPayablesList();
    let issuanceDueTimestamp = properties.getIssuanceduetimestamp().toNumber();
    let payablesJson = [
      {
        payableId: 1,
        engagementId: 0,
        obligatorAddress: issuanceEscrowAddress,
        claimorAddress: maker1,
        tokenAddress: collateralToken.address,
        amount: 2000000,
        payableDueTimestamp: issuanceDueTimestamp
      }
    ];
    assert.equal(1, payables.length);
    payablesJson.forEach((json) => assert.ok(Payables.searchPayables(payables, json).length > 0));
    assert.equal(2, properties.getIssuancestate());
    assert.equal(0, await instrumentEscrow.getTokenBalance(maker1, collateralToken.address));
    assert.equal(2000000, await issuanceEscrow.getTokenBalance(maker1, collateralToken.address));
    let receipt = {logs: events};
    expectEvent(receipt, 'IssuanceCreated', {
      issuanceId: new BN(1),
      makerAddress: maker1,
      issuanceDueTimestamp: issuanceDueTimestamp.toString()
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '0',
      transferType: '0',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: collateralToken.address,
      amount: '2000000'
    });
    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '0',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: collateralToken.address,
      amount: '2000000'
    });

    expectEvent(receipt, 'PayableCreated', {
      issuanceId: '1',
      itemId: '1',
      engagementId: '0',
      obligatorAddress: issuanceEscrowAddress,
      claimorAddress: maker1,
      tokenAddress: collateralToken.address,
      amount: '2000000',
      dueTimestamp: issuanceDueTimestamp.toString()
    });
  }),
  it('engage borrowing', async () => {
    let abis = getAbis();

    await collateralToken.transfer(maker1, 2000000);
    await collateralToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 2000000, {from: maker1});

    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, collateralToken.address, 10000, 20, 20000, 10000]);
    let createdIssuance = await instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1});
    let createdIssuanceEvents = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    // Deposit collateral tokens to borrowing Instrument Escrow
    await borrowingToken.transfer(taker1, 20000);
    await borrowingToken.approve(instrumentEscrowAddress, 20000, {from: taker1});
    await instrumentEscrow.depositToken(borrowingToken.address, 20000, {from: taker1});
    assert.equal(20000, await instrumentEscrow.getTokenBalance(taker1, borrowingToken.address));

    let engageIssuance = await instrumentManager.engageIssuance(1, '0x0', {from: taker1});
    let engageIssuanceEvents = LogParser.logParser(engageIssuance.receipt.rawLogs, abis);
    assert.equal(10000, await instrumentEscrow.getTokenBalance(maker1, borrowingToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(taker1, borrowingToken.address));

    let issuance = await BorrowingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    let payables = properties.getPayablesList();
    let issuanceDueTimestamp = properties.getIssuanceduetimestamp().toNumber();
    let engagementDueTimestamp = properties.getEngagementsList()[0].getEngagementduetimestamp().toNumber();
    let payablesJson = [
      {
        payableId: 1,
        engagementId: 0,
        obligatorAddress: issuanceEscrowAddress,
        claimorAddress: maker1,
        tokenAddress: collateralToken.address,
        amount: 2000000,
        payableDueTimestamp: issuanceDueTimestamp
      },
      {
        payableId: 2,
        engagementId: 1,
        obligatorAddress: maker1,
        claimorAddress: taker1,
        tokenAddress: borrowingToken.address,
        amount: 10000,
        payableDueTimestamp: engagementDueTimestamp
      },
      {
        payableId: 3,
        engagementId: 1,
        obligatorAddress: maker1,
        claimorAddress: taker1,
        tokenAddress: borrowingToken.address,
        amount: 2000,
        payableDueTimestamp: engagementDueTimestamp
      }
    ];
    assert.equal(3, payables.length);
    payablesJson.forEach((json) => assert.ok(Payables.searchPayables(payables, json).length > 0));
    assert.equal(4, properties.getIssuancestate());
    let receipt = {logs: engageIssuanceEvents};
    expectEvent(receipt, 'EngagementCreated', {
      issuanceId: '1',
      takerAddress: taker1,
      engagementId: '1'
    });
    expectEvent(receipt, 'IssuanceComplete', {
      issuanceId: '1',
      completionRatio: '10000'
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '1',
      transferType: '3',
      fromAddress: taker1,
      toAddress: maker1,
      tokenAddress: borrowingToken.address,
      amount: '10000'
    });

    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '3',
      fromAddress: taker1,
      toAddress: maker1,
      tokenAddress: borrowingToken.address,
      amount: '10000'
    });

    expectEvent(receipt, 'PayableCreated', {
      issuanceId: '1',
      itemId: '2',
      engagementId: '1',
      obligatorAddress: maker1,
      claimorAddress: taker1,
      tokenAddress: borrowingToken.address,
      amount: '10000',
      dueTimestamp: engagementDueTimestamp.toString()
    });
    expectEvent(receipt, 'PayableCreated', {
      issuanceId: '1',
      itemId: '3',
      engagementId: '1',
      obligatorAddress: maker1,
      claimorAddress: taker1,
      tokenAddress: borrowingToken.address,
      amount: '2000',
      dueTimestamp: engagementDueTimestamp.toString()
    });
  }),
  it('operations after issuance terminated', async() => {
    await collateralToken.transfer(maker1, 2000000);
    await collateralToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 2000000, {from: maker1});
    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, collateralToken.address, 10000, 20, 20000, 10000]);
    await instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1});
    await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker1});
    await expectRevert(instrumentManager.engageIssuance(1, [], {from: taker1}), "Issuance not Engageable");
    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("repay_full"), web3.utils.fromAscii(""), {from: maker1}), "Issuance not complete");
  }),
  it('cancel borrowing', async () => {
    let abis = getAbis();

    await collateralToken.transfer(maker1, 2000000);
    await collateralToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 2000000, {from: maker1});

    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, collateralToken.address, 10000, 20, 20000, 10000]);
    let createdIssuance = await instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1});
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    let cancelIssuance = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker1});
    let cancelIssuanceEvents = LogParser.logParser(cancelIssuance.receipt.rawLogs, abis);

    let issuance = await BorrowingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));

    let payables = properties.getPayablesList();
    let issuanceDueTimestamp = properties.getIssuanceduetimestamp().toNumber();
    assert.equal(0, payables.length);
    assert.equal(3, properties.getIssuancestate());
    assert.equal(2000000, await instrumentEscrow.getTokenBalance(maker1, collateralToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(maker1, collateralToken.address));

    let receipt = {logs: cancelIssuanceEvents};
    expectEvent(receipt, 'IssuanceCancelled', {
      issuanceId: new BN(1)
    });

    expectEvent(receipt, 'PayablePaid', {
      issuanceId: '1',
      itemId: '1'
    });

    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '1',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: collateralToken.address,
      amount: '2000000'
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '0',
      transferType: '1',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: collateralToken.address,
      amount: '2000000'
    });
  }),
  it('cancel borrowing not engageable', async () => {
    let abis = getAbis();
    await collateralToken.transfer(maker1, 2000000);
    await collateralToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 2000000, {from: maker1});

    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, collateralToken.address, 10000, 20, 20000, 10000]);
    let createdIssuance = await instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1});
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    // Deposit borrowing tokens to Borrowing Instrument Escrow
    await borrowingToken.transfer(taker1, 20000);
    await borrowingToken.approve(instrumentEscrowAddress, 20000, {from: taker1});
    await instrumentEscrow.depositToken(borrowingToken.address, 20000, {from: taker1});
    // Engage borrowing issuance
    await instrumentManager.engageIssuance(1, '0x0', {from: taker1});
    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker1}), 'Cancel issuance not engageable');
  }),
  it('cancel borrowing not from maker', async () => {
    let abis = getAbis();

    await collateralToken.transfer(maker1, 2000000);
    await collateralToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 2000000, {from: maker1});

    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, collateralToken.address, 10000, 20, 20000, 10000]);
    let createdIssuance = await instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1});
    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker2}), 'Only maker can cancel issuance');
  }),
  it('repaid successful', async () => {
    let abis = getAbis();

    await collateralToken.transfer(maker1, 2000000);
    await collateralToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 2000000, {from: maker1});

    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, collateralToken.address, 10000, 20, 20000, 10000]);
    let createdIssuance = await instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1});
    let createdIssuanceEvents = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    // Deposit collateral tokens to borrowing Instrument Escrow
    await borrowingToken.transfer(taker1, 20000);
    await borrowingToken.approve(instrumentEscrowAddress, 20000, {from: taker1});
    await instrumentEscrow.depositToken(borrowingToken.address, 20000, {from: taker1});
    assert.equal(20000, await instrumentEscrow.getTokenBalance(taker1, borrowingToken.address));

    await instrumentManager.engageIssuance(1, '0x0', {from: taker1});
    assert.equal(10000, await instrumentEscrow.getTokenBalance(maker1, borrowingToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(taker1, borrowingToken.address));

    await borrowingToken.transfer(maker1, 2000);
    await borrowingToken.approve(instrumentEscrowAddress, 2000, {from: maker1});
    await instrumentEscrow.depositToken(borrowingToken.address, 2000, {from: maker1});
    assert.equal(12000, await instrumentEscrow.getTokenBalance(maker1, borrowingToken.address));
    let repay = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("repay_full"), web3.utils.fromAscii(""), {from: maker1});
    let repayEvents = LogParser.logParser(repay.receipt.rawLogs, abis);
    let issuance = await BorrowingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    let borrowingEngagementProperty = protobuf.BorrowingData.BorrowingEngagementProperty.deserializeBinary(Buffer.from(properties.getEngagementsList()[0].getEngagementcustomproperty_asB64(), 'base64'));
    let payables = properties.getPayablesList();
    let issuanceDueTimestamp = properties.getIssuanceduetimestamp().toNumber();
    let engagementDueTimestamp = properties.getEngagementsList()[0].getEngagementduetimestamp().toNumber();
    assert.equal(0, payables.length);
    assert.equal(4, properties.getIssuancestate());
    assert.equal(2, borrowingEngagementProperty.getLoanstate());

    assert.equal(0, await instrumentEscrow.getTokenBalance(maker1, borrowingToken.address));
    assert.equal(22000, await instrumentEscrow.getTokenBalance(taker1, borrowingToken.address));
    assert.equal(2000000, await instrumentEscrow.getTokenBalance(maker1, collateralToken.address));
    assert.equal(0, await instrumentEscrow.getTokenBalance(taker1, collateralToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(taker1, borrowingToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(maker1, borrowingToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(taker1, collateralToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(maker1, collateralToken.address));

    let receipt = {logs: repayEvents};
    expectEvent(receipt, 'EngagementComplete', {
      issuanceId: new BN(1)
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '1',
      transferType: '3',
      fromAddress: maker1,
      toAddress: taker1,
      tokenAddress: borrowingToken.address,
      amount: '10000'
    });
    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '1',
      transferType: '3',
      fromAddress: maker1,
      toAddress: taker1,
      tokenAddress: borrowingToken.address,
      amount: '2000'
    });
    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '1',
      transferType: '1',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: collateralToken.address,
      amount: '2000000'
    });

    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '3',
      fromAddress: maker1,
      toAddress: taker1,
      tokenAddress: borrowingToken.address,
      amount: '12000'
    });
    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '1',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: collateralToken.address,
      amount: '2000000'
    });

    expectEvent(receipt, 'PayablePaid', {
      issuanceId: '1',
      itemId: '1'
    });
    expectEvent(receipt, 'PayablePaid', {
      issuanceId: '1',
      itemId: '2'
    });
    expectEvent(receipt, 'PayablePaid', {
      issuanceId: '1',
      itemId: '3'
    });
  }),
  it('repaid not engaged', async () => {
    await collateralToken.transfer(maker1, 2000000);
    await collateralToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 2000000, {from: maker1});
    let abis = getAbis();

    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, collateralToken.address, 10000, 20, 20000, 10000]);
    let createdIssuance = await instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1});
    let createdIssuanceEvents = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);
    await borrowingToken.transfer(maker1, 2000);
    await borrowingToken.approve(instrumentEscrowAddress, 2000, {from: maker1});
    await instrumentEscrow.depositToken(borrowingToken.address, 2000, {from: maker1});
    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("repay_full"), web3.utils.fromAscii("")), "Issuance not complete");
  }),
  it('repaid not maker', async () => {
    await collateralToken.transfer(maker1, 2000000);
    await collateralToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 2000000, {from: maker1});
    let abis = getAbis();

    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, collateralToken.address, 10000, 20, 20000, 10000]);
    let createdIssuance = await instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1});
    let createdIssuanceEvents = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    // Deposit collateral tokens to borrowing Instrument Escrow
    await borrowingToken.transfer(taker1, 20000);
    await borrowingToken.approve(instrumentEscrowAddress, 20000, {from: taker1});
    await instrumentEscrow.depositToken(borrowingToken.address, 20000, {from: taker1});
    await instrumentManager.engageIssuance(1, '0x0', {from: taker1});
    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("repay_full"), web3.utils.fromAscii(""), {from: maker2}), "Only maker can repay");
  }),
  it('repaid not full amount', async () => {
    await collateralToken.transfer(maker1, 2200000);
    await collateralToken.approve(instrumentEscrowAddress, 2200000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 2200000, {from: maker1});
    let abis = getAbis();

    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, collateralToken.address, 10000, 20, 20000, 10000]);
    let createdIssuance = await instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1});
    let createdIssuanceEvents = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    // Deposit collateral tokens to borrowing Instrument Escrow
    await borrowingToken.transfer(taker1, 20000);
    await borrowingToken.approve(instrumentEscrowAddress, 20000, {from: taker1});
    await instrumentEscrow.depositToken(borrowingToken.address, 20000, {from: taker1});
    await instrumentManager.engageIssuance(1, '0x0', {from: taker1});
    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("repay_full"), web3.utils.fromAscii(""), {from: maker1}), "Insufficient principal balance");
  }),
  it('issuance due after due date', async () => {
    let abis = getAbis();

    await collateralToken.transfer(maker1, 2000000);
    await collateralToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 2000000, {from: maker1});

    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, collateralToken.address, 10000, 20, 20000, 10000]);
    let createdIssuance = await instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1});
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    await web3.currentProvider.send({jsonrpc: 2.0, method: 'evm_increaseTime', params: [8640000], id: 1}, (err, result) => { console.log(err, result)});
    let notifyEngagementDue = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("issuance_due"), web3.utils.fromAscii(""), {from: maker1});
    let issuance = await BorrowingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    let payables = properties.getPayablesList();
    assert.equal(0, payables.length);
    assert.equal(4, properties.getIssuancestate());
    assert.equal(0, properties.getCompletionratio().toNumber());

    let notifyEngagementDueEvents = LogParser.logParser(notifyEngagementDue.receipt.rawLogs, abis);
    let receipt = {logs: notifyEngagementDueEvents};

    expectEvent(receipt, 'IssuanceComplete', {
      issuanceId: new BN(1),
      completionRatio: '0'
    });

    expectEvent(receipt, 'PayablePaid', {
      issuanceId: '1',
      itemId: '1'
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '0',
      transferType: '1',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: collateralToken.address,
      amount: '2000000'
    });

    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '1',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: collateralToken.address,
      amount: '2000000'
    });
    assert.equal(2000000, await instrumentEscrow.getTokenBalance(maker1, collateralToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(maker1, collateralToken.address));
  }),
  it('issuance due after engaged', async () => {
    await collateralToken.transfer(maker1, 2000000);
    await collateralToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 2000000, {from: maker1});

    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, collateralToken.address, 10000, 20, 20000, 10000]);
    let createdIssuance = await instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1});

    await borrowingToken.transfer(taker1, 20000);
    await borrowingToken.approve(instrumentEscrowAddress, 20000, {from: taker1});
    await instrumentEscrow.depositToken(borrowingToken.address, 20000, {from: taker1});
    await instrumentManager.engageIssuance(1, '0x0', {from: taker1});
    let notifyEngagementDue = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("issuance_due"), web3.utils.fromAscii(""), {from: maker1});
    let issuance = await BorrowingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    assert.equal(4, properties.getIssuancestate());
    assert.equal(10000, properties.getCompletionratio().toNumber());
  }),
  it('issuance due before due date', async () => {
    await collateralToken.transfer(maker1, 2000000);
    await collateralToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 2000000, {from: maker1});

    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, collateralToken.address, 10000, 20, 20000, 10000]);
    let createdIssuance = await instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1});
    let notifyEngagementDue = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("engagement_due"), web3.utils.fromAscii(""), {from: maker1});
    let issuance = await BorrowingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    assert.equal(2, properties.getIssuancestate());
  }),
  it('borrowing due after engaged', async () => {
    let abis = getAbis();

    await collateralToken.transfer(maker1, 2000000);
    await collateralToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(collateralToken.address, 2000000, {from: maker1});

    let borrowingMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [100000, borrowingToken.address, collateralToken.address, 10000, 20, 20000, 10000]);
    let createdIssuance = await instrumentManager.createIssuance(borrowingMakerParameters, {from: maker1});
    let createdIssuanceEvents = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    await borrowingToken.transfer(taker1, 20000);
    await borrowingToken.approve(instrumentEscrowAddress, 20000, {from: taker1});
    await instrumentEscrow.depositToken(borrowingToken.address, 20000, {from: taker1});
    await instrumentManager.engageIssuance(1, '0x0', {from: taker1});
    await web3.currentProvider.send({jsonrpc: 2.0, method: 'evm_increaseTime', params: [8640000], id: 1}, (err, result) => { console.log(err, result)});
    let notifyborrowingDue = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("engagement_due"), web3.utils.fromAscii(""), {from: maker1});
    let notifyborrowingDueEvents = LogParser.logParser(notifyborrowingDue.receipt.rawLogs, abis);
    let issuance = await BorrowingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    let payables = properties.getPayablesList();
    let issuanceDueTimestamp = properties.getIssuanceduetimestamp().toNumber();
    let engagementDueTimestamp = properties.getEngagementsList()[0].getEngagementduetimestamp().toNumber();
    let borrowingEngagementProperty = protobuf.BorrowingData.BorrowingEngagementProperty.deserializeBinary(Buffer.from(properties.getEngagementsList()[0].getEngagementcustomproperty_asB64(), 'base64'));
    assert.equal(0, payables.length);
    assert.equal(4, properties.getIssuancestate());
    assert.equal(3, borrowingEngagementProperty.getLoanstate());

    assert.equal(2000000, await instrumentEscrow.getTokenBalance(taker1, collateralToken.address));
    assert.equal(0, await instrumentEscrow.getTokenBalance(maker1, collateralToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(maker1, collateralToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(taker1, collateralToken.address));

    let receipt = {logs: notifyborrowingDueEvents};
    expectEvent(receipt, 'EngagementComplete', {
      issuanceId: new BN(1),
      engagementId: '1'
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '1',
      transferType: '1',
      fromAddress: maker1,
      toAddress: taker1,
      tokenAddress: collateralToken.address,
      amount: '2000000'
    });

    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '1',
      fromAddress: maker1,
      toAddress: taker1,
      tokenAddress: collateralToken.address,
      amount: '2000000'
    });

    expectEvent(receipt, 'PayablePaid', {
      issuanceId: '1',
      itemId: '1'
    });
    expectEvent(receipt, 'PayableDue', {
      issuanceId: '1',
      itemId: '2'
    });
    expectEvent(receipt, 'PayableDue', {
      issuanceId: '1',
      itemId: '3'
    });
  })
});
