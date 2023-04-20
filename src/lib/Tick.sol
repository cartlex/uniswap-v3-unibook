// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Tick {
    struct Info {
        bool initialized;
        uint128 liquidity;
    }

    function update(
        mapping(int24 => Info) storage self,
        int24 _tick,
        uint128 _liquidityDelta
    ) internal {
        Info storage tickInfo = self[_tick];
        uint128 liquidtyBefore = tickInfo.liquidity;
        uint128 liquidtyAfter = liquidtyBefore + _liquidityDelta;

        if(liquidtyBefore == 0) {
            tickInfo.initialized = true;
        }

        tickInfo.liquidity = liquidtyAfter;
    }

}