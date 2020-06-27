const PriceOracle = artifacts.require('PriceOracle');

module.exports = function(deployer) {
  deployer.deploy(PriceOracle);
};
