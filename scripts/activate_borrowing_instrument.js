const InstrumentRegistry = artifacts.require('InstrumentRegistry');
const BorrowingIssuance = artifacts.require('BorrowingIssuance');
const BorrowingInstrument = artifacts.require('BorrowingInstrument');
const InstrumentManager = artifacts.require('InstrumentManager');
const PriceOracle = artifacts.require('PriceOracle');

const argv = require('yargs').argv;
const utils = require('./utils');

module.exports = async function (callback) {
    try {
        const instrumentRegistry = await InstrumentRegistry.deployed();
        const priceOracle = await PriceOracle.deployed();
        
        const borrowingIssuance = await BorrowingIssuance.new({from: argv.account});
        const borrowingInstrument = await BorrowingInstrument.new(argv.makerWhitelist, argv.takerWhitelist,
            priceOracle.address, borrowingIssuance.address, {from: argv.account});

        const tx = await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), borrowingInstrument.address,
            web3.eth.abi.encodeParameters(['uint256', 'uint256'], [argv.terminationTimestamp, argv.overrideTimestamp]), {from: argv.account});
        const logs = await utils.logParser(web3, tx.receipt.rawLogs, [].concat(InstrumentRegistry.abi));
        const instrumentId = logs.filter(p => p['event'] === 'InstrumentActivated')[0].args.instrumentId;
        console.log('Instrument ID: ' + instrumentId);
        console.log('Instrument Address: ' + borrowingInstrument.address);

        const instrumentManagerAddress = await instrumentRegistry.getInstrumentManager(instrumentId);
        const instrumentManager = await InstrumentManager.at(instrumentManagerAddress);
        const instrumentEscrowAddress = await instrumentManager.getInstrumentEscrow();
        console.log('Instrument Manager Address: ' + instrumentManagerAddress);
        console.log('Instrument Escrow Address: ' + instrumentEscrowAddress);

        callback();
    } catch (e) {
        callback(e);
    }
}