const WhitelistInstrument = artifacts.require('WhitelistInstrument');

const argv = require('yargs').argv;

module.exports = async function (callback) {
    try {
        const instrument = await WhitelistInstrument.at(argv.instrumentAddress);
        await instrument.setMakerAllowed(argv.makerAddress, true, {from: argv.account, gas: 1000000});

        callback();
    } catch (e) {
        callback(e);
    }
}