const WETH9 = artifacts.require("WETH9");
const EscrowFactory = artifacts.require("EscrowFactory");
const NUTSToken = artifacts.require("NUTSToken");
const Config = artifacts.require("Config");
const InstrumentManagerFactory = artifacts.require("InstrumentManagerFactory");
const InstrumentRegistry = artifacts.require("InstrumentRegistry");
const PriceOracle = artifacts.require('PriceOracle');

const deployNutsPlatform = async function(deployer, [owner]) {

  // Deploy Instrument Registry.
  const weth9 = await deployer.deploy(WETH9);
  const escrowFactory = await deployer.deploy(EscrowFactory);
  const nutsToken = await deployer.deploy(NUTSToken, web3.utils.fromAscii("NUTS Token Beta"), web3.utils.fromAscii("NUTSBETA"), 20000);
  const config = await deployer.deploy(Config, weth9.address, escrowFactory.address, nutsToken.address, 0);
  const instrumentRegistry = await deployer.deploy(InstrumentRegistry, config.address);
  console.log('Instrument Registry: ' + instrumentRegistry.address);

  // Deploy Instrument Manager Factory.
  const instrumentManagerFactory = await deployer.deploy(InstrumentManagerFactory);
  await config.setInstrumentManagerFactory(web3.utils.fromAscii("v2.5"), instrumentManagerFactory.address);

  // Deploy the Price Oracle
  const priceOracle = await deployer.deploy(PriceOracle);
  console.log('Price Oracle: ' + priceOracle.address);
}

module.exports = function(deployer, network, accounts) {
  deployer
      .then(() => deployNutsPlatform(deployer, accounts))
      .catch(error => {
        console.log(error);
        process.exit(1);
      });
  };
  