const InstrumentRegistry = artifacts.require("InstrumentRegistry");
const LendingIssuance = artifacts.require("LendingIssuance");


module.exports = function(deployer, environment, [owner]) {

};


module.exports = function(deployer, network, accounts) {
  deployer
      .then(() => deployNutsPlatform(deployer, accounts))
      .catch(error => {
        console.log(error);
        process.exit(1);
      });
  };
  