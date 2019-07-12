
pragma solidity ^0.4.24;
import "./FixedSupplyToken.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";
import "../lib/ownership/ZapCoordinator.sol";
import "../token/ZapToken.sol";


contract Market {


  using SafeMath for uint256;
  
  //address public main; // main market address
  
  ZapToken public zapToken;
  ZapCoordinatorInterface public coordinator;
 
  address public fixsupplyaddress;
  FixedSupplyToken public FToken;
  uint256  public buyPrice;
  
  address public oracleAddress; // address of account operating oracle

  event GetPriceEvent();
  event PriceUpdated(uint256 amount);

  constructor(address _coordinator, address _oracle) public {
      coordinator = ZapCoordinatorInterface(_coordinator);
      address zapTokenAddress = coordinator.getContract("ZAP_TOKEN");
      // main= coordinator.getContract("MainMarket");
      fixsupplyaddress = coordinator.getContract("FixedSupplyToken");
      FToken= FixedSupplyToken(fixsupplyaddress);
      zapToken = ZapToken(zapTokenAddress);
      oracleAddress = _oracle;
  }

//returns the current price of zap to token
  function getPrice () public returns (uint256){
  //e/btc divided e/zapwe
    emit GetPriceEvent();
    return uint8(uint256(keccak256(block.timestamp, block.difficulty))%131) * 1000000000000000 + 100000000000000000 ; //need to change to match oracle
  }

//return the number of token a person has
  function getTokenBalance (address _user) public view returns (uint256){
    return FToken.balanceOf(_user) ;
  }

// 
  function getZapWeiSpent(address _user) public view returns (uint256) {
    return FToken.zapWei_spent(_user);
  }

  function getZapBalance (address _user) public view returns (uint256) {
    return zapToken.balanceOf(_user);
  }

// funtion oracle calls to update the price
  function updatePrice (uint _price) public {
    require(msg.sender == oracleAddress);
    buyPrice = _price;
    emit PriceUpdated(_price);
  }

//buying token
  function BuyToken (uint256 numberoftoken) public returns(uint256){

    buyPrice = getPrice();//set it to the new price using oracle ;
    uint256 zaprequire = numberoftoken.mul(buyPrice);
  //check if msg.sender has enoughg
    zapToken.approve(address(this),zaprequire); //address _spender, uint256 _valu


    zapToken.transferFrom(msg.sender,address(this),zaprequire);  //transferFrom(address from, address to, uint256 value)
    FToken.transfer(msg.sender,numberoftoken); // sends token to zap

    return numberoftoken;
  }

//withrawn an amount of Token
  function Withdrawn (uint256 withdraw_amount) public payable returns (uint8) {
    if (FToken.balanceOf(msg.sender) >= withdraw_amount){ //check if msg.sender has enough token
      buyPrice= getPrice();// set the buy price by usign oracle
      uint256 previousprice= (withdraw_amount.mul(FToken.zapWei_spent(msg.sender))).div(FToken.balanceOf(msg.sender));
      uint256 currentprice = withdraw_amount.mul(buyPrice);
      //uint256 withdrawfee =  (currentprice.mul(15)).div(100); //15% fee
        uint256 payment;
      if (currentprice >= previousprice){ //user wins
        uint256 difference = currentprice.sub(previousprice);//somehow send this to the main to tell them to pay the different
        
        // call main withdraw function
        // ask main for difference minus tax

        payment = /*withdraw(difference)*/ buyPrice;
        

      }
      else {//main market win
        uint256 gain= previousprice.sub(currentprice);

        // call main withdraw function
        // give main difference plus tax

        payment = /*withdraw(difference)*/ buyPrice;
      }

      FToken.approve(address(this),withdraw_amount);
      FToken.transferFrom(msg.sender, address(this), withdraw_amount);//(address from, address to, uint tokens)
      zapToken.transfer(msg.sender, payment);

      return 1;
    } 
    else{
      return 0;
    }
  }
}
