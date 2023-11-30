// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {FixedPoint96} from "./FixedPoint96.sol";
import {ErrorsLib} from "./ErrorsLib.sol";
import "@prb/math/src/Common.sol";

library Math {
    function calcAmount0Delta(uint160 sqrtPriceAX96, uint160 sqrtPriceBX96, uint128 liquidity)
        internal
        pure
        returns (uint256)
    {
        if (sqrtPriceAX96 > sqrtPriceBX96) {
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);
        }
        
        if (sqrtPriceAX96 == 0) revert ErrorsLib.InvalidSqrtPriceX96();

        uint256 amount0 = divRoundingUp(
            mulDivRoundingUp(
                (uint256(liquidity) << FixedPoint96.RESOLUTION), (sqrtPriceBX96 - sqrtPriceAX96), sqrtPriceBX96
            ),
            sqrtPriceAX96
        );

        return amount0;
    }

    function calcAmount1Delta(uint160 sqrtPriceAX96, uint160 sqrtPriceBX96, uint128 liquidity)
        internal
        pure
        returns (uint256)
    {
        if (sqrtPriceAX96 > sqrtPriceBX96) {
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);
        }

        uint256 amount1 = mulDivRoundingUp(liquidity, (sqrtPriceBX96 - sqrtPriceAX96), FixedPoint96.Q96);

        return amount1;
    }

    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        uint256 result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            if (result >= type(uint256).max) revert ErrorsLib.ResultOverflow();
        }

        return result;
    }

    function divRoundingUp(uint256 numerator, uint256 denominator) internal pure returns (uint256 result) {
        assembly {
            result := add(div(numerator, denominator), gt(mod(numerator, denominator), 0))
        }
    }
}
