// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

library ErrorsLib {
    error InvalidTickRange();
    error ZeroLiquidity();
    error InsufficientInputAmount();
    error TickNotSpaced();
    error InvalidSqrtPriceX96();
    error ResultOverflow();
}
