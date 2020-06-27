const InstrumentRegistry = artifacts.require('InstrumentRegistry');
const MultiSwapIssuance = artifacts.require('MultiSwapIssuance');
const MultiSwapInstrument = artifacts.require('MultiSwapInstrument');
const InstrumentManager = artifacts.require('InstrumentManager');

const argv = require('yargs').argv;
const utils = require('./utils');

module.exports = async function (callback) {
    try {
        const instrumentRegistry = await InstrumentRegistry.deployed();
        
        const multiSwapIssuance = await MultiSwapIssuance.new({from: argv.account});
        const multiSwapInstrument = await MultiSwapInstrument.new(argv.makerWhitelist, argv.takerWhitelist,
            multiSwapIssuance.address, {from: argv.account});

        const tx = await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), multiSwapInstrument.address,
            web3.eth.abi.encodeParameters(['uint256', 'uint256'], [argv.terminationTimestamp, argv.overrideTimestamp]), {from: argv.account});
        const logs = await utils.logParser(web3, tx.receipt.rawLogs, [].concat(InstrumentRegistry.abi));
        const instrumentId = logs.filter(p => p['event'] === 'InstrumentActivated')[0].args.instrumentId;
        console.log('Instrument ID: ' + instrumentId);
        console.log('Instrument Address: ' + multiSwapInstrument.address);

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