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

const deployNutsPlatform = async function(deployer, [owner]) {

  // Deploy Instrument Registry.
  const weth9 = await deployer.deploy(WETH9);
  const escrowFactory = await deployer.deploy(EscrowFactory);
  const nutsToken = await deployer.deploy(NUTSToken, 20000);
  const config = await deployer.deploy(Config, weth9.address, escrowFactory.address, nutsToken.address, 0);
  const instrumentRegistry = await deployer.deploy(InstrumentRegistry, config.address);

  // Deploy Instrument Manager Factory.
  const instrumentManagerFactory = await deployer.deploy(InstrumentManagerFactory);
  await config.setInstrumentManagerFactory(web3.utils.fromAscii("v2.5"), instrumentManagerFactory.address);

  // Deploy the Price Oracle.
  const priceOracle = await deployer.deploy(PriceOracleMock);

  // Deploy Lending Instrument.
  const lendingIssuance = await deployer.deploy(LendingIssuance);
  const lendingInstrument = await deployer.deploy(LendingInstrument, false, false, priceOracle.address, lendingIssuance.address);
  console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
  await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), lendingInstrument.address,
    web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));

  // Deploy Borrowing Instrument.
  const borrowingIssuance = await deployer.deploy(BorrowingIssuance);
  const borrowingInstrument = await deployer.deploy(BorrowingInstrument, false, false, priceOracle.address, borrowingIssuance.address);
  console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
  await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), borrowingInstrument.address,
    web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));

  // Deploy Swap Instrument.
  const swapIssuance = await deployer.deploy(SwapIssuance);
  const swapInstrument = await deployer.deploy(SwapInstrument, false, false, swapIssuance.address);
  console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
  await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), swapInstrument.address,
    web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
  
  // Deploy Multi-Swap Instrument.
  const multiSwapIssuance = await deployer.deploy(MultiSwapIssuance);
  const multiSwapInstrument = await deployer.deploy(MultiSwapInstrument, false, false, multiSwapIssuance.address);
  console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
  await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), multiSwapInstrument.address,
    web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
}

module.exports = function(deployer, network, accounts) {
  deployer
      .then(() => deployNutsPlatform(deployer, accounts))
      .catch(error => {
        console.log(error);
        process.exit(1);
      });
  };
  