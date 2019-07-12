const Market = artifacts.require("Market");
<<<<<<< HEAD

module.exports = function(deployer) {
  deployer.deploy(Market);
=======
const ZapCoordinator = artifacts.require("./ZapCoordinator.sol");

module.exports = function(deployer) {
  deployer.deploy(Market, ZapCoordinator.address);
>>>>>>> origin/HelloBranch
};
