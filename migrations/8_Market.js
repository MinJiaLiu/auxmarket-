const Market = artifacts.require("Market");
const ZapCoordinator = artifacts.require("./ZapCoordinator.sol");

module.exports = function(deployer) {
  deployer.deploy(Market, ZapCoordinator.address);
};
