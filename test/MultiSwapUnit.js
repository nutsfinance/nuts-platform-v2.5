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
const PriceOracleMock = artifacts.require("PriceOracleMock");
const MultiSwapInstrument = artifacts.require("MultiSwapInstrument");
const MultiSwapIssuance = artifacts.require("MultiSwapIssuance");
const ERC20Mock = artifacts.require("ERC20Mock");
const InstrumentManager = artifacts.require("InstrumentManager");
const InstrumentEscrow = artifacts.require("InstrumentEscrow");
const IssuanceEscrow = artifacts.require("IssuanceEscrow");
const InstrumentEscrowInterface = artifacts.require('InstrumentEscrowInterface');
const IssuanceEscrowInterface = artifacts.require('IssuanceEscrowInterface');


let multiSwap;
let instrumentManagerAddress;
let instrumentManager;
let instrumentEscrowAddress;
let instrumentEscrow;
let inputToken;
let outputToken;

function getAbis() {
  return [].concat(MultiSwapInstrument.abi, MultiSwapIssuance.abi, ERC20Mock.abi, IssuanceEscrow.abi, InstrumentEscrow.abi, InstrumentManager.abi);
}

contract('MultiSwap', ([owner, proxyAdmin, timerOracle, fsp, maker1, taker1, maker2, taker2, maker3, taker3]) => {
  beforeEach(async () => {
    weth9 = await WETH9.new();
    const escrowFactory = await EscrowFactory.new();
    const nutsToken = await NUTSToken.new(20000);
    const config = await Config.new(weth9.address, escrowFactory.address, nutsToken.address, 0);
    const instrumentRegistry = await InstrumentRegistry.new(config.address);

    // Deploy Instrument Manager Factory.
    const instrumentManagerFactory = await InstrumentManagerFactory.new();
    await config.setInstrumentManagerFactory(web3.utils.fromAscii("v2.5"), instrumentManagerFactory.address);

    // Deploy MultiSwap Instrument.
    const multiSwapIssuance = await MultiSwapIssuance.new();
    const multiSwapInstrument = await MultiSwapInstrument.new(false, false, multiSwapIssuance.address);
    console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
    await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), multiSwapInstrument.address,
      web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));

    inputToken = await ERC20Mock.new(18);
    outputToken = await ERC20Mock.new(18);
    console.log("Input token address:" + inputToken.address);
    console.log("Output token address:" + outputToken.address);
    instrumentManagerAddress = await instrumentRegistry.getInstrumentManager(1);
    instrumentManager = await InstrumentManager.at(instrumentManagerAddress);
    instrumentEscrowAddress = await instrumentManager.getInstrumentEscrow();
    console.log('MultiSwap instrument manager address: ' + instrumentManagerAddress);
    console.log('MultiSwap instrument escrow address: ' + instrumentEscrowAddress);

    instrumentEscrow = await InstrumentEscrow.at(instrumentEscrowAddress);
    console.log("maker1: " + maker1);
    console.log("taker1: " + taker1);
  }),
  it('invalid parameters', async () => {
    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, '0x0000000000000000000000000000000000000000', outputToken.address, 2000000, 40000, 20, 80000]);
    await expectRevert(instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1}), 'Input token not set');

    spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, '0x0000000000000000000000000000000000000000', 2000000, 40000, 20, 80000]);
    await expectRevert(instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1}), 'Output token not set');

    spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 0, 40000, 20, 80000]);
    await expectRevert(instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1}), 'Input amount not set');

    spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 0, 20, 80000]);
    await expectRevert(instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1}), 'Output amount not set');

    spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [1296000, inputToken.address, outputToken.address, 2000000, 40000, 20, 80000]);
    await expectRevert(instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1}), 'Invalid duration');

    spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 40000, 30000]);
    await expectRevert(instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1}), 'Invalid engagement output range');

    spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 50000, 80000]);
    await expectRevert(instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1}), 'Invalid engagement output range');
  }),
  it('valid parameters but insufficient fund', async () => {
    await inputToken.transfer(maker1, 1500000);
    await inputToken.approve(instrumentEscrowAddress, 1500000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 1500000, {from: maker1});

    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 20, 80000]);
    await expectRevert(instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1}), 'Insufficient input balance');
  }),
  it('valid parameters', async () => {
    let abis = getAbis();

    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    assert.equal(2000000, await instrumentEscrow.getTokenBalance(maker1, inputToken.address));

    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 20, 80000]);
    let createdIssuance = await instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1});

    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);
    let issuance = await MultiSwapIssuance.at(await instrumentManager.getIssuance(1));
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
        tokenAddress: inputToken.address,
        amount: 2000000,
        payableDueTimestamp: issuanceDueTimestamp
      }
    ];
    assert.equal(1, payables.length);
    payablesJson.forEach((json) => assert.ok(Payables.searchPayables(payables, json).length > 0));
    assert.equal(0, await instrumentEscrow.getTokenBalance(maker1, inputToken.address));
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);

    assert.equal(2000000, await issuanceEscrow.getTokenBalance(maker1, inputToken.address));
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
      tokenAddress: inputToken.address,
      amount: '2000000'
    });
    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '0',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: inputToken.address,
      amount: '2000000'
    });

    expectEvent(receipt, 'PayableCreated', {
      issuanceId: '1',
      itemId: '1',
      engagementId: '0',
      obligatorAddress: issuanceEscrowAddress,
      claimorAddress: maker1,
      tokenAddress: inputToken.address,
      amount: '2000000',
      dueTimestamp: issuanceDueTimestamp.toString()
    });
  }),
  it('engage multiSwap half', async () => {
    let abis = getAbis();

    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 20, 80000]);
    let createdIssuance = await instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1});
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    await outputToken.transfer(taker1, 20000);
    await outputToken.approve(instrumentEscrowAddress, 20000, {from: taker1});
    await instrumentEscrow.depositToken(outputToken.address, 20000, {from: taker1});
    assert.equal(20000, await instrumentEscrow.getTokenBalance(taker1, outputToken.address));

    // Engage spot multiSwap issuance
    let engageIssuance = await instrumentManager.engageIssuance(1, web3.eth.abi.encodeParameters(['uint256'], ['20000']), {from: taker1});

    let engageIssuanceEvents = LogParser.logParser(engageIssuance.receipt.rawLogs, abis);
    let issuance = await MultiSwapIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    let payables = properties.getPayablesList();
    let issuanceDueTimestamp = properties.getIssuanceduetimestamp().toNumber();
    let engagementLists = properties.getEngagementsList();
    let payablesJson = [
      {
        payableId: 2,
        engagementId: 1,
        obligatorAddress: issuanceEscrowAddress,
        claimorAddress: maker1,
        tokenAddress: inputToken.address,
        amount: 1000000,
        payableDueTimestamp: issuanceDueTimestamp
      }
    ];
    assert.equal(1, payables.length);
    assert.equal(1, engagementLists.length);
    let customProperty = protobuf.MultiSwapData.MultiSwapEngagementProperty.deserializeBinary(Uint8Array.from(Buffer.from(engagementLists[0].getEngagementcustomproperty_asB64(), 'base64')));
    assert.equal(20000, customProperty.getOutputamount().toNumber());
    assert.equal(2, properties.getIssuancestate());
    payablesJson.forEach((json) => assert.ok(Payables.searchPayables(payables, json).length > 0));
    assert.equal(0, await instrumentEscrow.getTokenBalance(taker1, outputToken.address));
    assert.equal(1000000, await instrumentEscrow.getTokenBalance(taker1, inputToken.address));
    assert.equal(20000, await instrumentEscrow.getTokenBalance(maker1, outputToken.address));
    let receipt = {logs: engageIssuanceEvents};
    expectEvent(receipt, 'EngagementCreated', {
      issuanceId: '1',
      takerAddress: taker1,
      engagementId: '1'
    });
    expectEvent(receipt, 'EngagementComplete', {
      issuanceId: '1',
      engagementId: '1'
    });

    expectEvent(receipt, 'PayableReinitiated', {
      issuanceId: '1',
      itemId: '1',
      reinitiatedTo: '2'
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '1',
      transferType: '3',
      fromAddress: taker1,
      toAddress: maker1,
      tokenAddress: outputToken.address,
      amount: '20000'
    });
    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '1',
      transferType: '1',
      fromAddress: maker1,
      toAddress: taker1,
      tokenAddress: inputToken.address,
      amount: '1000000'
    });

    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '3',
      fromAddress: taker1,
      toAddress: maker1,
      tokenAddress: outputToken.address,
      amount: '20000'
    });
    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '1',
      fromAddress: maker1,
      toAddress: taker1,
      tokenAddress: inputToken.address,
      amount: '1000000'
    });
  }),
  it('engage multiSwap complete', async () => {
    let abis = getAbis();

    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 20, 80000]);
    let createdIssuance = await instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1});
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    await outputToken.transfer(taker1, 20000);
    await outputToken.approve(instrumentEscrowAddress, 20000, {from: taker1});
    await instrumentEscrow.depositToken(outputToken.address, 20000, {from: taker1});
    assert.equal(20000, await instrumentEscrow.getTokenBalance(taker1, outputToken.address));
    await instrumentManager.engageIssuance(1, web3.eth.abi.encodeParameters(['uint256'], ['20000']), {from: taker1});
    await outputToken.transfer(taker2, 20000);
    await outputToken.approve(instrumentEscrowAddress, 20000, {from: taker2});
    await outputToken.transfer(taker2, 20000);
    await outputToken.approve(instrumentEscrowAddress, 20000, {from: taker2});
    await instrumentEscrow.depositToken(outputToken.address, 20000, {from: taker2});
    assert.equal(20000, await instrumentEscrow.getTokenBalance(taker2, outputToken.address));
    // Engage spot multiSwap issuance
    let engageIssuance = await instrumentManager.engageIssuance(1, web3.eth.abi.encodeParameters(['uint256'], ['20000']), {from: taker2});

    let engageIssuanceEvents = LogParser.logParser(engageIssuance.receipt.rawLogs, abis);
    let issuance = await MultiSwapIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    let payables = properties.getPayablesList();
    let issuanceDueTimestamp = properties.getIssuanceduetimestamp().toNumber();
    let engagementLists = properties.getEngagementsList();
    assert.equal(0, payables.length);
    assert.equal(2, engagementLists.length);
    let customProperty = protobuf.MultiSwapData.MultiSwapEngagementProperty.deserializeBinary(Uint8Array.from(Buffer.from(engagementLists[1].getEngagementcustomproperty_asB64(), 'base64')));
    assert.equal(20000, customProperty.getOutputamount().toNumber());
    assert.equal(4, properties.getIssuancestate());
    assert.equal(0, await instrumentEscrow.getTokenBalance(taker2, outputToken.address));
    assert.equal(1000000, await instrumentEscrow.getTokenBalance(taker2, inputToken.address));
    assert.equal(40000, await instrumentEscrow.getTokenBalance(maker1, outputToken.address));
    let receipt = {logs: engageIssuanceEvents};
    expectEvent(receipt, 'EngagementCreated', {
      issuanceId: '1',
      takerAddress: taker2,
      engagementId: '2'
    });
    expectEvent(receipt, 'EngagementComplete', {
      issuanceId: '1',
      engagementId: '2'
    });
    expectEvent(receipt, 'IssuanceComplete', {
      issuanceId: '1',
      completionRatio: '10000'
    });

    expectEvent(receipt, 'PayablePaid', {
      issuanceId: '1',
      itemId: '2'
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '2',
      transferType: '3',
      fromAddress: taker2,
      toAddress: maker1,
      tokenAddress: outputToken.address,
      amount: '20000'
    });
    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '2',
      transferType: '1',
      fromAddress: maker1,
      toAddress: taker2,
      tokenAddress: inputToken.address,
      amount: '1000000'
    });

    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '3',
      fromAddress: taker2,
      toAddress: maker1,
      tokenAddress: outputToken.address,
      amount: '20000'
    });
    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '1',
      fromAddress: maker1,
      toAddress: taker2,
      tokenAddress: inputToken.address,
      amount: '1000000'
    });
  }),
  it('engage multiSwap failures', async () => {
    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let abis = getAbis();
    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 20, 80000]);
    let createdIssuance = await instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1});

    await outputToken.transfer(taker1, 39999);
    await outputToken.approve(instrumentEscrowAddress, 39999, {from: taker1});
    await instrumentEscrow.depositToken(outputToken.address, 39999, {from: taker1});

    await expectRevert(instrumentManager.engageIssuance(1, web3.eth.abi.encodeParameters(['uint256'], ['40001']), {from: taker1}), 'Input exceeded');
    await expectRevert(instrumentManager.engageIssuance(1, web3.eth.abi.encodeParameters(['uint256'], ['40000']), {from: taker1}), 'Insufficient output balance');
  }),
  it('engage multiSwap with output too small', async () => {
    const abis = getAbis();
    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 20000, 80000]);
    let createdIssuance = await instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1});
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    await outputToken.transfer(taker1, 15000);
    await outputToken.approve(instrumentEscrowAddress, 15000, {from: taker1});
    await instrumentEscrow.depositToken(outputToken.address, 15000, {from: taker1});
    assert.equal(15000, await instrumentEscrow.getTokenBalance(taker1, outputToken.address));
    await expectRevert(instrumentManager.engageIssuance(1, web3.eth.abi.encodeParameters(['uint256'], ['15000']), {from: taker1}), 'Invalid engagement output');
  }),

  it('engage multiSwap with output too large', async () => {
    const abis = getAbis();
    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 20000, 30000]);
    let createdIssuance = await instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1});
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    await outputToken.transfer(taker1, 35000);
    await outputToken.approve(instrumentEscrowAddress, 35000, {from: taker1});
    await instrumentEscrow.depositToken(outputToken.address, 35000, {from: taker1});
    assert.equal(35000, await instrumentEscrow.getTokenBalance(taker1, outputToken.address));
    await expectRevert(instrumentManager.engageIssuance(1, web3.eth.abi.encodeParameters(['uint256'], ['35000']), {from: taker1}), 'Invalid engagement output');
  }),

  it('cancel spot multiSwap not engageable', async () => {
    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let abis = getAbis();
    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 20, 80000]);
    let createdIssuance = await instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1});

    await outputToken.transfer(taker1, 40000);
    await outputToken.approve(instrumentEscrowAddress, 40000, {from: taker1});
    await instrumentEscrow.depositToken(outputToken.address, 40000, {from: taker1});

    // Engage spot multiSwap issuance
    await instrumentManager.engageIssuance(1, web3.eth.abi.encodeParameters(['uint256'], ['40000']), {from: taker1});
    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker1}), 'Cancel issuance not engageable');
  }),
  it('cancel spot multiSwap not maker', async () => {
    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let abis = getAbis();
    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 20, 80000]);
    let createdIssuance = await instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1});

    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker2}), 'Only maker can cancel issuance');
  }),
  it('operations after issuance terminated', async() => {
    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 20, 80000]);
    await instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1});
    await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker1});
    await expectRevert(instrumentManager.engageIssuance(1, [], {from: taker1}), "Issuance not Engageable");
  }),
  it('cancel spot multiSwap', async () => {
    let abis = getAbis();

    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 20, 80000]);
    let createdIssuance = await instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1});
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    let cancelIssuance = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker1});

    let issuance = await MultiSwapIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    let payables = properties.getPayablesList();
    assert.equal(0, payables.length);
    assert.equal(3, properties.getIssuancestate());

    let cancelIssuanceEvents = LogParser.logParser(cancelIssuance.receipt.rawLogs, abis);
    let receipt = {logs: cancelIssuanceEvents};

    assert.equal(2000000, await instrumentEscrow.getTokenBalance(maker1, inputToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(maker1, inputToken.address));
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
      tokenAddress: inputToken.address,
      amount: '2000000'
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '0',
      transferType: '1',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: inputToken.address,
      amount: '2000000'
    });
  }),
  it('cancel spot multiSwap half engaged', async () => {
    let abis = getAbis();

    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 20, 80000]);
    let createdIssuance = await instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1});
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);
    await outputToken.transfer(taker1, 20000);
    await outputToken.approve(instrumentEscrowAddress, 20000, {from: taker1});
    await instrumentEscrow.depositToken(outputToken.address, 20000, {from: taker1});
    assert.equal(20000, await instrumentEscrow.getTokenBalance(taker1, outputToken.address));
    await instrumentManager.engageIssuance(1, web3.eth.abi.encodeParameters(['uint256'], ['20000']), {from: taker1});

    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker1}), "Already engaged");
  }),
  it('notify due after due', async () => {
    let abis = getAbis();

    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 20, 80000]);
    let createdIssuance = await instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1});
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);
    await web3.currentProvider.send({jsonrpc: 2.0, method: 'evm_increaseTime', params: [8640000], id: 1}, (err, result) => { console.log(err, result)});
    let notifyDue = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("issuance_due"), web3.utils.fromAscii(""), {from: maker1});

    let notifyDueEvents = LogParser.logParser(notifyDue.receipt.rawLogs, abis);
    let receipt = {logs: notifyDueEvents};
    let issuance = await MultiSwapIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    let payables = properties.getPayablesList();
    assert.equal(0, payables.length);
    assert.equal(4, properties.getIssuancestate());
    assert.equal(2000000, await instrumentEscrow.getTokenBalance(maker1, inputToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(maker1, inputToken.address));
    expectEvent(receipt, 'IssuanceComplete', {
      issuanceId: new BN(1),
      completionRatio: '0'
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
      tokenAddress: inputToken.address,
      amount: '2000000'
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '0',
      transferType: '1',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: inputToken.address,
      amount: '2000000'
    });
  }),
  it('notify due after due half engaged', async () => {
    let abis = getAbis();

    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 20, 80000]);
    let createdIssuance = await instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1});
    await outputToken.transfer(taker1, 20000);
    await outputToken.approve(instrumentEscrowAddress, 20000, {from: taker1});
    await instrumentEscrow.depositToken(outputToken.address, 20000, {from: taker1});
    assert.equal(20000, await instrumentEscrow.getTokenBalance(taker1, outputToken.address));
    await instrumentManager.engageIssuance(1, web3.eth.abi.encodeParameters(['uint256'], ['20000']), {from: taker1});
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);
    await web3.currentProvider.send({jsonrpc: 2.0, method: 'evm_increaseTime', params: [8640000], id: 1}, (err, result) => { console.log(err, result)});
    let notifyDue = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("issuance_due"), web3.utils.fromAscii(""), {from: maker1});

    let notifyDueEvents = LogParser.logParser(notifyDue.receipt.rawLogs, abis);
    let receipt = {logs: notifyDueEvents};
    let issuance = await MultiSwapIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    let payables = properties.getPayablesList();
    assert.equal(0, payables.length);
    assert.equal(4, properties.getIssuancestate());
    assert.equal(1000000, await instrumentEscrow.getTokenBalance(maker1, inputToken.address));
    assert.equal(0, await issuanceEscrow.getTokenBalance(maker1, inputToken.address));
    expectEvent(receipt, 'IssuanceComplete', {
      issuanceId: new BN(1),
      completionRatio: '5000'
    });

    expectEvent(receipt, 'PayablePaid', {
      issuanceId: '1',
      itemId: '2'
    });

    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '1',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: inputToken.address,
      amount: '1000000'
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '0',
      transferType: '1',
      fromAddress: maker1,
      toAddress: maker1,
      tokenAddress: inputToken.address,
      amount: '1000000'
    });
  }),
  it('notify due before due', async () => {
    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let abis = getAbis();
    let spotMultiSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [20000, inputToken.address, outputToken.address, 2000000, 40000, 20, 80000]);
    let createdIssuance = await instrumentManager.createIssuance(spotMultiSwapMakerParameters, {from: maker1});
    let notifyDue = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("issuance_due"), web3.utils.fromAscii(""), {from: maker1});

    let issuance = await MultiSwapIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    assert.equal(2, properties.getIssuancestate());
  })
});
