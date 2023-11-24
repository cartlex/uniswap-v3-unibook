// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Tick} from "./libraries/Tick.sol";
import {Position} from "./libraries/Position.sol";
import {ErrorsLib} from "./libraries/ErrorsLib.sol";
import {EventsLib} from "./libraries/EventsLib.sol";

contract UniswapV3Pool {
    using Tick for mapping(int24 => Tick.Info);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;

    int24 private constant MIN_TICK = -887272;
    int24 private constant MAX_TICK = -MIN_TICK;

    address public immutable token0;
    address public immutable token1;

    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
    }

    Slot0 public slot0;

    uint128 public liquidity;

    mapping(int24 => Tick.Info) public ticks;
    mapping(bytes32 => Position.Info) public positions;

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
    function mint(address owner, int24 lowerTick, int24 upperTick, uint128 amount)
        external
        returns (uint256, uint256)
    {
        if (lowerTick >= upperTick || lowerTick < MIN_TICK || upperTick > MAX_TICK) revert ErrorsLib.InvalidTickRange();

        if (amount == 0) revert ErrorsLib.ZeroLiquidity();

        ticks.update(lowerTick, amount);
        ticks.update(upperTick, amount);

        Position.Info storage position = positions.get(owner, lowerTick, upperTick);

        position.update(amount);

        uint256 amount0 = 0.99897661834742528 ether;
        uint256 amount1 = 5000 ether;

        liquidity = liquidity + amount;

        uint256 balance0Before;
        uint256 balance1Before;

        if (amount0 > 0) balance0Before = balance0();
        if (amount1 > 0) balance1Before = balance1();

        IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(
            amount0,
            amount1
        );

        if (amount0 > 0 && balance0Before + amount0 > balance0()) revert ErrorsLib.InsufficientInputAmount();
        if (amount1 > 0 && balance1Before + amount1 > balance1()) revert ErrorsLib.InsufficientInputAmount();

        emit EventsLib.Mint(msg.sender, owner, lowerTick, upperTick, amount, amount0, amount1);
    }

    function balance0() internal view returns (uint256) {
        return IERC20(token0).balanceOf(address(this));
    }

    function balance1() internal view returns (uint256) {
        return IERC20(token1).balanceOf(address(this));
    }
}
