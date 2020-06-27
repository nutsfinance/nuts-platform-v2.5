const InstrumentRegistry = artifacts.require('InstrumentRegistry');
const LendingIssuance = artifacts.require('LendingIssuance');
const LendingInstrument = artifacts.require('LendingInstrument');
const InstrumentManager = artifacts.require('InstrumentManager');
const InstrumentEscrow = artifacts.require('InstrumentEscrow');
const PriceOracle = artifacts.require('PriceOracle');

const argv = require('yargs').argv;
const utils = require('./utils');

module.exports = async function (callback) {
    try {
        const instrumentRegistry = await InstrumentRegistry.deployed();
        const priceOracle = await PriceOracle.deployed();
        
        const lendingIssuance = await LendingIssuance.new({from: argv.account});
        const lendingInstrument = await LendingInstrument.new(false, false, priceOracle.address, lendingIssuance.address, {from: argv.account});

        await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), lendingInstrument.address,
            web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));

        const lendingInstrumentManagerAddress = await instrumentRegistry.getInstrumentManager(1);
        const lendingInstrumentManager = await InstrumentManager.at(lendingInstrumentManagerAddress);
        const lendingInstrumentEscrowAddress = await lendingInstrumentManager.getInstrumentEscrow();

        callback();
    } catch (e) {
        callback(e);
    }
}