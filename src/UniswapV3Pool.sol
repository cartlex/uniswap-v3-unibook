// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV3MintCallback} from "./interfaces/IUniswapV3MintCallback.sol";
import {IUniswapV3SwapCallback} from "./interfaces/IUniswapV3SwapCallback.sol";
import {Tick} from "./libraries/Tick.sol";
import {TickBitmap} from "./libraries/TickBitmap.sol";
import {Position} from "./libraries/Position.sol";
import {TickMath} from "./libraries/TickMath.sol";
import {Math} from "./libraries/Math.sol";
import {ErrorsLib} from "./libraries/ErrorsLib.sol";
import {EventsLib} from "./libraries/EventsLib.sol";

contract UniswapV3Pool {
    using Tick for mapping(int24 => Tick.Info);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;
    using TickBitmap for mapping(int16 => uint256);

    int24 private constant MIN_TICK = -887272;
    int24 private constant MAX_TICK = -MIN_TICK;

    address public immutable token0;
    address public immutable token1;

    struct CallbackData {
        address token0;
        address token1;
        address payer;
    }

    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
    }

    Slot0 public slot0;

    uint128 public liquidity;

    mapping(int24 => Tick.Info) public ticks;
    mapping(bytes32 => Position.Info) public positions;
    mapping(int16 => uint256) public tickBitmap;

    constructor(address token0_, address token1_, uint160 sqrtPriceX96, int24 tick) {
        token0 = token0_;
        token1 = token1_;

        slot0 = Slot0({sqrtPriceX96: sqrtPriceX96, tick: tick});
    }

    /**
     * @param owner Owner of the provided liqudity
     * @param lowerTick Lower bound of the price range in which owner provide liquidity
     * @param upperTick Upper bound of the price range in which owner provide liquidity
     * @param amount Amount of liquidity to provide
     */
    function mint(address owner, int24 lowerTick, int24 upperTick, uint128 amount, bytes calldata data)
        external
        returns (uint256, uint256)
    {
        if (lowerTick >= upperTick || lowerTick < MIN_TICK || upperTick > MAX_TICK) revert ErrorsLib.InvalidTickRange();

        if (amount == 0) revert ErrorsLib.ZeroLiquidity();

        bool flippedLower = ticks.update(lowerTick, amount);
        bool flippedUpper = ticks.update(upperTick, amount);

        if (flippedLower) {
            tickBitmap.flipTick(lowerTick, 1);
        }

        if (flippedUpper) {
            tickBitmap.flipTick(upperTick, 1);
        }

        Position.Info storage _position = positions.get(owner, lowerTick, upperTick);

        _position.update(amount);

        Slot0 memory slot0_ = slot0;

        uint256 amount0 = Math.calcAmount0Delta(
            slot0_.sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(upperTick),
            amount
        );

        uint256 amount1 = Math.calcAmount1Delta(
            slot0_.sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(lowerTick),
            amount
        );

        liquidity = liquidity + amount;

        uint256 balance0Before;
        uint256 balance1Before;

        if (amount0 > 0) balance0Before = balance0();
        if (amount1 > 0) balance1Before = balance1();

        IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(amount0, amount1, data);

        if (amount0 > 0 && balance0Before + amount0 > balance0()) revert ErrorsLib.InsufficientInputAmount();
        if (amount1 > 0 && balance1Before + amount1 > balance1()) revert ErrorsLib.InsufficientInputAmount();

        emit EventsLib.Mint(msg.sender, owner, lowerTick, upperTick, amount, amount0, amount1);

        return (amount0, amount1);
    }

    function swap(address recipient, bytes calldata data) public returns (int256, int256) {
        int24 nextTick = 85184;
        uint160 nextPrice = 5604469350942327889444743441197;

        int256 amount0 = -0.008396714242162444 ether;
        int256 amount1 = 42 ether;

        (slot0.tick, slot0.sqrtPriceX96) = (nextTick, nextPrice);
        IERC20(token0).transfer(recipient, uint256(-amount0));

        uint256 balance1Before = balance1();
        IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(amount0, amount1, data);

        if (balance1Before + uint256(amount1) > balance1()) revert ErrorsLib.InsufficientInputAmount();

        emit EventsLib.Swap(msg.sender, recipient, amount0, amount1, slot0.sqrtPriceX96, liquidity, slot0.tick);

        return (amount0, amount1);
    }

    function balance0() internal view returns (uint256) {
        return IERC20(token0).balanceOf(address(this));
    }

    function balance1() internal view returns (uint256) {
        return IERC20(token1).balanceOf(address(this));
    }
}
