// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library EventsLib {
    event Mint(
        address caller,
        address owner,
        int24 lowerTick,
        int24 upperTick,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    event Swap(
        address sender,
        address recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );
}
