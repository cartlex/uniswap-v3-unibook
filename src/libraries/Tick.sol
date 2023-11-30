// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Tick {
    struct Info {
        bool initialized;
        uint128 liquidity;
    }

    function update(mapping(int24 => Tick.Info) storage self, int24 tick, uint128 liquidityDelta) internal returns (bool) {
        Tick.Info storage tickInfo = self[tick];

        uint128 liquidityBefore = tickInfo.liquidity;
        uint128 liquidityAfter = liquidityBefore + liquidityDelta;
        bool flipped = (liquidityAfter == 0) != (liquidityBefore == 0);

        if (liquidityBefore == 0) {
            tickInfo.initialized = true;
        }

        tickInfo.liquidity = liquidityAfter;

        return flipped;
    }
}
