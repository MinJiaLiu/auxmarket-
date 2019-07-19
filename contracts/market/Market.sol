pragma solidity ^0.4.24;
import "./FixedSupplyToken.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";
import "../lib/ownership/ZapCoordinator.sol";
import "../token/ZapToken.sol";

// Zap contracts's methods that subscriber can call knowing the addresses
contract ZapBridge{
    function getContract(string memory contractName) public view returns (address); //coordinator
    function bond(address provider ,bytes32 endpoint, uint256 dots) public;
    function unbond(address provider ,bytes32 endpoint, uint256 dots) public;
    function calcZapForDots(address provider, bytes32 endpoint, uint256 dots) external view returns (uint256); //bondage
    function delegateBond(address holderAddress, address oracleAddress, bytes32 endpoint, uint256 numDots) external returns (uint256 boundZap); //bondage
    function query(address provider, string calldata queryString, bytes32 endpoint, bytes32[] calldata params) external returns (uint256); //dispatch
    function approve(address bondage, uint256 amount) public returns (bool); // Zap Token
}

contract Subscriber {

    address public owner;
    ZapBridge public coordinator;
    address provider;
    bytes32 endpoint;
    uint256 query_id;

    event ReceiveResponse(uint256 indexed id, int indexed result);


    //Coordinator contract is one single contract that
    //knows all other Zap contract addresses
    constructor(address _coordinator, address _provider, bytes32 _endpoint) public{
        owner = msg.sender;
        coordinator = ZapBridge(_coordinator);
        provider = _provider;
        endpoint = _endpoint;
    }

    //This function call can be skipped if owner approve and delegateBond for this contract
    function approve(uint256 amount) public returns (bool){
      address ZapTokenAddress = coordinator.getContract("ZAP_TOKEN");
      address BondageAddress = coordinator.getContract("BONDAGE");
      return ZapBridge(ZapTokenAddress).approve(BondageAddress,amount);

    }

    //This function call can be ommitted if owner call delegateBond directly to Bondage contract
    //Contract has to hold enough zap approved
    function bond(uint256 dots) public{
        address BondageAddress = coordinator.getContract("BONDAGE");
        return ZapBridge(BondageAddress).bond(provider,endpoint,dots);
    }

    //This function call can be ommitted if owner call delegateBond directly to Bondage
    function unbond(uint256 dots) public{
        address BondageAddress = coordinator.getContract("BONDAGE");
        return ZapBridge(BondageAddress).bond(provider,endpoint,dots);
    }

    //Query offchain or onchain provider.
    function query(string memory queryString, bytes32[] memory params) public returns (uint256) {
        address dispatchAddress = coordinator.getContract("DISPATCH");
        query_id = ZapBridge(dispatchAddress).query(provider,queryString,endpoint,params);
        return query_id;
    }

    //Implementing callback that will accept provider's respondIntArray
    //Response method options  are  :respondBytes32Array, respondIntArray, respond1, respond2, respond3, respond4
    function callback(uint256 _id, int _response) external;

        //Implement your logic with _response data her

}


contract Market is Subscriber {


  using SafeMath for uint256;

  //address public main; // main market address

  ZapToken public zapToken;
  ZapCoordinatorInterface public ccoordinator;

  address public fixsupplyaddress;
  FixedSupplyToken public FToken;
  uint256  public buyPrice;
  MainMarket public main;


  //address public oracleAddress; // address of account operating oracle

  event GetPriceEvent(uint256 amount);
  event PriceUpdated(uint256 amount);

  constructor(address _ccoordinator,address _coordinator, address _provider, bytes32 _endpoint) Subscriber(address _coordinator, address _provider, bytes32 _endpoint_)public {
      ccoordinator = ZapCoordinatorInterface(_ccoordinator);
      address zapTokenAddress = ccoordinator.getContract("ZAP_TOKEN");
      mainmarket= ccoordinator.getContract("MainMarket");
      fixsupplyaddress = ccoordinator.getContract("FixedSupplyToken");
      FToken= FixedSupplyToken(fixsupplyaddress);
      zapToken = ZapToken(zapTokenAddress);
      main= MainMarket(mainmarket);
      Ftoken.transfer(address(this),_totalSupply);

  }

//returns the current price of zap to token
  function getPrice (uint256 amount) public returns (uint256){
  //e/btc divided e/zapwe
    emit GetPriceEvent(uint256 amount );
    return uint8(uint256(keccak256(block.timestamp, block.difficulty))%131) * 1000000000000000 + 100000000000000000 ; //need to change to match oracle
  }

//return the number of token a person has
  function getAMTBalance (address _user) public view returns (uint256){
    return FToken.balanceOf(_user) ;
  }



  function getZapBalance (address _user) public view returns (uint256) {
    return zapToken.balanceOf(_user);
  }

// funtion oracle calls to update the price
  function updatePrice (uint _price) public {

    buyPrice = _price;
    emit PriceUpdated(_price);
  }

  function getGainOrLoss (uint256 withdraw_amount ,address _user) public view returns (int256){
          buyPrice= getPrice();// set the buy price by usign oracle
          uint256 previousprice= (withdraw_amount.mul(FToken.zapWei_spent(msg.sender))).div(FToken.balanceOf(msg.sender));
          uint256 currentprice = withdraw_amount.mul(buyPrice);
          uint256 difference = currentprice.sub(previousprice);
          return difference;


  }

//buying token
  function buy (uint256 numberoftoken) public returns(uint256){

    buyPrice = getPrice();//set it to the new price using oracle ;
    uint256 zaprequire = numberoftoken.mul(buyPrice);
  //check if msg.sender has enoughg
    /* zapToken.approve(address(this),zaprequire); //address _spender, uint256 _valu */


    zapToken.transferFrom(msg.sender,address(this),zaprequire);  //transferFrom(address from, address to, uint256 value)
    FToken.transfer(msg.sender,numberoftoken); // sends token to zap

    return numberoftoken;
  }

//withrawn an amount of Token
  function Withdrawn (uint256 withdraw_amount) public payable returns (bool success) {
      FToken.transferFrom(msg.sender, address(this), withdraw_amount) //also checks if u have enough
      buyPrice= getPrice();
      payment = buyPrice.mul(withdraw_amount);
      main.withdraw(payment,msg.sender);
      return true;

  }
}
