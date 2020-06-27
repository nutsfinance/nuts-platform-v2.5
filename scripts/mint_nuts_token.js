const NutsToken = artifacts.require('NutsToken');

const argv = require('yargs').argv;

module.exports = async function (callback) {
    try {
        const nutsToken = await NutsToken.deployed();
        await nutsToken.mint(argv.target, argv.amount, {from: argv.account});

        callback();
    } catch (e) {
        callback(e);
    }
}