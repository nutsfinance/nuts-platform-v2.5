const ERC20 = artifacts.require('ERC20');
const PriceOracle = artifacts.require('PriceOracle');

module.exports = async function (callback) {
    try {
        const priceOracle = await PriceOracle.at('0x52473D102fcC7Da39662289cCa1726eFC90E0F38');

        const mockUSD = '0x3EfC5E3c4CFFc638E9C506bb0F040EA0d8d3D094';
        const mockCNY = '0x2D5254e5905c6671b1804eac23Ba3F1C8773Ee46';
        const mockETH = '0x92a9f7B36b40A76E9f93Ab2F8fbb6fA64B8f98fa';
        const mockUSDT = '0x301D599DEF9cD55e545EFE7769D4540c8f2EdC94';
        const mockUSDC = '0xd5DEC3A72eE67F3934E57426c704F06C4D0F7B51';
        const mockDAI = '0xF9074D543B800354E8DC6488A5f09D9863F95f33';

        // USD <--> CNY
        await priceOracle.setRate(mockUSD, mockCNY, 20, 3);
        await priceOracle.setRate(mockCNY, mockUSD, 3, 20);
        // USD <--> ETH
        await priceOracle.setRate(mockUSD, mockETH, '1000000000000000000', 200);
        await priceOracle.setRate(mockETH, mockUSD, 200, '1000000000000000000');
        // USD <--> USDT
        await priceOracle.setRate(mockUSD, mockUSDT, 1000000, 1);
        await priceOracle.setRate(mockUSDT, mockUSD, 1, 1000000);
        // USD <--> USDC
        await priceOracle.setRate(mockUSD, mockUSDC, 1000000, 1);
        await priceOracle.setRate(mockUSDC, mockUSD, 1, 1000000);
        // USD <--> DAI
        await priceOracle.setRate(mockUSD, mockDAI, '1000000000000000000', 1);
        await priceOracle.setRate(mockDAI, mockUSD, 1, '1000000000000000000');

        // CNY <--> ETH
        await priceOracle.setRate(mockCNY, mockETH, '3000000000000000000', 4000);
        await priceOracle.setRate(mockETH, mockCNY, 4000, '3000000000000000000');
        // CNY <--> USDT
        await priceOracle.setRate(mockCNY, mockUSDT, 3000000, 20);
        await priceOracle.setRate(mockUSDT, mockCNY, 20, 3000000);
        // CNY <--> USDC
        await priceOracle.setRate(mockCNY, mockUSDC, 3000000, 20);
        await priceOracle.setRate(mockUSDC, mockCNY, 20, 3000000);
        // CNY <--> DAI
        await priceOracle.setRate(mockCNY, mockDAI, '3000000000000000000', 20);
        await priceOracle.setRate(mockDAI, mockCNY, 20, '3000000000000000000');

        // ETH <--> USDT
        await priceOracle.setRate(mockETH, mockUSDT, 200, '1000000000000');
        await priceOracle.setRate(mockUSDT, mockETH, '1000000000000', 200);
        // ETH <--> USDC
        await priceOracle.setRate(mockETH, mockUSDC, 200, '1000000000000');
        await priceOracle.setRate(mockUSDC, mockETH, '1000000000000', 200);
        // ETH <--> DAI
        await priceOracle.setRate(mockETH, mockDAI, 200, 1);
        await priceOracle.setRate(mockDAI, mockETH, 1, 200);

        // USDT <--> USDC
        await priceOracle.setRate(mockUSDT, mockUSDC, 1, 1);
        await priceOracle.setRate(mockUSDC, mockUSDT, 1, 1);
        // USDT <--> DAI
        await priceOracle.setRate(mockUSDT, mockDAI, 1, '1000000000000');
        await priceOracle.setRate(mockDAI, mockUSDT, '1000000000000', 1);

        // USDC <--> DAI
        await priceOracle.setRate(mockUSDC, mockDAI, 1, '1000000000000');
        await priceOracle.setRate(mockDAI, mockUSDC, '1000000000000', 1);

        callback();
    } catch (e) {
        callback(e);
    }
}