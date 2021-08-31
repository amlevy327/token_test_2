// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma abicoder v2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

import '@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';

contract Token is ERC20 {

  using SafeMath for uint256;

  address public customTokenAddress = address(this);
  address public WETH9;

  uint24 public poolFee = 10000;
  uint160 public testSqrtPriceX96 = 79228162514264337593543950336; // = 1?

  IPeripheryImmutableState public peripheryImmutableState = IPeripheryImmutableState(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  IUniswapV3Factory public uniFactory;
  IUniswapV3Pool public uniPool; 
  IWETH9 public uniWETH9;
  INonfungiblePositionManager public immutable nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

  uint256 public amountToken = 50000000000000000;
  uint256 public amountWETH = 50000000000000000;
  uint256 public amountWETHTransfer;

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
    _mint(msg.sender, 100000000000000000000);
    WETH9 = peripheryImmutableState.WETH9();
    uniWETH9 = IWETH9(WETH9);
    uniFactory = IUniswapV3Factory(peripheryImmutableState.factory());
  }

  // TRANSFERS 

  // transfer tokens to contract
  function transferTokensToContract() external {
    transfer(address(this), amountToken);
  }

  // deposit ETH, wrap, transfer
  function deposit() external payable {
    require(msg.value > 0);
    amountWETHTransfer = msg.value;
    uniWETH9.deposit{value: msg.value}();
    uniWETH9.transfer(msg.sender, amountWETHTransfer);
  }
  function transferToSender() external {
    uniWETH9.transfer(msg.sender, amountWETHTransfer);
  }
  
  // UNISWAP

  // create uniswap pool
  function createUniPool() external {
    uniPool = IUniswapV3Pool(uniFactory.createPool(customTokenAddress, WETH9, poolFee));
  }

  // initialize uniswap pool
  function initUniPool() external {
    uniPool.initialize(testSqrtPriceX96);
  }

  // get pool - check
  function getUniPool() external {
    uniPool = IUniswapV3Pool(uniFactory.getPool(customTokenAddress, WETH9, poolFee));
  }

  // approve manager
  function approveManagerWETH() external {
    // sends from this address - need to approve manually from account
    uniWETH9.approve(address(nonfungiblePositionManager), amountWETH);
  }
  function approveManagerToken() external {
    approve(address(nonfungiblePositionManager), amountToken);
  }

  // mint position - using inputs to get corredt order of tokens
  function mintPosition(address _token0, address _token1, uint24 _fee, uint256 _amountToken0, uint256 _amountToken1) external returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        ){
    INonfungiblePositionManager.MintParams memory params =
      INonfungiblePositionManager.MintParams({
          token0: _token0,
          token1: _token1,
          fee: _fee,
          tickLower: TickMath.MIN_TICK,
          tickUpper: TickMath.MAX_TICK,
          amount0Desired: _amountToken0,
          amount1Desired: _amountToken1,
          amount0Min: 0,
          amount1Min: 0,
          recipient: msg.sender,
          // recipient: address(this),
          deadline: block.timestamp
      });

    // pool must already be created and initialized in order to mint
    (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);
  }
}