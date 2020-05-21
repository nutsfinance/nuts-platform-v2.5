const LendingIssuance = artifacts.require("LendingIssuance");

module.exports = function(deployer, environment, accounts) {
    console.log(accounts);
    console.log(environment);
  deployer.deploy(LendingIssuance, accounts[1], 1, accounts[2], accounts[0], web3.utils.fromAscii(''));
};
