// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./lib/Tick.sol";
import "./lib/Position.sol";

contract UniswapV3Pool {
    using Position for mapping(bytes32 => Position.Info);
    using Tick for mapping(int24 => Tick.Info);
    using Position for Position.Info;

    mapping(int24 => Tick.Info) public ticks;
    mapping(bytes32 => Position.Info) public positions;

    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    address public immutable token0;
    address public immutable token1;

    uint128 public liquidity;

    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
    }

    Slot0 public slot0;

    error InvalidTickRange();
    error ZeroLiquidity();

    constructor(
        address _token0,
        address _token1,
        uint160 _sqrtPriceX96,
        int24 _tick
    ) {
        token0 = _token0;
        token1 = _token1;

        slot0 = Slot0({sqrtPriceX96: _sqrtPriceX96, tick: _tick});
    }

    function mint(
        address _owner,
        int24 _lowerTick,
        int24 _upperTick,
        uint128 _amount
    ) external returns (uint256 amount0, uint256 amount1) {
        if (
            _lowerTick >= _upperTick ||
            _lowerTick < MIN_TICK ||
            _upperTick > MAX_TICK
        ) revert InvalidTickRange();
        if(_amount == 0) revert ZeroLiquidity();

        ticks.update(_lowerTick, _amount);
        ticks.update(_upperTick, _amount);

        Position.Info storage position = positions.get(
            _owner,
            _lowerTick,
            _upperTick
        );

        position.update(_amount);

        amount0 = 0.998976618347425200 ether;
        amount1 = 5000 ether;

        liquidity += uint128(_amount);

    }
}