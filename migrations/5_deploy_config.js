const WETH9 = artifacts.require("WETH9");
const EscrowFactory = artifacts.require("EscrowFactory");
const NUTSToken = artifacts.require("NUTSToken");
const Config = artifacts.require("Config");

const deployConfig = async function (deployer, [owner]) {
    const weth9 = await WETH9.deployed();
    const escrowFactory = await EscrowFactory.deployed();
    const nutsToken = await NUTSToken.deployed();

    await deployer.deploy(Config, weth9.address, escrowFactory.address, nutsToken.address, '20000000000000000000');
}

module.exports = function (deployer, network, accounts) {
    deployer
        .then(() => deployConfig(deployer, accounts))
        .catch(error => {
            console.log(error);
            process.exit(1);
        });
};
