const WETH9 = artifacts.require("WETH9");
const EscrowFactory = artifacts.require("EscrowFactory");
const NUTSToken = artifacts.require("NUTSToken");
const Config = artifacts.require("Config");
const InstrumentManagerFactory = artifacts.require("InstrumentManagerFactory");
const InstrumentRegistry = artifacts.require("InstrumentRegistry");
// const PriceOracleMock = artifacts.require("PriceOracleMock");
// const LendingInstrument = artifacts.require("LendingInstrument");
// const LendingIssuance = artifacts.require("LendingIssuance");
// const BorrowingInstrument = artifacts.require("BorrowingInstrument");
// const BorrowingIssuance = artifacts.require("BorrowingIssuance");
// const SwapInstrument = artifacts.require("SwapInstrument");
// const SwapIssuance = artifacts.require("SwapIssuance");
// const MultiSwapInstrument = artifacts.require("MultiSwapInstrument");
// const MultiSwapIssuance = artifacts.require("MultiSwapIssuance");
// const ERC20Mock = artifacts.require("ERC20Mock");
// const InstrumentManager = artifacts.require("InstrumentManager");
// const InstrumentEscrow = artifacts.require("InstrumentEscrow");

const deployNutsPlatform = async function(deployer, [owner, maker, taker]) {

  // Deploy Instrument Registry.
  const weth9 = await deployer.deploy(WETH9);
  const escrowFactory = await deployer.deploy(EscrowFactory);
  const nutsToken = await deployer.deploy(NUTSToken, 20000);
  const config = await deployer.deploy(Config, weth9.address, escrowFactory.address, nutsToken.address, 0);
  const instrumentRegistry = await deployer.deploy(InstrumentRegistry, config.address);

  // Deploy Instrument Manager Factory.
  const instrumentManagerFactory = await deployer.deploy(InstrumentManagerFactory);
  await config.setInstrumentManagerFactory(web3.utils.fromAscii("v2.5"), instrumentManagerFactory.address);

  // // Deploy the Price Oracle.
  // const priceOracle = await deployer.deploy(PriceOracleMock);

  // // Deploy Lending Instrument.
  // const lendingIssuance = await deployer.deploy(LendingIssuance);
  // const lendingInstrument = await deployer.deploy(LendingInstrument, false, false, priceOracle.address, lendingIssuance.address);
  // console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
  // await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), lendingInstrument.address,
  //   web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));

  // lendingToken = await ERC20Mock.new();
  // collateralToken = await ERC20Mock.new();
  // console.log("Lending token address:" + lendingToken.address);
  // console.log("Collateral token address:" + collateralToken.address);
  // await priceOracle.setRate(lendingToken.address, collateralToken.address, 100, 1);
  // await priceOracle.setRate(collateralToken.address, lendingToken.address, 1, 100);
  // const lendingInstrumentManagerAddress = await instrumentRegistry.getInstrumentManager(1);
  // console.log(lendingInstrumentManagerAddress);
  // const lendingInstrumentManager = await InstrumentManager.at(lendingInstrumentManagerAddress);
  // const lendingInstrumentEscrowAddress = await lendingInstrumentManager.getInstrumentEscrow();
  // console.log(lendingInstrumentEscrowAddress);
  // await lendingToken.transfer(maker, 20000);
  // await lendingToken.approve(lendingInstrumentEscrowAddress, 20000, {from: maker});

  // const lendingInstrumentEscrow = await InstrumentEscrow.at(lendingInstrumentEscrowAddress);
  // await lendingInstrumentEscrow.depositToken(lendingToken.address, 20000, {from: maker});
  // const makerBalance = await lendingInstrumentEscrow.getTokenBalance(maker, lendingToken.address);

  // const lendingMakerParameters = web3.eth.abi.encodeParameters(['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
  //   [lendingToken.address, collateralToken.address, '20000', '20', '15000', '10000']);
  // const createdIssuance = await lendingInstrumentManager.createIssuance(lendingMakerParameters, {from: maker});
  // console.log(createdIssuance);

  // await collateralToken.transfer(taker, 4000000);
  // await collateralToken.approve(lendingInstrumentEscrowAddress, 4000000, {from: taker});
  // await lendingInstrumentEscrow.depositToken(collateralToken.address, 4000000, {from: taker});
  // const engageIssuance = await lendingInstrumentManager.engageIssuance(1, '0x0', {from: taker});
  // console.log(engageIssuance);
  
  // // Deploy Borrowing Instrument.
  // const borrowingIssuance = await deployer.deploy(BorrowingIssuance);
  // const borrowingInstrument = await deployer.deploy(BorrowingInstrument, false, false, priceOracle.address, borrowingIssuance.address);
  // console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
  // await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), borrowingInstrument.address,
  //   web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));

  // // Deploy Swap Instrument.
  // const swapIssuance = await deployer.deploy(SwapIssuance);
  // const swapInstrument = await deployer.deploy(SwapInstrument, false, false, swapIssuance.address);
  // console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
  // await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), swapInstrument.address,
  //   web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
  
  // // Deploy Multi-Swap Instrument.
  // const multiSwapIssuance = await deployer.deploy(MultiSwapIssuance);
  // const multiSwapInstrument = await deployer.deploy(MultiSwapInstrument, false, false, multiSwapIssuance.address);
  // console.log(web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
  // await instrumentRegistry.activateInstrument(web3.utils.fromAscii("v2.5"), multiSwapInstrument.address,
  //   web3.eth.abi.encodeParameters(['uint256', 'uint256'], ['9590280014', '9590280014']));
}

module.exports = function(deployer, network, accounts) {
  deployer
      .then(() => deployNutsPlatform(deployer, accounts))
      .catch(error => {
        console.log(error);
        process.exit(1);
      });
  };
  