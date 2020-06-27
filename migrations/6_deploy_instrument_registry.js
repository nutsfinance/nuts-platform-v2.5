const Config = artifacts.require("Config");
const InstrumentRegistry = artifacts.require("InstrumentRegistry");

const deployInstrumentRegistry = async function(deployer) {
  const config = await Config.deployed();
  const instrumentRegistry = await deployer.deploy(InstrumentRegistry, config.address);
  console.log('Instrument Registry: ' + instrumentRegistry.address);
}

module.exports = function(deployer, network, accounts) {
  deployer
      .then(() => deployInstrumentRegistry(deployer))
      .catch(error => {
        console.log(error);
        process.exit(1);
      });
  };
  