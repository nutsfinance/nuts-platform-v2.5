const EscrowFactory = artifacts.require("EscrowFactory");

module.exports = function(deployer) {
    deployer.deploy(EscrowFactory);
};
  