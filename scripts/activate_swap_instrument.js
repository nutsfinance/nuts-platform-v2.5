const InstrumentRegistry = artifacts.require('InstrumentRegistry');
const SwapIssuance = artifacts.require('SwapIssuance');
const SwapInstrument = artifacts.require('SwapInstrument');
const InstrumentManager = artifacts.require('InstrumentManager');
const NutsToken = artifacts.require('NUTSToken');

const argv = require('yargs').argv;
const utils = require('./utils');

module.exports = async function (callback) {
    try {
        const nutsToken = await NutsToken.deployed();
        const instrumentRegistry = await InstrumentRegistry.deployed();
        
        await nutsToken.approve(instrumentRegistry.address, argv.depositAmount, {from: argv.account});
        const swapIssuance = await SwapIssuance.new({from: argv.account});
        const swapInstrument = await SwapInstrument.new(argv.makerWhitelist, argv.takerWhitelist,
            swapIssuance.address, {from: argv.account});

        const tx = await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), swapInstrument.address,
            web3.eth.abi.encodeParameters(['uint256', 'uint256'], [argv.terminationTimestamp, argv.overrideTimestamp]), {from: argv.account});
        const logs = await utils.logParser(web3, tx.receipt.rawLogs, [].concat(InstrumentRegistry.abi));
        const instrumentId = logs.filter(p => p['event'] === 'InstrumentActivated')[0].args.instrumentId;
        console.log('Instrument ID: ' + instrumentId);
        console.log('Instrument Address: ' + swapInstrument.address);

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