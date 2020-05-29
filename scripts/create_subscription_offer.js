const InstrumentRegistry = artifacts.require('InstrumentRegistry');
const InstrumentManager = artifacts.require('InstrumentManager');
const InstrumentEscrow = artifacts.require('InstrumentEscrow');
const ERC20 = artifacts.require('ERC20');
const ERC20FixedSupply = artifacts.require('ERC20FixedSupply');
const argv = require('yargs').argv;
const utils = require('./utils');

module.exports = async function (callback) {
    try {
        const instrumentRegistry = await InstrumentRegistry.at(argv.instrumentRegistry);

        const instrumentManagerAddress = await instrumentRegistry.getInstrumentManager(argv.instrumentId);
        console.log('Instrument Manager: ' + instrumentManagerAddress);
        const instrumentManager = await InstrumentManager.at(instrumentManagerAddress);
        const instrumentEscrowAddress = await instrumentManager.getInstrumentEscrow();
        console.log('Instrument Escrow: ' + instrumentEscrowAddress);

        // Deploy redemption token
        const redemptionToken = await ERC20FixedSupply.new(web3.utils.fromAscii(argv.redemptionTokenName),
            web3.utils.fromAscii(argv.redemptionTokenSymbol), argv.redemptionAmount, {from: argv.account});
        console.log('Redemption token: ' + redemptionToken.address);

        // Transfer all redemption tokens to instrument escrow
        await redemptionToken.approve(instrumentEscrowAddress, argv.redemptionAmount, {from: argv.account});
        const instrumentEscrow = await InstrumentEscrow.at(instrumentEscrowAddress);
        await instrumentEscrow.depositToken(redemptionToken.address, argv.redemptionAmount, {from: argv.account});

        // Create issuance
        const tx = await instrumentManager.createIssuance(web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256'],
            [redemptionToken.address, argv.subscriptionToken, argv.redemptionAmount, argv.subscriptionAmount, argv.duration]), {from: argv.account});
        const logs = await utils.logParser(web3, tx.receipt.rawLogs, [].concat(InstrumentManager.abi));
        let issuanceCreated = logs.filter(p => p['event'] === 'IssuanceCreated')[0].args;
        console.log('Issuance ID: ' + issuanceCreated.issuanceId);

        callback();
    } catch (e) {
        callback(e);
    }
}