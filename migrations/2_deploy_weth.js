const WETH9 = artifacts.require("WETH9");

module.exports = function(deployer) {
  deployer.deploy(WETH9);
};
