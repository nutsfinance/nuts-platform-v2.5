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
const SwapInstrument = artifacts.require("SwapInstrument");
const SwapIssuance = artifacts.require("SwapIssuance");
const ERC20Mock = artifacts.require("ERC20Mock");
const InstrumentManager = artifacts.require("InstrumentManager");
const InstrumentEscrow = artifacts.require("InstrumentEscrow");
const IssuanceEscrow = artifacts.require("IssuanceEscrow");
const InstrumentEscrowInterface = artifacts.require('InstrumentEscrowInterface');
const IssuanceEscrowInterface = artifacts.require('IssuanceEscrowInterface');


let swap;
let instrumentManagerAddress;
let instrumentManager;
let instrumentEscrowAddress;
let instrumentEscrow;
let inputToken;
let outputToken;

function getAbis() {
  return [].concat(SwapInstrument.abi, SwapIssuance.abi, ERC20Mock.abi, IssuanceEscrow.abi, InstrumentEscrow.abi, InstrumentManager.abi);
}

contract('Swap', ([owner, proxyAdmin, timerOracle, fsp, maker1, taker1, maker2, taker2, maker3, taker3]) => {
  beforeEach(async () => {
    weth9 = await WETH9.new();
    const escrowFactory = await EscrowFactory.new();
    const nutsToken = await NUTSToken.new(web3.utils.fromAscii("NUTS Token Test"), web3.utils.fromAscii("NUTSTEST"), 20000);
    const config = await Config.new(weth9.address, escrowFactory.address, nutsToken.address, 0);
    const instrumentRegistry = await InstrumentRegistry.new(config.address);

    // Deploy Instrument Manager Factory.
    const instrumentManagerFactory = await InstrumentManagerFactory.new();
    await config.setInstrumentManagerFactory(web3.utils.fromAscii("v2.5"), instrumentManagerFactory.address);

    // Deploy Swap Instrument.
    const swapIssuance = await SwapIssuance.new();
    const swapInstrument = await SwapInstrument.new(false, false, swapIssuance.address);
    console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
    await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), swapInstrument.address,
      web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));

    inputToken = await ERC20Mock.new(18);
    outputToken = await ERC20Mock.new(18);
    console.log("Input token address:" + inputToken.address);
    console.log("Output token address:" + outputToken.address);
    instrumentManagerAddress = await instrumentRegistry.getInstrumentManager(1);
    instrumentManager = await InstrumentManager.at(instrumentManagerAddress);
    instrumentEscrowAddress = await instrumentManager.getInstrumentEscrow();
    console.log('Swap instrument manager address: ' + instrumentManagerAddress);
    console.log('Swap instrument escrow address: ' + instrumentEscrowAddress);

    instrumentEscrow = await InstrumentEscrow.at(instrumentEscrowAddress);
    console.log("maker1: " + maker1);
    console.log("taker1: " + taker1);
  }),
  it('invalid parameters', async () => {
    let spotSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256'], [20000, '0x0000000000000000000000000000000000000000', outputToken.address, 2000000, 40000]);
    await expectRevert(instrumentManager.createIssuance(spotSwapMakerParameters, {from: maker1}), 'Input token not set');

    spotSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256'], [20000, inputToken.address, '0x0000000000000000000000000000000000000000', 2000000, 40000]);
    await expectRevert(instrumentManager.createIssuance(spotSwapMakerParameters, {from: maker1}), 'Output token not set');

    spotSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256'], [20000, inputToken.address, outputToken.address, 0, 40000]);
    await expectRevert(instrumentManager.createIssuance(spotSwapMakerParameters, {from: maker1}), 'Input amount not set');

    spotSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256'], [20000, inputToken.address, outputToken.address, 2000000, 0]);
    await expectRevert(instrumentManager.createIssuance(spotSwapMakerParameters, {from: maker1}), 'Output amount not set');

    spotSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256'], [1296000, inputToken.address, outputToken.address, 2000000, 40000]);
    await expectRevert(instrumentManager.createIssuance(spotSwapMakerParameters, {from: maker1}), 'Invalid duration');
  }),
  it('valid parameters but insufficient fund', async () => {
    await inputToken.transfer(maker1, 1500000);
    await inputToken.approve(instrumentEscrowAddress, 1500000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 1500000, {from: maker1});

    let spotSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256'], [20000, inputToken.address, outputToken.address, 2000000, 40000]);
    await expectRevert(instrumentManager.createIssuance(spotSwapMakerParameters, {from: maker1}), 'Insufficient input balance');
  }),
  it('valid parameters', async () => {
    let abis = getAbis();

    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    assert.equal(2000000, await instrumentEscrow.getTokenBalance(maker1, inputToken.address));

    let spotSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256'], [20000, inputToken.address, outputToken.address, 2000000, 40000]);
    let createdIssuance = await instrumentManager.createIssuance(spotSwapMakerParameters, {from: maker1});

    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);
    let issuance = await SwapIssuance.at(await instrumentManager.getIssuance(1));
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
  it('engage spot swap', async () => {
    let abis = getAbis();

    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let spotSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256'], [20000, inputToken.address, outputToken.address, 2000000, 40000]);
    let createdIssuance = await instrumentManager.createIssuance(spotSwapMakerParameters, {from: maker1});
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    await outputToken.transfer(taker1, 40000);
    await outputToken.approve(instrumentEscrowAddress, 40000, {from: taker1});
    await instrumentEscrow.depositToken(outputToken.address, 40000, {from: taker1});
    assert.equal(40000, await instrumentEscrow.getTokenBalance(taker1, outputToken.address));

    // Engage spot swap issuance
    let engageIssuance = await instrumentManager.engageIssuance(1, '0x0', {from: taker1});

    let engageIssuanceEvents = LogParser.logParser(engageIssuance.receipt.rawLogs, abis);
    let issuance = await SwapIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    let payables = properties.getPayablesList();
    let issuanceDueTimestamp = properties.getIssuanceduetimestamp().toNumber();
    let engagementDueTimestamp = properties.getEngagementsList()[0].getEngagementduetimestamp().toNumber();
    assert.equal(0, payables.length);
    assert.equal(4, properties.getIssuancestate());
    assert.equal(0, await instrumentEscrow.getTokenBalance(taker1, outputToken.address));
    assert.equal(2000000, await instrumentEscrow.getTokenBalance(taker1, inputToken.address));
    assert.equal(40000, await instrumentEscrow.getTokenBalance(maker1, outputToken.address));

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
    expectEvent(receipt, 'IssuanceComplete', {
      issuanceId: '1',
      completionRatio: '10000'
    });

    expectEvent(receipt, 'PayablePaid', {
      issuanceId: '1',
      itemId: '1'
    });

    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '1',
      transferType: '3',
      fromAddress: taker1,
      toAddress: maker1,
      tokenAddress: outputToken.address,
      amount: '40000'
    });
    expectEvent(receipt, 'AssetTransferred', {
      issuanceId: '1',
      engagementId: '1',
      transferType: '1',
      fromAddress: maker1,
      toAddress: taker1,
      tokenAddress: inputToken.address,
      amount: '2000000'
    });

    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '3',
      fromAddress: taker1,
      toAddress: maker1,
      tokenAddress: outputToken.address,
      amount: '40000'
    });
    expectEvent(receipt, 'TokenTransferred', {
      issuanceId: '1',
      transferType: '1',
      fromAddress: maker1,
      toAddress: taker1,
      tokenAddress: inputToken.address,
      amount: '2000000'
    });
  }),
  it('engage spot swap insufficient output balance', async () => {
    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let abis = getAbis();
    let spotSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256'], [20000, inputToken.address, outputToken.address, 2000000, 40000]);
    let createdIssuance = await instrumentManager.createIssuance(spotSwapMakerParameters, {from: maker1});

    await outputToken.transfer(taker1, 39999);
    await outputToken.approve(instrumentEscrowAddress, 39999, {from: taker1});
    await instrumentEscrow.depositToken(outputToken.address, 39999, {from: taker1});

    // Engage spot swap issuance
    await expectRevert(instrumentManager.engageIssuance(1, '0x0', {from: taker1}), 'Insufficient output balance');
  }),
  it('cancel spot swap not engageable', async () => {
    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let abis = getAbis();
    let spotSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256'], [20000, inputToken.address, outputToken.address, 2000000, 40000]);
    let createdIssuance = await instrumentManager.createIssuance(spotSwapMakerParameters, {from: maker1});

    await outputToken.transfer(taker1, 40000);
    await outputToken.approve(instrumentEscrowAddress, 40000, {from: taker1});
    await instrumentEscrow.depositToken(outputToken.address, 40000, {from: taker1});

    // Engage spot swap issuance
    await instrumentManager.engageIssuance(1, '0x0', {from: taker1});
    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker1}), 'Cancel issuance not engageable');
  }),
  it('cancel spot swap not maker', async () => {
    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let abis = getAbis();
    let spotSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256'], [20000, inputToken.address, outputToken.address, 2000000, 40000]);
    let createdIssuance = await instrumentManager.createIssuance(spotSwapMakerParameters, {from: maker1});

    await expectRevert(instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker2}), 'Only maker can cancel issuance');
  }),
  it('operations after issuance terminated', async() => {
    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let spotSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256'], [20000, inputToken.address, outputToken.address, 2000000, 40000]);
    await instrumentManager.createIssuance(spotSwapMakerParameters, {from: maker1});
    await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker1});
    await expectRevert(instrumentManager.engageIssuance(1, [], {from: taker1}), "Issuance not Engageable");
  }),
  it('cancel spot swap', async () => {
    let abis = getAbis();

    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let spotSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256'], [20000, inputToken.address, outputToken.address, 2000000, 40000]);
    let createdIssuance = await instrumentManager.createIssuance(spotSwapMakerParameters, {from: maker1});
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);

    let cancelIssuance = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("cancel_issuance"), web3.utils.fromAscii(""), {from: maker1});

    let issuance = await SwapIssuance.at(await instrumentManager.getIssuance(1));
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
  it('notify due after due', async () => {
    let abis = getAbis();

    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let spotSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256'], [20000, inputToken.address, outputToken.address, 2000000, 40000]);
    let createdIssuance = await instrumentManager.createIssuance(spotSwapMakerParameters, {from: maker1});
    let events = LogParser.logParser(createdIssuance.receipt.rawLogs, abis);
    let issuanceEscrowAddress = await instrumentManager.getIssuanceEscrow(1);
    let issuanceEscrow = await IssuanceEscrowInterface.at(issuanceEscrowAddress);
    await web3.currentProvider.send({jsonrpc: 2.0, method: 'evm_increaseTime', params: [8640000], id: 1}, (err, result) => { console.log(err, result)});
    let notifyDue = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("issuance_due"), web3.utils.fromAscii(""), {from: maker1});

    let notifyDueEvents = LogParser.logParser(notifyDue.receipt.rawLogs, abis);
    let receipt = {logs: notifyDueEvents};
    let issuance = await SwapIssuance.at(await instrumentManager.getIssuance(1));
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
  it('notify due before due', async () => {
    await inputToken.transfer(maker1, 2000000);
    await inputToken.approve(instrumentEscrowAddress, 2000000, {from: maker1});
    await instrumentEscrow.depositToken(inputToken.address, 2000000, {from: maker1});
    let abis = getAbis();
    let spotSwapMakerParameters = web3.eth.abi.encodeParameters(['uint256', 'address', 'address', 'uint256', 'uint256'], [20000, inputToken.address, outputToken.address, 2000000, 40000]);
    let createdIssuance = await instrumentManager.createIssuance(spotSwapMakerParameters, {from: maker1});
    let notifyDue = await instrumentManager.processEvent(1, 0, web3.utils.fromAscii("issuance_due"), web3.utils.fromAscii(""), {from: maker1});

    let issuance = await SwapIssuance.at(await instrumentManager.getIssuance(1));
    let customData = await issuance.getIssuanceProperty();
    let properties = protobuf.IssuanceData.IssuanceProperty.deserializeBinary(Uint8Array.from(Buffer.from(customData.substring(2), 'hex')));
    assert.equal(2, properties.getIssuancestate());
  })
});
