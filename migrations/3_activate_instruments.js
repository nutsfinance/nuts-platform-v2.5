const WETH9 = artifacts.require("WETH9");
const EscrowFactory = artifacts.require("EscrowFactory");
const NUTSToken = artifacts.require("NUTSToken");
const Config = artifacts.require("Config");
const InstrumentManagerFactory = artifacts.require("InstrumentManagerFactory");
const InstrumentRegistry = artifacts.require("InstrumentRegistry");
const PriceOracleMock = artifacts.require("PriceOracleMock");
const LendingInstrument = artifacts.require("LendingInstrument");
const LendingIssuance = artifacts.require("LendingIssuance");
const BorrowingInstrument = artifacts.require("BorrowingInstrument");
const BorrowingIssuance = artifacts.require("BorrowingIssuance");
const SwapInstrument = artifacts.require("SwapInstrument");
const SwapIssuance = artifacts.require("SwapIssuance");
const MultiSwapInstrument = artifacts.require("MultiSwapInstrument");
const MultiSwapIssuance = artifacts.require("MultiSwapIssuance");
const ERC20Mock = artifacts.require("ERC20Mock");
const InstrumentManager = artifacts.require("InstrumentManager");
const InstrumentEscrow = artifacts.require("InstrumentEscrow");

const activateInstruments = async function (deployer, [owner, maker, taker]) {

    const instrumentRegistry = await InstrumentRegistry.deployed();

    // Deploy the Price Oracle.
    const priceOracle = await deployer.deploy(PriceOracleMock);

    const mockUSD = '0x3EfC5E3c4CFFc638E9C506bb0F040EA0d8d3D094';
    const mockCNY = '0x2D5254e5905c6671b1804eac23Ba3F1C8773Ee46';
    const mockETH = (await WETH9.deployed()).address;
    const mockUSDT = (await deployer.deploy(ERC20Mock, 6)).address;
    const mockUSDC = (await deployer.deploy(ERC20Mock, 6)).address;
    const mockDAI = (await deployer.deploy(ERC20Mock, 18)).address;

    // USD <--> CNY
    await priceOracle.setRate(mockUSD, mockCNY, 20, 3);
    await priceOracle.setRate(mockCNY, mockUSD, 3, 20);
    // USD <--> ETH
    await priceOracle.setRate(mockUSD, mockETH, 1, 200);
    await priceOracle.setRate(mockETH, mockUSD, 200, 1);
    // USD <--> USDT
    await priceOracle.setRate(mockUSD, mockUSDT, 1, 1);
    await priceOracle.setRate(mockUSDT, mockUSD, 1, 1);
    // USD <--> USDC
    await priceOracle.setRate(mockUSD, mockUSDC, 1, 1);
    await priceOracle.setRate(mockUSDC, mockUSD, 1, 1);
    // USD <--> DAI
    await priceOracle.setRate(mockUSD, mockDAI, 1, 1);
    await priceOracle.setRate(mockDAI, mockUSD, 1, 1);

    // CNY <--> ETH
    await priceOracle.setRate(mockCNY, mockETH, 3, 4000);
    await priceOracle.setRate(mockETH, mockCNY, 4000, 3);
    // CNY <--> USDT
    await priceOracle.setRate(mockCNY, mockUSDT, 3, 20);
    await priceOracle.setRate(mockUSDT, mockCNY, 20, 3);
    // CNY <--> USDC
    await priceOracle.setRate(mockCNY, mockUSDC, 3, 20);
    await priceOracle.setRate(mockUSDC, mockCNY, 20, 3);
    // CNY <--> DAI
    await priceOracle.setRate(mockCNY, mockDAI, 3, 20);
    await priceOracle.setRate(mockDAI, mockCNY, 20, 3);

    // ETH <--> USDT
    await priceOracle.setRate(mockETH, mockUSDT, 200, 1);
    await priceOracle.setRate(mockUSDT, mockETH, 1, 200);
    // ETH <--> USDC
    await priceOracle.setRate(mockETH, mockUSDC, 200, 1);
    await priceOracle.setRate(mockUSDC, mockETH, 1, 200);
    // ETH <--> DAI
    await priceOracle.setRate(mockETH, mockDAI, 200, 1);
    await priceOracle.setRate(mockDAI, mockETH, 1, 200);

    // USDT <--> USDC
    await priceOracle.setRate(mockUSDT, mockUSDC, 1, 1);
    await priceOracle.setRate(mockUSDC, mockUSDT, 1, 1);
    // USDT <--> DAI
    await priceOracle.setRate(mockUSDT, mockDAI, 1, 1);
    await priceOracle.setRate(mockDAI, mockUSDT, 1, 1);

    // USDC <--> DAI
    await priceOracle.setRate(mockUSDC, mockDAI, 1, 1);
    await priceOracle.setRate(mockDAI, mockUSDC, 1, 1);

    // Deploy Lending Instrument.
    const lendingIssuance = await deployer.deploy(LendingIssuance);
    const lendingInstrument = await deployer.deploy(LendingInstrument, false, false, priceOracle.address, lendingIssuance.address);
    console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
    await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), lendingInstrument.address,
        web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
    const lendingInstrumentManagerAddress = await instrumentRegistry.getInstrumentManager(1);
    const lendingInstrumentManager = await InstrumentManager.at(lendingInstrumentManagerAddress);
    const lendingInstrumentEscrowAddress = await lendingInstrumentManager.getInstrumentEscrow();

    // Deploy Borrowing Instrument.
    const borrowingIssuance = await deployer.deploy(BorrowingIssuance);
    const borrowingInstrument = await deployer.deploy(BorrowingInstrument, false, false, priceOracle.address, borrowingIssuance.address);
    console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
    await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), borrowingInstrument.address,
        web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
    const borrowingInstrumentManagerAddress = await instrumentRegistry.getInstrumentManager(2);
    const borrowingInstrumentManager = await InstrumentManager.at(borrowingInstrumentManagerAddress);
    const borrowingInstrumentEscrowAddress = await borrowingInstrumentManager.getInstrumentEscrow();

    // Deploy Swap Instrument.
    const swapIssuance = await deployer.deploy(SwapIssuance);
    const swapInstrument = await deployer.deploy(SwapInstrument, false, false, swapIssuance.address);
    console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
    await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), swapInstrument.address,
        web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
    const swapInstrumentManagerAddress = await instrumentRegistry.getInstrumentManager(3);
    const swapInstrumentManager = await InstrumentManager.at(swapInstrumentManagerAddress);
    const swapInstrumentEscrowAddress = await swapInstrumentManager.getInstrumentEscrow();

    // Deploy Multi-Swap Instrument.
    const multiSwapIssuance = await deployer.deploy(MultiSwapIssuance);
    const multiSwapInstrument = await deployer.deploy(MultiSwapInstrument, false, false, multiSwapIssuance.address);
    console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
    await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), multiSwapInstrument.address,
        web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
    const multiSwapInstrumentManagerAddress = await instrumentRegistry.getInstrumentManager(4);
    const multiSwapInstrumentManager = await InstrumentManager.at(multiSwapInstrumentManagerAddress);
    const multiSwapInstrumentEscrowAddress = await multiSwapInstrumentManager.getInstrumentEscrow();

    const tokens = {
        ETH: mockETH,
        USDT: mockUSDT,
        USDC: mockUSDC,
        DAI: mockDAI
    };
    console.log(tokens);

    const contractAddresses = {
        instruments: {
            lending: {
                instrumentManager: lendingInstrumentManagerAddress,
                instrumentEscrow: lendingInstrumentEscrowAddress,
                instrumentId: 1
            },
            borrowing: {
                instrumentManager: borrowingInstrumentManagerAddress,
                instrumentEscrow: borrowingInstrumentEscrowAddress,
                instrumentId: 2
            },
            swap: {
                instrumentManager: swapInstrumentManagerAddress,
                instrumentEscrow: swapInstrumentEscrowAddress,
                instrumentId: 3
            },
            multiswap: {
                instrumentManager: multiSwapInstrumentManagerAddress,
                instrumentEscrow: multiSwapInstrumentEscrowAddress,
                instrumentId: 4
            }
        },
        instrumentRegistry: instrumentRegistry.address,
        priceOracle: priceOracle.address
    };
    console.log(contractAddresses);
}

module.exports = function (deployer, network, accounts) {
    deployer
        .then(() => activateInstruments(deployer, accounts))
        .catch(error => {
            console.log(error);
            process.exit(1);
        });
};
