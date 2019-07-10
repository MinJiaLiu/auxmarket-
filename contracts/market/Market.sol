
pragma solidity ^0.4.24;
import "./FixedSupplyToken.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";
import "../lib/ownership/ZapCoordinator.sol";
import "../token/ZapToken.sol";


contract Market {


  using SafeMath for uint256;
  address main; // main market address
  ZapToken public zapToken;
  ZapCoordinatorInterface public coordinator;
  address fixsupplyaddress;
  FixedSupplyToken public FToken;
  uint256  public buyPrice ;

  constructor(address _coordinator) public {
      coordinator = ZapCoordinatorInterface(_coordinator);
      address zapTokenAddress = coordinator.getContract("ZAP_TOKEN");
      /* main= coordinator.getContract("MainMarket"); */
      fixsupplyaddress = coordinator.getContract("FixedSupplyToken");
      FToken= FixedSupplyToken(fixsupplyaddress);
      zapToken = ZapToken(zapTokenAddress);

  }

//returns the current price of zap to token
  function getPrice () public pure returns (uint256){
  //e/btc divided e/zapwe
    return 2; //need to change to match oracle
  }

//buying token
  function BuyToken (uint256 numberoftoken) public returns(uint256){

    buyPrice = getPrice();//set it to the new price using oracle ;
    uint256 zaprequire = numberoftoken.mul(buyPrice);
  //check if msg.sender has enough zap
    zapToken.approve(address(this),zaprequire); //address _spender, uint256 _valu
    zapToken.transferFrom(msg.sender,address(this),zaprequire);  //transferFrom(address from, address to, uint256 value)
    FToken.transfer(msg.sender,numberoftoken); // sends token to zap

      return numberoftoken;
    }


//return the number of token a person has
  function getBalance () public view returns (uint256){
    return FToken.balanceOf(msg.sender) ;
  }

//withrawn an amount of Token
  function Withdrawn (uint256 withdraw_amount) public payable returns (string memory ) {
    if (FToken.balanceOf(msg.sender) >= withdraw_amount){ //check if msg.sender has enough token
    buyPrice= getPrice();// set the buy price by usign oracle
    uint256 previousprice= (withdraw_amount.mul(FToken.zapWei_spent(msg.sender))).div(FToken.balanceOf(msg.sender));
    uint256 currentprice = withdraw_amount.mul(buyPrice) ;
    uint256 withdrawfee =  (currentprice.mul(15)).div(100); //15% fee
    if (currentprice >= previousprice){ //user wins
      uint256 difference = currentprice.sub( previousprice);//somehow send this to the main to tell them to pay the different
      zapToken.transfer(msg.sender,previousprice);

      zapToken.transferFrom(main,msg.sender,difference);

    }
    else {//main market win
      uint256 gain= previousprice.sub(currentprice);
      zapToken.transfer(msg.sender,currentprice);
      zapToken.transferFrom(address(this),main,gain);



    }
    FToken.approve(address(this),withdraw_amount);
    FToken.transferFrom(msg.sender, fixsupplyaddress,withdraw_amount);//(address from, address to, uint tokens)
    zapToken.transferFrom(msg.sender,main,withdrawfee);

    return "withdraw complete. ";
    }

    else{
      return "not a valid amount to withdraw";
    }
  }
}
