const WETH9 = artifacts.require("WETH9");
const EscrowFactory = artifacts.require("EscrowFactory");
const NUTSToken = artifacts.require("NUTSToken");
const Config = artifacts.require("Config");
const InstrumentManagerFactory = artifacts.require("InstrumentManagerFactory");
const InstrumentRegistry = artifacts.require("InstrumentRegistry");
const PriceOracle = artifacts.require("PriceOracle");
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
    const priceOracle = await deployer.deploy(PriceOracle);

    const mockUSD = '0x3EfC5E3c4CFFc638E9C506bb0F040EA0d8d3D094';
    const mockCNY = '0x2D5254e5905c6671b1804eac23Ba3F1C8773Ee46';
    const mockETH = (await WETH9.deployed()).address;
    const mockUSDT = (await deployer.deploy(ERC20Mock, 6)).address;
    const mockUSDC = (await deployer.deploy(ERC20Mock, 6)).address;
    const mockDAI = (await deployer.deploy(ERC20Mock, 18)).address;

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
