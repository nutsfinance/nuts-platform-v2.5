const NUTSToken = artifacts.require("NUTSToken");

module.exports = function(deployer) {
    deployer.deploy(NUTSToken, web3.utils.fromAscii("NUTS Token Beta"), web3.utils.fromAscii("NUTSBETA"), '210000000000000000000000000');
};
  