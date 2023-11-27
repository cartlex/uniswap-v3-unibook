// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Token} from "./Mock/Token.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UniswapV3Pool} from "../src/UniswapV3Pool.sol";
import {ErrorsLib} from "../src/libraries/ErrorsLib.sol";

contract UniswapV3PoolTest is Test {
    Token public token0;
    Token public token1;
    UniswapV3Pool public uniswapV3Pool;
    bool public shouldTransferInCallback;

    struct TestCaseParams {
        uint256 wethBalance;
        uint256 daiBalance;
        int24 currentTick;
        int24 lowerTick;
        int24 upperTick;
        uint128 liquidity;
        uint160 currentSqrtP;
        bool shouldTransferInCallback;
        bool mintLiquidity;
    }

    function setUp() public {
        token0 = new Token("Ether", "ETH");
        token1 = new Token("DAI", "DAI");
    }

    function testMintSuccess() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            daiBalance: 5000 ether,
            currentTick: 85176,
            lowerTick: 84222,
            upperTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });

        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        uint256 expectedAmount0 = 0.998976618347425280 ether;
        uint256 expectedAmount1 = 5000 ether;

        assertEq(poolBalance0, expectedAmount0);
        assertEq(poolBalance1, expectedAmount1);

        assertEq(token0.balanceOf(address(uniswapV3Pool)), expectedAmount0);
        assertEq(token1.balanceOf(address(uniswapV3Pool)), expectedAmount1);

        bytes32 positionKey = keccak256(abi.encodePacked(address(this), params.lowerTick, params.upperTick));

        uint128 positionLiquidity = uniswapV3Pool.positions(positionKey);
        assertEq(positionLiquidity, params.liquidity);

        (bool tickInitialized, uint128 tickLiquidity) = uniswapV3Pool.ticks(params.lowerTick);

        assertTrue(tickInitialized);
        assertEq(tickLiquidity, params.liquidity);

        (tickInitialized, tickLiquidity) = uniswapV3Pool.ticks(params.upperTick);

        assertTrue(tickInitialized);
        assertEq(tickLiquidity, params.liquidity);

        (uint160 sqrtPriceX96, int24 tick) = uniswapV3Pool.slot0();
        assertEq(sqrtPriceX96, params.currentSqrtP);
        assertEq(tick, params.currentTick);

        uint128 poolLiqudity = uniswapV3Pool.liquidity();
        assertEq(poolLiqudity, params.liquidity);
    }

    function testLowerTickOutOfRange() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            daiBalance: 5000 ether,
            currentTick: 85176,
            lowerTick: -887273,
            upperTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });

        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.daiBalance);
        
        uniswapV3Pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            params.currentSqrtP,
            params.currentTick
        );

        shouldTransferInCallback = params.shouldTransferInCallback;

        if (params.mintLiquidity) {
            vm.expectRevert(ErrorsLib.InvalidTickRange.selector);
            uniswapV3Pool.mint(address(this), params.lowerTick, params.upperTick, params.liquidity);
        }
    }

    function testUpperTickOutOfRange() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            daiBalance: 5000 ether,
            currentTick: 85176,
            lowerTick: 84222,
            upperTick: 887273,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });

        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.daiBalance);
        
        uniswapV3Pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            params.currentSqrtP,
            params.currentTick
        );

        shouldTransferInCallback = params.shouldTransferInCallback;

        if (params.mintLiquidity) {
            vm.expectRevert(ErrorsLib.InvalidTickRange.selector);
            uniswapV3Pool.mint(address(this), params.lowerTick, params.upperTick, params.liquidity);
        }
    }

    function testZeroLiquidity() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            daiBalance: 5000 ether,
            currentTick: 82000,
            lowerTick: 87992,
            upperTick: 99000,
            liquidity: 0,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });

        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.daiBalance);
        
        uniswapV3Pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            params.currentSqrtP,
            params.currentTick
        );

        shouldTransferInCallback = params.shouldTransferInCallback;

        if (params.mintLiquidity) {
            vm.expectRevert(ErrorsLib.ZeroLiquidity.selector);
            uniswapV3Pool.mint(address(this), params.lowerTick, params.upperTick, params.liquidity);
        }
    }

    function testProviderDoesntHaveEnoughTokens() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            daiBalance: 5000 ether,
            currentTick: 82000,
            lowerTick: 87992,
            upperTick: 99000,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });

        uniswapV3Pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            params.currentSqrtP,
            params.currentTick
        );

        shouldTransferInCallback = params.shouldTransferInCallback;

        if (params.mintLiquidity) {
            vm.expectRevert("ERC20: transfer amount exceeds balance");
            uniswapV3Pool.mint(address(this), params.lowerTick, params.upperTick, params.liquidity);
        }
    }

    function setupTestCase(TestCaseParams memory params) internal returns (uint256, uint256) {
        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.daiBalance);
        
        uniswapV3Pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            params.currentSqrtP,
            params.currentTick
        );

        shouldTransferInCallback = params.shouldTransferInCallback;

        if (params.mintLiquidity) {
            (uint256 poolBalance0, uint256 poolBalance1) =
                uniswapV3Pool.mint(address(this), params.lowerTick, params.upperTick, params.liquidity);

            return (poolBalance0, poolBalance1);
        }
    }

    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata data) public {
        if (shouldTransferInCallback) {
            IERC20(token0).transfer(msg.sender, amount0);
            IERC20(token1).transfer(msg.sender, amount1);
        }
    }
}
