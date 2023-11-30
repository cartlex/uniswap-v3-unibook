// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IUniswapV3Pool {
    struct CallbackData {
        address token0;
        address token1;
        address payer;
    }
}