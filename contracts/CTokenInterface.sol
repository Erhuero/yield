pragma solidity ^0.5.7;

interface CTokenInterface {
  //to lend money
  function mint(uint mintAmount) external returns (uint);
  //get the money back after the lending
  function redeem(uint redeemTokens) external returns (uint);
  function borrow(uint borrowAmount) external returns (uint);
  function repayBorrow(uint repayAmount) external returns (uint);
  //give token number borrowed + interest
  function borrowBalanceCurrent(address account) external returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function underlying() external view returns(address);
}