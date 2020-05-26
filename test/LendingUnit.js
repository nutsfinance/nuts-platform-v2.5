const { BN, constants, balance, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const assert = require('assert');
const SolidityEvent = require("web3");
const LogParser = require(__dirname + "/LogParser.js");
const Payables = require(__dirname + "/Payables.js");
const protobuf = require(__dirname + "/../protobuf-js-messages");
const custodianAddress = "0xDbE7A2544eeFfec81A7D898Ac08075e0D56FEac6";

const WETH9 = artifacts.require("WETH9");
const EscrowFactory = artifacts.require("EscrowFactory");
const NUTSToken = artifacts.require("NUTSToken");
const Config = artifacts.require("Config");
const InstrumentManagerFactory = artifacts.require("InstrumentManagerFactory");
const InstrumentRegistry = artifacts.require("InstrumentRegistry");
const PriceOracleMock = artifacts.require("PriceOracleMock");
const LendingInstrument = artifacts.require("LendingInstrument");
const LendingIssuance = artifacts.require("LendingIssuance");
const ERC20Mock = artifacts.require("ERC20Mock");
const InstrumentManager = artifacts.require("InstrumentManager");
const InstrumentEscrow = artifacts.require("InstrumentEscrow");
const IssuanceEscrow = artifacts.require("IssuanceEscrow");
const InstrumentEscrowInterface = artifacts.require('InstrumentEscrowInterface');
const IssuanceEscrowInterface = artifacts.require('IssuanceEscrowInterface');

let collateralToken;
let lendingToken;
let instrumentManagerAddress;
let instrumentEscrowAddress;
let lending;
let instrumentManager;
let instrumentEscrow;
let weth9;

function getAbis() {
  return [].concat(LendingInstrument.abi, LendingIssuance.abi, ERC20Mock.abi, IssuanceEscrow.abi, InstrumentEscrow.abi, InstrumentManager.abi);
}

contract('Lending', ([owner, proxyAdmin, timerOracle, fsp, maker1, taker1, maker2, taker2, maker3, taker3]) => {
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
    const priceOracle = await PriceOracleMock.new();

    // Deploy Lending Instrument.
    const lendingIssuance = await LendingIssuance.new();
    const lendingInstrument = await LendingInstrument.new(false, false, priceOracle.address, lendingIssuance.address);
    console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
    await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), lendingInstrument.address,
      web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));

    lendingToken = await ERC20Mock.new();
    collateralToken = await ERC20Mock.new();
    console.log("Lending token address:" + lendingToken.address);
    console.log("Collateral token address:" + collateralToken.address);
    await priceOracle.setRate(lendingToken.address, collateralToken.address, 1, 100);
    await priceOracle.setRate(collateralToken.address, lendingToken.address, 100, 1);
    instrumentManagerAddress = await instrumentRegistry.getInstrumentManager(1);
    instrumentManager = await InstrumentManager.at(instrumentManagerAddress);
    instrumentEscrowAddress = await instrumentManager.getInstrumentEscrow();
    console.log('Lending instrument manager address: ' + instrumentManagerAddress);
    console.log('Lending instrument escrow address: ' + instrumentEscrowAddress);

    instrumentEscrow = await InstrumentEscrow.at(instrumentEscrowAddress);
    console.log("maker1: " + maker1);
    console.log("taker1: " + taker1);
  }),
  it('invalid parameters', async () => {
    await lendingToken.transfer(maker1, 20000);
    await lendingToken.approve(instrumentEscrowAddress, 20000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 20000, {from: maker1});

    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      ['0x0000000000000000000000000000000000000000', collateralToken.address, 0, 15000, 20, 10000]);
    await expectRevert(instrumentManager.createIssuance(lendingMakerParameters, {from: maker1}), 'LendingIssuance: Lending token not set.');

    lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'], [lendingToken.address,
        '0x0000000000000000000000000000000000000000', 20000, 15000, 1, 10000]);
    await expectRevert(instrumentManager.createIssuance(lendingMakerParameters, {from: maker1}), 'LendingIssuance: Collateral token not set.');

    lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [collateralToken.address,
        lendingToken.address, 0, 15000, 20, 10000]);
    await expectRevert(instrumentManager.createIssuance(lendingMakerParameters, {from: maker1}), 'Lending amount not set');

    lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [collateralToken.address,
        lendingToken.address, 20000, 1, 15000, 10000]);
    await expectRevert(instrumentManager.createIssuance(lendingMakerParameters, {from: maker1}), 'LendingIssuance: Invalid tenor days.');

    lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [collateralToken.address,
        lendingToken.address, 20000, 91, 15000, 10000]);
    await expectRevert(instrumentManager.createIssuance(lendingMakerParameters, {from: maker1}), 'LendingIssuance: Invalid tenor days.');

    lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [collateralToken.address,
        lendingToken.address, 20000, 20, 4999, 10000]);
    await expectRevert(instrumentManager.createIssuance(lendingMakerParameters, {from: maker1}), 'LendingIssuance: Invalid collateral ratio.');

    lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [collateralToken.address,
        lendingToken.address, 20000, 20, 20001, 10000]);
    await expectRevert(instrumentManager.createIssuance(lendingMakerParameters, {from: maker1}), 'LendingIssuance: Invalid collateral ratio.');

    lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [collateralToken.address,
        lendingToken.address, 20000, 20, 15000, 9]);
    await expectRevert(instrumentManager.createIssuance(lendingMakerParameters, {from: maker1}), 'LendingIssuance: Invalid interest rate.');

    lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [collateralToken.address,
        lendingToken.address, 20000, 20, 15000, 50001]);
    await expectRevert(instrumentManager.createIssuance(lendingMakerParameters, {from: maker1}), 'LendingIssuance: Invalid interest rate.');
  }),
  it('valid parameters but insufficient fund', async () => {
    await lendingToken.transfer(maker1, 20000);
    await lendingToken.approve(instrumentEscrowAddress, 20000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 20000, {from: maker1});

    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [lendingToken.address, collateralToken.address, '25000', '20', '15000', '10000']);
    await expectRevert(instrumentManager.createIssuance(lendingMakerParameters, {from: maker1}), 'LendingIssuance: Insufficient principal balance.');
  }),
  it('valid parameters', async () => {
    let abis = getAbis();
    await lendingToken.transfer(maker1, 20000);
    await lendingToken.approve(instrumentEscrowAddress, 20000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 20000, {from: maker1});
    assert.equal(20000, await instrumentEscrow.getTokenBalance(maker1, lendingToken.address));

    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [lendingToken.address, collateralToken.address, '20000', '20', '15000', '10000']);
    let createdIssuance = await instrumentManager.createIssuance(lendingMakerParameters, {from: maker1});

    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);
    let issuance = await LendingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    assert.equal(2, properties.getIssuancestate());
    let payables = properties.getPayablesList();
    let issuanceDueTimestamp = properties.getIssuanceduetimestamp().toNumber();
    let payablesJson = [
      {
        payableId: 1,
        engagementId: 0,
        obligatorAddress: issuanceEscrowAddress,
        claimorAddress: maker1,
        tokenAddress: lendingToken.address,
        amount: 20000,
        payableDueTimestamp: issuanceDueTimestamp,
      }
    ];
    assert.equal(1, payables.length);
    payablesJson.forEach((json) => assert.ok(Payables.searchPayables(payables, json).length > 0));
    assert.equal(0, await instrumentEscrow.getTokenBalance(maker1, lendingToken.address));

    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let receipt = {logs: events};
    assert.equal(20000, await issuanceEscrow.getTokenBalance(maker1, lendingToken.address));
    expectEvent(receipt, 'IssuanceCreated', {
      issuanceId: new BN(1),
      makerAddress: maker1,
      issuanceDueTimestamp: issuanceDueTimestamp.toString()
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '0',
      transferType: '1',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: lendingToken.address,
      amount: '20000'
    });
    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '1',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: lendingToken.address,
      amount: '20000'
    });

    expectEvent(receipt, 'PayableCreated', {
      issuanceId: '1',
      itemId: '1',
      engagementId: '0',
      obligatorAddress: issuanceEscrowAddress,
      claimorAddress: maker1,
      tokenAddress: lendingToken.address,
      amount: '20000',
      dueTimestamp: issuanceDueTimestamp.toString()
    });
  }),
  it('engage lending', async () => {
    let abis = getAbis();
    await lendingToken.transfer(maker1, 20000);
    await lendingToken.approve(instrumentEscrowAddress, 20000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 20000, {from: maker1});

    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [lendingToken.address, collateralToken.address, '20000', '20', '15000', '10000']);
    let createdIssuance = await instrumentManager.createIssuance(lendingMakerParameters, {from: maker1});
    let createdIssuanceEvents = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    // Deposit collateral tokens to Lending Instrument Escrow
    await collateralToken.transfer(taker1, 4000000);
    await collateralToken.approve(instrumentEscrowAddress, 4000000, {from: taker1});
    await instrumentEscrow.depositToken(collateralToken.address, 4000000, {from: taker1});
    assert.equal(4000000, await instrumentEscrow.getTokenBalance(taker1, collateralToken.address));
    let engageIssuance = await instrumentManager.engageIssuance(1, '0x0', {from: taker1});
    assert.equal(1000000, await instrumentEscrow.getTokenBalance(taker1, collateralToken.address));
    assert.equal(20000, await instrumentEscrow.getTokenBalance(taker1, lendingToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(maker1, lendingToken.address));
    assert.equal(3000000, await issuanceEscrow.getTokenBalance(taker1, collateralToken.address));

    let issuance = await LendingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));

    let payables = properties.getPayablesList();
    let issuanceDueTimestamp = properties.getIssuanceduetimestamp().toNumber();
    let engagementDueTimestamp = properties.getEngagementsList()[0].getEngagementduetimestamp().toNumber();
    let payablesJson = [
      {
        payableId: 2,
        engagementId: 1,
        obligatorAddress: issuanceEscrowAddress,
        claimorAddress: taker1,
        tokenAddress: collateralToken.address,
        amount: 3000000,
        payableDueTimestamp: engagementDueTimestamp
      },
      {
        payableId: 3,
        engagementId: 1,
        obligatorAddress: taker1,
        claimorAddress: maker1,
        tokenAddress: lendingToken.address,
        amount: 20000,
        payableDueTimestamp: engagementDueTimestamp
      },
      {
        payableId: 4,
        engagementId: 1,
        obligatorAddress: taker1,
        claimorAddress: maker1,
        tokenAddress: lendingToken.address,
        amount: 4000,
        payableDueTimestamp: engagementDueTimestamp
      }
    ];
    assert.equal(4, properties.getIssuancestate());
    assert.equal(10000, properties.getCompletionratio().toNumber());
    assert.equal(3, payables.length);
    payablesJson.forEach((json) => assert.ok(Payables.searchPayables(payables, json).length > 0));

    let events = LogParser.logParser(engageIssuance.receipt.rawLogs, abis);
    let receipt = {logs: events};
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
      transferType: '1',
      fromAddress: taker1,
      toAddress: taker1,
      tokenAddress: collateralToken.address,
      amount: '3000000'
    });
    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '1',
      transferType: '2',
      fromAddress: maker1,
      toAddress: taker1,
      tokenAddress: lendingToken.address,
      amount: '20000'
    });

    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '1',
      fromAddress: taker1,
      toAddress: taker1,
      tokenAddress: collateralToken.address,
      amount: '3000000'
    });
    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '2',
      fromAddress: maker1,
      toAddress: taker1,
      tokenAddress: lendingToken.address,
      amount: '20000'
    });

    expectEvent(receipt, 'PayableCreated', {
      issuanceId: '1',
      itemId: '2',
      engagementId: '1',
      obligatorAddress: issuanceEscrowAddress,
      claimorAddress: taker1,
      tokenAddress: collateralToken.address,
      amount: '3000000',
      dueTimestamp: engagementDueTimestamp.toString()
    });
    expectEvent(receipt, 'PayableCreated', {
      issuanceId: '1',
      itemId: '3',
      engagementId: '1',
      obligatorAddress: taker1,
      claimorAddress: maker1,
      tokenAddress: lendingToken.address,
      amount: '20000',
      dueTimestamp: engagementDueTimestamp.toString()
    });
    expectEvent(receipt, 'PayableCreated', {
      issuanceId: '1',
      itemId: '4',
      engagementId: '1',
      obligatorAddress: taker1,
      claimorAddress: maker1,
      tokenAddress: lendingToken.address,
      amount: '4000',
      dueTimestamp: engagementDueTimestamp.toString()
    });
    expectEvent(receipt, 'PayableReinitiated', {
      issuanceId: '1',
      itemId: '1',
      reinitiatedTo: '3'
    });
  }),
  it('operations after issuance terminated', async() => {
    await lendingToken.transfer(maker1, 20000);
    await lendingToken.approve(instrumentEscrowAddress, 20000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 20000, {from: maker1});
    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [lendingToken.address, collateralToken.address, '20000', '20', '15000', '10000']);
    await instrumentManager.createIssuance(lendingMakerParameters, {from: maker1});
    await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker1});
    await expectRevert(instrumentManager.engageIssuance(1, [], {from: taker1}), "Issuance not Engageable");
    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("repay_full"), web3.utils.fromAscii(""), {from: maker1}), "Issuance not complete");
  }),
  it('cancel lending', async () => {
    let abis = getAbis();
    await lendingToken.transfer(maker1, 20000);
    await lendingToken.approve(instrumentEscrowAddress, 20000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 20000, {from: maker1});

    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [lendingToken.address, collateralToken.address, '20000', '20', '15000', '10000']);
    let createdIssuance = await instrumentManager.createIssuance(lendingMakerParameters, {from: maker1});
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    let cancelIssuance = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker1});

    let issuance = await LendingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    let payables = properties.getPayablesList();
    let issuanceDueTimestamp = properties.getIssuanceduetimestamp().toNumber();
    assert.equal(0, payables.length);
    assert.equal(3, properties.getIssuancestate());

    let cancelIssuanceEvents = LogParser.logParser(cancelIssuance.receipt.rawLogs, abis);
    let receipt = {logs: cancelIssuanceEvents};

    assert.equal(20000, await instrumentEscrow.getTokenBalance(maker1, lendingToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(maker1, lendingToken.address));

    expectEvent(receipt, 'IssuanceCancelled', {
      issuanceId: new BN(1)
    });

    expectEvent(receipt, 'PayablePaid', {
      issuanceId: '1',
      itemId: '1'
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '0',
      transferType: '2',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: lendingToken.address,
      amount: '20000'
    });

    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '2',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: lendingToken.address,
      amount: '20000'
    });
  }),
  it('cancel lending not engageable', async () => {
    await lendingToken.transfer(maker1, 20000);
    await lendingToken.approve(instrumentEscrowAddress, 20000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 20000, {from: maker1});
    let abis = getAbis();

    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [lendingToken.address, collateralToken.address, '20000', '20', '15000', '10000']);
    let createdIssuance = await instrumentManager.createIssuance(lendingMakerParameters, {from: maker1});
    let createdIssuanceEvents = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    // Deposit collateral tokens to Lending Instrument Escrow
    await collateralToken.transfer(taker1, 4000000);
    await collateralToken.approve(instrumentEscrowAddress, 4000000, {from: taker1});
    await instrumentEscrow.depositToken(collateralToken.address, 4000000, {from: taker1});
    await instrumentManager.engageIssuance(1, '0x0', {from: taker1});
    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker1}), 'Cancel issuance not engageable');
  }),
  it('cancel lending not from maker', async () => {
    await lendingToken.transfer(maker1, 20000);
    await lendingToken.approve(instrumentEscrowAddress, 20000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 20000, {from: maker1});
    let abis = getAbis();

    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [lendingToken.address, collateralToken.address, '20000', '20', '15000', '10000']);
    let createdIssuance = await instrumentManager.createIssuance(lendingMakerParameters, {from: maker1});
    let createdIssuanceEvents = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);
    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker2}), 'Only maker can cancel issuance');
  }),
  it('repaid successful', async () => {
    let abis = getAbis();
    await lendingToken.transfer(maker1, 20000);
    await lendingToken.approve(instrumentEscrowAddress, 20000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 20000, {from: maker1});

    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [lendingToken.address, collateralToken.address, '20000', '20', '15000', '10000']);
    let createdIssuance = await instrumentManager.createIssuance(lendingMakerParameters, {from: maker1});
    let createdIssuanceEvents = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    // Deposit collateral tokens to Lending Instrument Escrow
    await collateralToken.transfer(taker1, 4000000);
    await collateralToken.approve(instrumentEscrowAddress, 4000000, {from: taker1});
    await instrumentEscrow.depositToken(collateralToken.address, 4000000, {from: taker1});
    assert.equal(4000000, await instrumentEscrow.getTokenBalance(taker1, collateralToken.address));

    await instrumentManager.engageIssuance(1, '0x0', {from: taker1});
    assert.equal(1000000, await instrumentEscrow.getTokenBalance(taker1, collateralToken.address));
    assert.equal(20000, await instrumentEscrow.getTokenBalance(taker1, lendingToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(maker1, lendingToken.address));
    assert.equal(3000000, await issuanceEscrow.getTokenBalance(taker1, collateralToken.address));

    await lendingToken.transfer(taker1, 24000);
    await lendingToken.approve(instrumentEscrowAddress, 24000, {from: taker1});
    await instrumentEscrow.depositToken(lendingToken.address, 24000, {from: taker1});
    assert.equal(44000, await instrumentEscrow.getTokenBalance(taker1, lendingToken.address));

    let depositToIssuance = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("repay_full"), web3.utils.fromAscii(""), {from: taker1});
    let issuance = await LendingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    let payables = properties.getPayablesList();
    let issuanceDueTimestamp = properties.getIssuanceduetimestamp().toNumber();
    let engagementDueTimestamp = properties.getEngagementsList()[0].getEngagementduetimestamp().toNumber();
    let lendingEngagementProperty = protobuf.LendingData.LendingEngagementProperty.deserializeBinary(Buffer.from(properties.getEngagementsList()[0].getEngagementcustomproperty_asB64(), 'base64'));
    assert.equal(0, payables.length);
    assert.equal(4, properties.getIssuancestate());
    assert.equal(2, lendingEngagementProperty.getLoanstate());

    assert.equal(20000, await instrumentEscrow.getTokenBalance(taker1, lendingToken.address));
    assert.equal(24000, await instrumentEscrow.getTokenBalance(maker1, lendingToken.address));
    assert.equal(4000000, await instrumentEscrow.getTokenBalance(taker1, collateralToken.address));
    assert.equal(0, await instrumentEscrow.getTokenBalance(maker1, collateralToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(taker1, lendingToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(maker1, lendingToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(taker1, collateralToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(maker1, collateralToken.address));

    let depositToIssuanceEvents = LogParser.logParser(depositToIssuance.receipt.rawLogs, abis);
    let receipt = {logs: depositToIssuanceEvents};
    expectEvent(receipt, 'EngagementComplete', {
      issuanceId: new BN(1)
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '1',
      transferType: '4',
      fromAddress: taker1,
      toAddress: maker1,
      tokenAddress: lendingToken.address,
      amount: '20000'
    });
    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '1',
      transferType: '4',
      fromAddress: taker1,
      toAddress: maker1,
      tokenAddress: lendingToken.address,
      amount: '4000'
    });
    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '1',
      transferType: '2',
      fromAddress: taker1,
      toAddress: taker1,
      tokenAddress: collateralToken.address,
      amount: '3000000'
    });

    expectEvent(receipt, 'PayablePaid', {
      issuanceId: '1',
      itemId: '2'
    });
    expectEvent(receipt, 'PayablePaid', {
      issuanceId: '1',
      itemId: '3'
    });
    expectEvent(receipt, 'PayablePaid', {
      issuanceId: '1',
      itemId: '4'
    });

    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '4',
      fromAddress: taker1,
      toAddress: maker1,
      tokenAddress: lendingToken.address,
      amount: '24000'
    });
    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '2',
      fromAddress: taker1,
      toAddress: taker1,
      tokenAddress: collateralToken.address,
      amount: '3000000'
    });
  }),
  it('repaid not engaged', async () => {
    await lendingToken.transfer(maker1, 40000);
    await lendingToken.approve(instrumentEscrowAddress, 40000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 40000, {from: maker1});

    let abis = getAbis();

    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [lendingToken.address, collateralToken.address, '20000', '20', '15000', '10000']);
    let createdIssuance = await instrumentManager.createIssuance(lendingMakerParameters, {from: maker1});
    let createdIssuanceEvents = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);
    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("repay_full"), web3.utils.fromAscii(""), {from: maker1}), "Issuance not complete");
  }),
  it('repaid not taker', async () => {
    await lendingToken.transfer(maker1, 40000);
    await lendingToken.approve(instrumentEscrowAddress, 40000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 40000, {from: maker1});
    let abis = getAbis();

    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [lendingToken.address, collateralToken.address, '20000', '20', '15000', '10000']);
    let createdIssuance = await instrumentManager.createIssuance(lendingMakerParameters, {from: maker1});
    let createdIssuanceEvents = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    // Deposit collateral tokens to Lending Instrument Escrow
    await collateralToken.transfer(taker1, 4000000);
    await collateralToken.approve(instrumentEscrowAddress, 4000000, {from: taker1});
    await instrumentEscrow.depositToken(collateralToken.address, 4000000, {from: taker1});
    await instrumentManager.engageIssuance(1, '0x0', {from: taker1});
    await lendingToken.approve(instrumentEscrowAddress, 20000, {from: taker2});
    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("repay_full"), web3.utils.fromAscii(""), {from: maker1}), "Only taker can repay");
  }),
  it('repaid not full amount', async () => {
    await lendingToken.transfer(maker1, 20000);
    await lendingToken.approve(instrumentEscrowAddress, 20000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 20000, {from: maker1});
    let abis = getAbis();

    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [lendingToken.address, collateralToken.address, '20000', '20', '15000', '10000']);
    let createdIssuance = await instrumentManager.createIssuance(lendingMakerParameters, {from: maker1});
    let createdIssuanceEvents = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    // Deposit collateral tokens to Lending Instrument Escrow
    await collateralToken.transfer(taker1, 4000000);
    await collateralToken.approve(instrumentEscrowAddress, 4000000, {from: taker1});
    await instrumentEscrow.depositToken(collateralToken.address, 4000000, {from: taker1});
    await instrumentManager.engageIssuance(1, '0x0', {from: taker1});
    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("repay_full"), web3.utils.fromAscii(""), {from: taker1}), "Insufficient principal balance");
  }),
  it('issuance due after due date', async () => {
    let abis = getAbis();
    await lendingToken.transfer(maker1, 20000);
    await lendingToken.approve(instrumentEscrowAddress, 20000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 20000, {from: maker1});

    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [lendingToken.address, collateralToken.address, '20000', '20', '15000', '10000']);
    let createdIssuance = await instrumentManager.createIssuance(lendingMakerParameters, {from: maker1});
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);

    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);
    await web3.currentProvider.send({jsonrpc: 2.0, method: 'evm_increaseTime', params: [8640000], id: 1}, (err, result) => { console.log(err, result)});
    let notifyEngagementDue = await instrumentManager.processEvent(1, 0,  web3.utils.fromAscii("issuance_due"), web3.utils.fromAscii(""), {from: maker1});
    let issuance = await LendingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    let payables = properties.getPayablesList();
    let issuanceDueTimestamp = properties.getIssuanceduetimestamp().toNumber();
    assert.equal(0, payables.length);
    assert.equal(4, properties.getIssuancestate());
    assert.equal(0, properties.getCompletionratio().toNumber());

    let notifyEngagementDueEvents = LogParser.logParser(notifyEngagementDue.receipt.rawLogs, abis);
    let receipt = {logs: notifyEngagementDueEvents};

    expectEvent(receipt, 'IssuanceComplete', {
      issuanceId: new BN(1),
      completionRatio: '0'
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '0',
      transferType: '2',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: lendingToken.address,
      amount: '20000'
    });


    expectEvent(receipt, 'PayablePaid', {
      issuanceId: '1',
      itemId: '1'
    });

    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '2',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: lendingToken.address,
      amount: '20000'
    });
    assert.equal(20000, await instrumentEscrow.getTokenBalance(maker1, lendingToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(maker1, lendingToken.address));
  }),
  it('issuance due after engaged', async () => {
    await lendingToken.transfer(maker1, 20000);
    await lendingToken.approve(instrumentEscrowAddress, 20000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 20000, {from: maker1});

    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [lendingToken.address, collateralToken.address, '20000', '20', '15000', '10000']);
    let createdIssuance = await instrumentManager.createIssuance(lendingMakerParameters, {from: maker1});
    await collateralToken.transfer(taker1, 4000000);
    await collateralToken.approve(instrumentEscrowAddress, 4000000, {from: taker1});
    await instrumentEscrow.depositToken(collateralToken.address, 4000000, {from: taker1});
    await instrumentManager.engageIssuance(1, '0x0', {from: taker1});
    let notifyEngagementDue = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("issuance_due"), web3.utils.fromAscii(""), {from: maker1});
    let issuance = await LendingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    assert.equal(4, properties.getIssuancestate());
    assert.equal(10000, properties.getCompletionratio().toNumber());
  }),
  it('issuance due before due date', async () => {
    await lendingToken.transfer(maker1, 20000);
    await lendingToken.approve(instrumentEscrowAddress, 20000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 20000, {from: maker1});

    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [lendingToken.address, collateralToken.address, '20000', '20', '15000', '10000']);
    let createdIssuance = await instrumentManager.createIssuance(lendingMakerParameters, {from: maker1});
    let notifyEngagementDue = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("issuance_due"), web3.utils.fromAscii(""), {from: maker1});
    let issuance = await LendingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    assert.equal(2, properties.getIssuancestate());
  }),
  it('lending due after engaged', async () => {
    let abis = getAbis();
    await lendingToken.transfer(maker1, 20000);
    await lendingToken.approve(instrumentEscrowAddress, 20000, {from: maker1});
    await instrumentEscrow.depositToken(lendingToken.address, 20000, {from: maker1});

    let lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [lendingToken.address, collateralToken.address, '20000', '20', '15000', '10000']);
    let createdIssuance = await instrumentManager.createIssuance(lendingMakerParameters, {from: maker1});
    let createdIssuanceEvents = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    await collateralToken.transfer(taker1, 4000000);
    await collateralToken.approve(instrumentEscrowAddress, 4000000, {from: taker1});
    await instrumentEscrow.depositToken(collateralToken.address, 4000000, {from: taker1});
    await instrumentManager.engageIssuance(1, '0x0', {from: taker1});

    await web3.currentProvider.send({jsonrpc: 2.0, method: 'evm_increaseTime', params: [8640000], id: 1}, (err, result) => { console.log(err, result)});
    let notifyLendingDue = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("engagement_due"), web3.utils.fromAscii(""), {from: maker1});
    let issuance = await LendingIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    let payables = properties.getPayablesList();
    let issuanceDueTimestamp = properties.getIssuanceduetimestamp().toNumber();
    let engagementDueTimestamp = properties.getEngagementsList()[0].getEngagementduetimestamp().toNumber();
    let lendingEngagementProperty = protobuf.LendingData.LendingEngagementProperty.deserializeBinary(Buffer.from(properties.getEngagementsList()[0].getEngagementcustomproperty_asB64(), 'base64'));
    assert.equal(0, payables.length);
    assert.equal(4, properties.getIssuancestate());
    assert.equal(3, lendingEngagementProperty.getLoanstate());

    let notifyLendingDueEvents = LogParser.logParser(notifyLendingDue.receipt.rawLogs, abis);
    let receipt = {logs: notifyLendingDueEvents};

    assert.equal(3000000, await instrumentEscrow.getTokenBalance(maker1, collateralToken.address));
    assert.equal(1000000, await instrumentEscrow.getTokenBalance(taker1, collateralToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(maker1, collateralToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(taker1, collateralToken.address));
    expectEvent(receipt, 'EngagementComplete', {
      issuanceId: new BN(1),
      engagementId: '1'
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '1',
      transferType: '2',
      fromAddress: taker1,
      toAddress: maker1,
      tokenAddress: collateralToken.address,
      amount: '3000000'
    });

    expectEvent(receipt, 'PayablePaid', {
      issuanceId: '1',
      itemId: '2'
    });
    expectEvent(receipt, 'PayableDue', {
      issuanceId: '1',
      itemId: '3'
    });
    expectEvent(receipt, 'PayableDue', {
      issuanceId: '1',
      itemId: '4'
    });

    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '2',
      fromAddress: taker1,
      toAddress: maker1,
      tokenAddress: collateralToken.address,
      amount: '3000000'
    });
  })
});
