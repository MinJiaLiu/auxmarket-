<<<<<<< HEAD
pragma solidity ^0.4.24;

import "../ownership/Ownable.sol";

contract Destructible is Ownable {
    function selfDestruct() public onlyOwner {
        selfdestruct(owner);
    }
}
=======
pragma solidity ^0.4.24;

import "../ownership/Ownable.sol";

contract Destructible is Ownable {
    function selfDestruct() public onlyOwner {
        selfdestruct(owner);
    }
}
>>>>>>> origin/HelloBranch
