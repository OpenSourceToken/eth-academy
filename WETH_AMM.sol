// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./WETH.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

contract WETH_AMM is ERC20 {
    using Math for uint256;
    using SignedMath for int256;

    WETH public weth;
    IERC20 public token1;

    uint public reserve0;
    uint public reserve1;
 
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1);
    event Swap(
        address indexed sender,
        uint256 amountIn,
        address tokenIn,
        uint256 amountOut,
        address tokenOut
        );

    constructor(address _token) ERC20("WETH AMM LP Token", "WETH-AMM") {
        weth = new WETH();
        token1 = IERC20(_token);
    }

    function addLiquidity(uint256 amount0Desired, uint256 amount1Desired) public returns(uint256 liquidity){
        weth.deposit{value: amount0Desired}();
        weth.transferFrom(msg.sender, address(this), amount0Desired);
        token1.transferFrom(msg.sender, address(this), amount1Desired);

        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {

            liquidity = (amount0Desired * amount1Desired).sqrt();
        } else {

            (, uint liquidityL) = amount0Desired.tryMul(_totalSupply);
            (, liquidityL) = liquidityL.tryDiv(reserve0);
            
            (, uint liquidityR) = amount1Desired.tryMul(_totalSupply);
            (, liquidityR) = liquidityR.tryDiv(reserve1);

            liquidity = liquidityL.min(liquidityR);
        }

        require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');

        reserve0 = weth.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        _mint(msg.sender, liquidity);
        
        emit Mint(msg.sender, amount0Desired, amount1Desired);
    }

    function removeLiquidity(uint256 liquidity) external returns (uint256 amount0, uint256 amount1) {
        uint256 balance0 = weth.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));

        uint256 _totalSupply = totalSupply();
        (, amount0) = liquidity.tryMul(balance0);
        (, amount0) = amount0.tryDiv(_totalSupply);

        (, amount1) = liquidity.tryMul(balance1);
        (, amount1) = amount1.tryDiv(_totalSupply);

        require(amount0 > 0 && amount1 > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');

        _burn(msg.sender, liquidity);

        weth.withdraw(amount0);
        payable(msg.sender).transfer(amount0);
        token1.transfer(msg.sender, amount1);

        reserve0 = weth.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Burn(msg.sender, amount0, amount1);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256 amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        (, uint amountL) = amountIn.tryMul(reserveOut);
        (, uint amountR) = reserveIn.tryAdd(amountIn);
        (, amountOut) = amountL.tryDiv(amountR);
    }

    function swap(uint256 amountIn, IERC20 tokenIn, uint256 amountOutMin) external payable returns (uint256 amountOut, IERC20 tokenOut){
        require(amountIn > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(tokenIn == weth || tokenIn == token1, 'INVALID_TOKEN');
        
        uint256 balance0 = weth.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));

        if(tokenIn == weth){
            tokenOut = token1;
            amountOut = getAmountOut(amountIn, balance0, balance1);
            require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');

            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            weth.deposit{value: amountIn}();
            tokenOut.transfer(msg.sender, amountOut);
        }else{
            tokenOut = weth;
            amountOut = getAmountOut(amountIn, balance1, balance0);
            require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            payable(msg.sender).transfer(amountOut);
            weth.withdraw(amountOut);
        }

        reserve0 = weth.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
    }
}
