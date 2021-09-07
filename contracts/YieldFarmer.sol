pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import '@studydefi/money-legos/dydx/DydxFlashloanBase.sol';
import '@studydefi/money-legos/dydx/contracts/ICallee.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract YieldFarmer is ICallee, DydxFlashloanBase {
    address public owner;

    coonstructor() public {
        //set the address of the owner
        owner = msg.sender;
        
    }
}