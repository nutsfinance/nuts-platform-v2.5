const ERC20 = artifacts.require('ERC20Mock');
const PriceOracle = artifacts.require('PriceOracle');

module.exports = async function (callback) {
    try {
        // const priceOracle = await PriceOracle.at('0xF697B149FAa6e5cfed7f1EbC1ECDa183A9942750');
        const priceOracle = await PriceOracle.deployed();
        console.log(priceOracle.address);

        const mockUSD = '0x3EfC5E3c4CFFc638E9C506bb0F040EA0d8d3D094';
        const mockCNY = '0x2D5254e5905c6671b1804eac23Ba3F1C8773Ee46';
        const mockETH = '0x8018B912dddfc0Cf7bc33aE72ccB326541518C17';
        const mockUSDT = '0xD10289866c9f1A81Da7b4d02E125e4D7a4D3fe86';
        const mockUSDC = '0xeb6CC720398FA175848b9e1606B974A31aFc8C3b';
        const mockDAI = '0xceFf96F6C441110e24CE499b041cAa64C89cae27';

        const usdc = await ERC20.at(mockUSDC);
        const usdt = await ERC20.at(mockUSDT);
        const dai = await ERC20.at(mockDAI);

        // const role = '0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775';

        // // USD <--> CNY
        // await priceOracle.setRate(mockUSD, mockCNY, '20', '3');
        // await priceOracle.setRate(mockCNY, mockUSD, '3', '20');
        // // USD <--> ETH
        // await priceOracle.setRate(mockUSD, mockETH, '1', '200');
        // await priceOracle.setRate(mockETH, mockUSD, '200', '1');
        // // USD <--> USDT
        // await priceOracle.setRate(mockUSD, mockUSDT, '1', '1');
        // await priceOracle.setRate(mockUSDT, mockUSD, '1', '1');
        // // USD <--> USDC
        // await priceOracle.setRate(mockUSD, mockUSDC, '1', '1');
        // await priceOracle.setRate(mockUSDC, mockUSD, '1', '1');
        // // USD <--> DAI
        // await priceOracle.setRate(mockUSD, mockDAI, '1', '1');
        // await priceOracle.setRate(mockDAI, mockUSD, '1', '1');

        // // CNY <--> ETH
        // await priceOracle.setRate(mockCNY, mockETH, '3', '4000');
        // await priceOracle.setRate(mockETH, mockCNY, '4000', '3');
        // // CNY <--> USDT
        // await priceOracle.setRate(mockCNY, mockUSDT, '3', '20');
        // await priceOracle.setRate(mockUSDT, mockCNY, '20', '3');
        // // CNY <--> USDC
        // await priceOracle.setRate(mockCNY, mockUSDC, '3', '20');
        // await priceOracle.setRate(mockUSDC, mockCNY, '20', '3');
        // // CNY <--> DAI
        // await priceOracle.setRate(mockCNY, mockDAI, '3', '20');
        // await priceOracle.setRate(mockDAI, mockCNY, '20', '3');

        // // ETH <--> USDT
        // await priceOracle.setRate(mockETH, mockUSDT, '200', '1');
        // await priceOracle.setRate(mockUSDT, mockETH, '1', '200');
        // // ETH <--> USDC
        // await priceOracle.setRate(mockETH, mockUSDC, '200', '1');
        // await priceOracle.setRate(mockUSDC, mockETH, '1', '200');
        // // ETH <--> DAI
        // await priceOracle.setRate(mockETH, mockDAI, '200', '1');
        // await priceOracle.setRate(mockDAI, mockETH, '1', '200');

        // // USDT <--> USDC
        // await priceOracle.setRate(mockUSDT, mockUSDC, '1', '1');
        // await priceOracle.setRate(mockUSDC, mockUSDT, '1', '1');
        // // USDT <--> DAI
        // await priceOracle.setRate(mockUSDT, mockDAI, '1', '1');
        // await priceOracle.setRate(mockDAI, mockUSDT, '1', '1');

        // // USDC <--> DAI
        // await priceOracle.setRate(mockUSDC, mockDAI, '1', '1');
        // await priceOracle.setRate(mockDAI, mockUSDC, '1', '1');

        callback();
    } catch (e) {
        callback(e);
    }
}