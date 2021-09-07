pragma solidity ^0.5.7;

interface ComptrollerInterface {
  //call this before able to borrow
  function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
  //claim token reward as the participant
  function claimComp(address holder) external;
  //address of comp token
  function getCompAddress() external view returns(address);
}