// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";

contract UniswapV3Manager {
    function mint(address poolAddress, int24 lowerTick, int24 upperTick, uint128 liquidity, bytes calldata data)
        public
    {
        IUniswapV3Pool(poolAddress).mint(msg.sender, lowerTick, upperTick, liquidity, data);
    }

    function swap(address poolAddress, bytes calldata data) public {
        IUniswapV3Pool(poolAddress).swap(msg.sender, data);
    }

    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata data) external {
        IUniswapV3Pool.CallbackData memory extra = abi.decode(data, (IUniswapV3Pool.CallbackData));
        if (amount0 > 0) {
            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
        }
    }

    function uniswapV3SwapCallback(uint256 amount0, uint256 amount1, bytes calldata data) external {
        IUniswapV3Pool.CallbackData memory extra = abi.decode(data, (IUniswapV3Pool.CallbackData));
        if (amount0 > 0) {
            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
        }

        if (amount1 > 0) {
            IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
        }
    }
}
