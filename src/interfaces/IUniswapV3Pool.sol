// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IUniswapV3Pool {
    struct CallbackData {
        address token0;
        address token1;
        address payer;
    }

    function mint(address owner, int24 lowerTick, int24 upperTick, uint128 amount, bytes calldata data) external;
    
    function swap(address recipient, bytes calldata data) external returns (int256, int256);
}