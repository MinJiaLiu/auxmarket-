
pragma solidity ^0.4.24;
import "./FixedSupplyToken.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";
import "../lib/ownership/ZapCoordinator.sol";
import "../token/ZapToken.sol";


contract Market {


  using SafeMath for uint256;
  address main; // main market address
  mapping (address => uint256) private zapspent; //amount of zap that a msg.sender has spent in buying Token
  uint256 buyPrice; //current price per zap/btc
  ZapToken public zapToken;
  ZapCoordinatorInterface public coordinator;
  address fixsupplyaddress;
  FixedSupplyToken public FToken;



  constructor(address _coordinator) public {
      coordinator = ZapCoordinatorInterface(_coordinator);
      address zapTokenAddress = coordinator.getContract("ZAP_TOKEN");
      /* main= coordinator.getContract("MainMarket"); */
      fixsupplyaddress = coordinator.getContract("FixedSupplyToken");
      FToken= FixedSupplyToken(fixsupplyaddress);
      zapToken = ZapToken(zapTokenAddress);

  }

//returns the current price of zap to bitcoing
  function getPrice () public pure returns (uint256){
    return 2; //need to change to match oracle
  }
//buying token
  function BuyToken (uint256 numberoftoken) public payable returns(uint256){

    buyPrice = getPrice();//set it to the new price using oracle ;
    uint256 zaprequire = numberoftoken.mul(buyPrice);
    if (zapToken.balanceOf(msg.sender) >= zaprequire){  //check if msg.sender has enough zap
      zapToken.transferFrom(msg.sender,address(this),zaprequire);  //transferFrom(address from, address to, uint256 value)
      zapspent[msg.sender]= zapspent[msg.sender].add(zaprequire);  //add the amount spent to the msg.sender
      FToken.transfer(msg.sender,numberoftoken); // sends token to zap

      return numberoftoken;
    }
    else{
      return 0;
    }

  }

//return the number of token a person has
  function getBalance () public view returns (uint256){
    return FToken.balanceOf(msg.sender) ;
  }

//withrawn an amount of Token
  function Withdrawn (uint256 withdraw_amount) public payable returns (string memory ) {
    if (FToken.balanceOf(msg.sender) >= withdraw_amount){ //check if msg.sender has enough token
    buyPrice= getPrice();// set the buy price by usign oracle
    uint256 ratio = withdraw_amount.div(FToken.balanceOf(msg.sender));
    uint256 previousprice= ratio.mul(zapspent[msg.sender]);
    uint256 currentprice = withdraw_amount.mul(buyPrice) ;
    uint256 withdrawfee =  currentprice.mul(1); //WITHDRAWN FEE IS CURRENTLY INCORRECT OKAY
    if (currentprice >= previousprice){
      uint256 difference = currentprice.sub( previousprice);//somehow send this to the main to tell them to pay the different
      zapToken.transferFrom(address(this),msg.sender,previousprice);
      zapToken.transferFrom(main,msg.sender,difference);

    }
    else {
      uint256 gain= previousprice.sub(currentprice);
      zapToken.transferFrom(address(this),msg.sender,currentprice);
      zapToken.transferFrom(address(this),main,gain);



    }
    FToken.transferFrom(msg.sender, fixsupplyaddress,withdraw_amount);//(address from, address to, uint tokens)
    zapToken.transferFrom(msg.sender,main,withdrawfee);

    return "withdraw complete. ";
    }

    else{
      return "not a valid amount to withdraw";
    }
  }
}
