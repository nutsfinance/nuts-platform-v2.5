const WETH9 = artifacts.require("WETH9");
const EscrowFactory = artifacts.require("EscrowFactory");
const NUTSToken = artifacts.require("NUTSToken");
const Config = artifacts.require("Config");
const InstrumentManagerFactory = artifacts.require("InstrumentManagerFactory");
const InstrumentRegistry = artifacts.require("InstrumentRegistry");

const deployNutsPlatform = async function(deployer, [owner, maker, taker]) {

  // Deploy Instrument Registry.
  const weth9 = await deployer.deploy(WETH9);
  const escrowFactory = await deployer.deploy(EscrowFactory);
  const nutsToken = await deployer.deploy(NUTSToken, web3.utils.fromAscii("NUTS Token Test"), web3.utils.fromAscii("NUTSTEST"), 20000);
  const config = await deployer.deploy(Config, weth9.address, escrowFactory.address, nutsToken.address, 0);
  const instrumentRegistry = await deployer.deploy(InstrumentRegistry, config.address);

  // Deploy Instrument Manager Factory.
  const instrumentManagerFactory = await deployer.deploy(InstrumentManagerFactory);
  await config.setInstrumentManagerFactory(web3.utils.fromAscii("v2.5"), instrumentManagerFactory.address);
}

module.exports = function(deployer, network, accounts) {
  deployer
      .then(() => deployNutsPlatform(deployer, accounts))
      .catch(error => {
        console.log(error);
        process.exit(1);
      });
  };
  