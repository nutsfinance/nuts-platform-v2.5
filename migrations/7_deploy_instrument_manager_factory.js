const InstrumentManagerFactory = artifacts.require("InstrumentManagerFactory");

module.exports = function(deployer) {
    deployer.deploy(InstrumentManagerFactory);
};
  
  