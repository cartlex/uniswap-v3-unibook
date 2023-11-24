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
}
