const InstrumentRegistry = artifacts.require('InstrumentRegistry');
const InstrumentManager = artifacts.require('InstrumentManager');
const InstrumentEscrow = artifacts.require('InstrumentEscrow');
const ERC20 = artifacts.require('ERC20');
const ERC20FixedSupply = artifacts.require('ERC20FixedSupply');
const argv = require('yargs').argv;
const utils = require('./utils');
const axios = require('axios');

module.exports = async function (callback) {
    try {
        const maker = '0xb7b26138F7fF4AAa942153a7225Ffc5cC78ABb38';
        const taker = '0x711E6b255c62D3AF1c2b8E006365ED46BF103059';
        const instrumentReistryAddress = '0xFa913a841796b5C9e68CD6D29360927dC77006a7';
        const instrumentId = 4;
        const redemptionTokenName1 = 'Apple ETH Rights Token 4';
        const redemptionTokenSymbol1 = 'APPL ETH 4';
        const redemptionAmount1 = '1000000000000000000000';   // 1000 rights token
        const subscriptionTokenAddress1 = '0xA53d062959DefBCd28bcA416c5a302cF753Fa09c';  // ETH
        const subscriptionAmount1 = '10000000000000000000';   // 10 ETH
        const redemptionTokenName2 = 'Apple USDC Rights Token 4';
        const redemptionTokenSymbol2 = 'APPL USDC 4';
        const redemptionAmount2 = '2000000000000000000000';   // 2000 rights token
        const subscriptionTokenAddress2 = '0x9Cbfd9946D806bD9792ee79250e55CA24887581c';  // USDC
        const subscriptionAmount2 = '4000000000';   // 4000 USDC
        const duration = 20;
        const subscriptionOfferId = 4;

        const instrumentRegistry = await InstrumentRegistry.at(instrumentReistryAddress);
        const instrumentManagerAddress = await instrumentRegistry.getInstrumentManager(instrumentId);
        console.log('Instrument Manager: ' + instrumentManagerAddress);
        const instrumentManager = await InstrumentManager.at(instrumentManagerAddress);
        const instrumentEscrowAddress = await instrumentManager.getInstrumentEscrow();
        console.log('Instrument Escrow: ' + instrumentEscrowAddress);
        const instrumentEscrow = await InstrumentEscrow.at(instrumentEscrowAddress);

        // Deploy redemption token 1
        const redemptionToken1 = await ERC20FixedSupply.new(web3.utils.fromAscii(redemptionTokenName1),
            web3.utils.fromAscii(redemptionTokenSymbol1), redemptionAmount1, {from: maker});
        console.log('Redemption token 1: ' + redemptionToken1.address);

        // Create redemption token 1
        // Add redemption token
        const tokenData1 = {
            "tokenAddress": redemptionToken1.address,
            "tokenSymbol": redemptionTokenSymbol1,
            "tokenName": redemptionTokenName1,
            "decimals": 18,
            "iconUrl": "https://nuts-assets.s3-us-west-2.amazonaws.com/token/token1.png",
            "supportsTransaction": false
        };
        await axios.post('https://kovan-api.dapp.finance/tokens', tokenData1);

        // Deploy redemption token 2
        const redemptionToken2 = await ERC20FixedSupply.new(web3.utils.fromAscii(redemptionTokenName2),
            web3.utils.fromAscii(redemptionTokenSymbol2), redemptionAmount2, {from: maker});
        console.log('Redemption token 2: ' + redemptionToken2.address);

        // Create redemption token 2
        // Add redemption token
        const tokenData2 = {
            "tokenAddress": redemptionToken2.address,
            "tokenSymbol": redemptionTokenSymbol2,
            "tokenName": redemptionTokenName2,
            "decimals": 18,
            "iconUrl": "https://nuts-assets.s3-us-west-2.amazonaws.com/token/token2.png",
            "supportsTransaction": false
        };
        await axios.post('https://kovan-api.dapp.finance/tokens', tokenData2);

        // Transfer all redemption tokens 1 to instrument escrow
        await redemptionToken1.approve(instrumentEscrowAddress, redemptionAmount1, {from: maker});
        await instrumentEscrow.depositToken(redemptionToken1.address, redemptionAmount1, {from: maker});

        // Create issuance 1
        const tx1 = await instrumentManager.createIssuance(web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256'],
            [redemptionToken1.address, subscriptionTokenAddress1, redemptionAmount1, subscriptionAmount1, duration]), {from: maker});
        const logs1 = await utils.logParser(web3, tx1.receipt.rawLogs, [].concat(InstrumentManager.abi));
        const issuanceId1 = logs1.filter(p => p['event'] === 'IssuanceCreated')[0].args.issuanceId;
        console.log('Issuance 1 ID: ' + issuanceId1);

        // Transfer all redemption tokens 2 to instrument escrow
        await redemptionToken2.approve(instrumentEscrowAddress, redemptionAmount2, {from: maker});
        await instrumentEscrow.depositToken(redemptionToken2.address, redemptionAmount2, {from: maker});

        // Create issuance 2
        const tx2 = await instrumentManager.createIssuance(web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256'],
            [redemptionToken2.address, subscriptionTokenAddress2, redemptionAmount2, subscriptionAmount2, duration]), {from: maker});
        const logs2 = await utils.logParser(web3, tx2.receipt.rawLogs, [].concat(InstrumentManager.abi));
        const issuanceId2 = logs2.filter(p => p['event'] === 'IssuanceCreated')[0].args.issuanceId;
        console.log('Issuance 2 ID: ' + issuanceId2);

        // Engage subscription issuance 1
        const engageAmount1 = '4000000000000000000'; // 4 ETH
        await instrumentEscrow.deposit({from: taker, value: engageAmount1});
        await instrumentManager.engageIssuance(issuanceId1, web3.eth.abi.encodeParameters(['uint256'], [engageAmount1]), {from: taker});

        // Engage subscription issuance 2
        const engageAmount2 = '2000000000000000000'; // 2 ETH
        await instrumentEscrow.deposit({from: taker, value: engageAmount2});
        await instrumentManager.engageIssuance(issuanceId1, web3.eth.abi.encodeParameters(['uint256'], [engageAmount2]), {from: taker});

        // Engage subscription issuance 3
        const engageAmount3 = '3000000000000000000'; // 3 ETH
        await instrumentEscrow.deposit({from: taker, value: engageAmount3});
        await instrumentManager.engageIssuance(issuanceId1, web3.eth.abi.encodeParameters(['uint256'], [engageAmount3]), {from: taker});

        // Create redemption issuance
        const redemptionTotal1 = '5000000000000000000';   // 5 ETH
        await instrumentEscrow.deposit({from: maker, value: redemptionTotal1});
        const tx3 = await instrumentManager.createIssuance(web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256'],
            [subscriptionTokenAddress1, redemptionToken1.address, redemptionTotal1, redemptionAmount1, duration]), {from: maker});
        const logs3 = await utils.logParser(web3, tx3.receipt.rawLogs, [].concat(InstrumentManager.abi));
        const issuanceId3 = logs3.filter(p => p['event'] === 'IssuanceCreated')[0].args.issuanceId;
        console.log('Redemption issuance ID: ' + issuanceId3);

        // Engage redemption issuance 1
        const redeemAmount1 = '200000000000000000000';   // 200 rights token
        await instrumentManager.engageIssuance(issuanceId3, web3.eth.abi.encodeParameters(['uint256'], [redeemAmount1]), {from: taker});

        // Engage redemption issuance 2
        const redeemAmount2 = '200000000000000000000';   // 200 rights token
        await instrumentManager.engageIssuance(issuanceId3, web3.eth.abi.encodeParameters(['uint256'], [redeemAmount2]), {from: taker});

        const now = new Date().getTime();
        const day = 3600 * 24 * 1000;
        const subscriptionData = {
            "id": subscriptionOfferId,
            "companyName": "Apple",
            "companyIconUrl": "https://nuts-assets.s3-us-west-2.amazonaws.com/company/Appleicon.png",
            "ticker": "APPL",
            "exchange": "nasdaq",
            "subscriptionStartTimestamp": now - 25 * day,
            "subscriptionEndTimestamp": now - 20 * day,
            "announceTimestamp": now - 15 * day,
            "redemptionStartTimestamp": now - 10 * day,
            "redemptionEndTimestamp": now - day,
            "fillRatio": 0.64,
            "offers": {
                "ETH": {
                  "subscription": issuanceId1,
                  "redemption": issuanceId3
                },
                "USDC": {
                  "subscription": issuanceId2,
                  "redemption": 0
                }
            }
        };

        await axios.post('https://kovan-api.dapp.finance/subscription-offers', subscriptionData);

        callback();
    } catch (e) {
        callback(e);
    }
}