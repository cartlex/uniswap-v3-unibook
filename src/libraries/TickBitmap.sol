// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ErrorsLib} from "./ErrorsLib.sol";
import {BitMath} from "./BitMath.sol";

library TickBitmap {
    function position(int24 tick) private pure returns (int16, uint8) {
        int16 wordPos = int16(tick >>  8);
        uint8 bitPos = uint8(uint24(tick % 256));
        return (wordPos, bitPos);
    }

    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing 
    ) internal {
        if (tick % tickSpacing != 0) revert ErrorsLib.TickNotSpaced();
        (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;
    }

    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24, bool) {
        int24 compressed = tick / tickSpacing;

        if (lte) {
            (int16 wordPos, uint8 bitPos) = position(compressed);
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = self[wordPos] & mask;

            bool initialized = masked != 0;
            int24 next = initialized
                ? (compressed - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))) * tickSpacing
                : (compressed - int24(uint24(bitPos))) * tickSpacing;
            
            return (next, initialized);
        } else {
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;

            bool initialized = masked != 0;
            int24 next = initialized
                ? (compressed + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
                : (compressed - int24(uint24((type(uint8).max - bitPos)))) * tickSpacing;
            
            return (next, initialized);
        }
    }
}