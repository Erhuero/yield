pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import '@studydefi/money-legos/dydx/DydxFlashloanBase.sol';
import '@studydefi/money-legos/dydx/contracts/ICallee.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './Compound.sol';

contract YieldFarmer is ICallee, DydxFlashloanBase {
    enum Direction { DEposit, Withdraw }
    //define whate we wanna do
    struct Operation{
        address token;
        address cToken;
        Direction direction;
        uint amountProvided;
        uint amountBorrowed;
    }
    address public owner;

    coonstructor() public {
        //set the address of the owner
        owner = msg.sender;        
    }

    function openPosition(
        address _solo,
        address _token,
        address _cToken,
        //provide a part of the token we want to invest in the compound
        uint _amountProvided,
        uint _amountBorrowed
    ) external {
        //protect the external function 
        require(msg.sender == only, 'only owner');
          //-2 to pay 2 way for the flashloan
        _initiateFlashloan(_solo, _token, _cToken, Direction.Deposit, _amountProvided - 2, _amountBorrowed);
    }

    function closePosition(
        tion openPosition(
        address _solo,
        address _token,
        address _cToken
    ) external {
        require(msg.sender == only, 'only owner');
        //transfer 2 wei to this contract in order to pay for the flashloan
        IERC20(_token).transferFrom(msg.sender, address(this), 2);
        //claim our comp token as the reward for lender and borrower
        claimComp();
        //get borrow balance
        uint borrowBalance = getBorrowBAlance(_cToken);
        //reimburse
        _initiateFlashloan(_solo, _token, _cToken, Direction.Withdraw, 0, borrowBalance);
        //transfer comp token to the sender of the transaction
        address compAddress = getCompAddress();
        //pointer to the comp token
        IERC20 comp = IERC20(compAddress);
        //get our balance of the comp
        uint compBalance = comp.balanceOf(address(this));
        //transfer to the sender of the transaction
        comp.transfer(msg.sender, compBalance);
        //transfer the underlying token to the sender of the transaction
        //pointer
        IERC20 token = IERC20(_token);
        //get a token balance with the balance function
        uint tokenBalance = token.balance(address(this));
        //transfer token to the sender
        token.transfer(msg.sender, tokenBalance);
    }

    function callFunction(        
        addrress sender,
        //teel us who borrowed the money
        Account.Info memory account,
        bytes memory data
    ) public {
        Operation memory operation = abi.decode(data, (Operation));
        //test amount we provided + amount from the flashloan
        if(operarion.direction == Direction.Deposit) {
            //lend the money to compound
            supply(operation.cToken, operation.amountProvided + operationBorrowed);
            //call the enter market function after we can leverage our collateral in order to borrow
            enterMarket(operation.cToken);
            //defined in Compound.sol, borrow the same amount we borrowed from the flashloan
            borrow(operation.cToken, operation.amountBorrowed);
            //we don't borrow as much as a supply is because with compund it's not possible
            //we use a part of our collateral to cover a borrow
        } else {
            repayBorrow(operation.cToken, operation.amountBorrowed);
            //specify ctoken balance owned by the smart contract
            uint cTokenBalance = getcTokenBalance(operation.cToken);
            //specify how much of the cToken we want to redeem
            //the underlying token will be back in our smart contract after this
            redeem(operation.cToken, cTokenBalance);
        }
      
    }

    function _initiateFlashloan(
    address _solo, 
    //token we want to borrow
    address _token, 
    address _cToken,
    //direction to reimburse money
    Direction _direction,
    uint _amountProvided, 
    //borrowed from the flashloan
    uint _amountBorrowed
  )
    internal
  {
    ISoloMargin solo = ISoloMargin(_solo);

    // Get marketId from token address
    uint256 marketId = _getMarketIdFromTokenAddress(_solo, _token);

    // Calculate repay amount (_amount + (2 wei))
    // Approve transfer from
    //amount we borrow + 2 wei (cost of the flashloan)
    uint256 repayAmount = _getRepaymentAmountInternal(_amountBorrowed);
    IERC20(_token).approve(_solo, repayAmount);

    // 1. Withdraw $
    // 2. Call callFunction(...)
    // 3. Deposit back $
    Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

    operations[0] = _getWithdrawAction(marketId, _amountBorrowed);
    operations[1] = _getCallAction(
        // Encode MyCustomData for callFunction
        abi.encode(Operation({
          token: _token, 
          cToken: _cToken, 
          direction: _direction,
          amountProvided: _amountProvided, 
          amountBorrowed: _amountBorrowed
        }))
    );
    //reimburse the flashloan
    operations[2] = _getDepositAction(marketId, repayAmount);

    Account.Info[] memory accountInfos = new Account.Info[](1);
    accountInfos[0] = _getAccountInfo();
    //initiate the flashloan
    solo.operate(accountInfos, operations);
  }
}