// const Market = artifacts.require("Market");
// const ZapCoordinator = artifacts.require("./ZapCoordinator.sol");
//
// module.exports = function(deployer) {
//   deployer.deploy(Market, ZapCoordinator.address,);
// };

const AuxiliaryMarket = artifacts.require('./Market.sol');
const ZapCoordinator = artifacts.require('./ZapCoordinator.sol');
const AuxiliaryMarketToken = artifacts.require('./FixedSupplyToken.sol');
const ZapToken = artifacts.require('./ZapToken.sol');

module.exports = async function(deployer) {
  const coordinator = await ZapCoordinator.deployed();
  const zapToken = await ZapToken.deployed();

  await deployer.deploy(AuxiliaryMarketToken);

  const amt = await AuxiliaryMarketToken.deployed();

  await coordinator.addImmutableContract('AUXILIARYMARKET_TOKEN', amt.address);



  await deployer.deploy(AuxiliaryMarket, ZapCoordinator.address);
  const am = await AuxiliaryMarket.deployed();
  await coordinator.addImmutableContract('AUXMARKET', am.address);

  var accounts = await web3.eth.getAccounts();
  var secondAccount = accounts[1];
  var thirdAccount = accounts[2];

  //Mint initial 100 million MMT Tokens for Main Market to disperse to users who bond
  var mintAmount = 100000000;

  //turn to 18 decimal precision

  let amtWei = web3.utils.toWei(mintAmount.toString(), 'ether');
  //mmtWei is used for more precise transactions.
  await mmt.mint(mm.address, mmtWei);
  await amt.mint(am.address, amtWei);

  let allocate = 2000000;
  let allocateInWeiMMT = web3.utils.toWei(allocate.toString(), 'ether');

  //Allocate Zap to user for testing purposes locally
  await mm.allocateZap(allocateInWeiMMT);

  //2000000 zap
  let approved = 2000000;
  let approveWeiZap = web3.utils.toWei(approved.toString(), 'ether');

  //Approve MainMarket and Aux Market an allowance of Zap to use on behalf of msg.sender(User)
  await zapToken.approve(mm.address, approveWeiZap);
  await zapToken.approve(am.address, approveWeiZap);
  await mm.depositZap(approveWeiZap);
  await mm.bond(10);

  // //Allocate more after depositing zap into Main Market
  await mm.allocateZap(allocateInWeiMMT);

  //Setting up second account
  await mm.allocateZap(allocateInWeiMMT, { from: secondAccount });
  await zapToken.approve(mm.address, approveWeiZap, { from: secondAccount });
  await mm.depositZap(approveWeiZap, { from: secondAccount });
  await mm.bond(10, { from: secondAccount });

  //Setting up third account
  await mm.allocateZap(allocateInWeiMMT, { from: thirdAccount });
  await zapToken.approve(mm.address, approveWeiZap, { from: thirdAccount });
  await mm.depositZap(approveWeiZap, { from: thirdAccount });
  await mm.bond(50, { from: thirdAccount });
};
