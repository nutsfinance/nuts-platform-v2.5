const Config = artifacts.require("Config");
const InstrumentManagerFactory = artifacts.require("InstrumentManagerFactory");

const registryInstrumentManagerFactory = async function(deployer, [owner]) {
  // Deploy Instrument Manager Factory.
  const config = await Config.deployed();
  const instrumentManagerFactory = await InstrumentManagerFactory.deployed();
  await config.setInstrumentManagerFactory(web3.utils.fromAscii("v2.5"), instrumentManagerFactory.address);
}

module.exports = function(deployer, network, accounts) {
  deployer
      .then(() => registryInstrumentManagerFactory(deployer, accounts))
      .catch(error => {
        console.log(error);
        process.exit(1);
      });
  };
  