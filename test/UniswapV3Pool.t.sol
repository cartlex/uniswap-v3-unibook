// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {console2, Test} from "forge-std/Test.sol";
import {Token} from "./mock/Token.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UniswapV3Pool} from "../src/UniswapV3Pool.sol";
import {ErrorsLib} from "../src/libraries/ErrorsLib.sol";

contract UniswapV3PoolTest is Test {
    Token public token0;
    Token public token1;
    UniswapV3Pool public uniswapV3Pool;
    bool public shouldTransferInCallback;
    bool public testInput;

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
            IERC20(token0).approve(address(this), params.wethBalance);
            IERC20(token1).approve(address(this), params.daiBalance);

            UniswapV3Pool.CallbackData memory extra =
                UniswapV3Pool.CallbackData({token0: address(token0), token1: address(token1), payer: address(this)});

            (uint256 poolBalance0, uint256 poolBalance1) = uniswapV3Pool.mint(
                address(this), params.lowerTick, params.upperTick, params.liquidity, abi.encode(extra)
            );

            return (poolBalance0, poolBalance1);
        }
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

        uint256 expectedAmount0 = 0.99897661834742528 ether;
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
            uniswapV3Pool.mint(address(this), params.lowerTick, params.upperTick, params.liquidity, "");
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
            uniswapV3Pool.mint(address(this), params.lowerTick, params.upperTick, params.liquidity, "");
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
            uniswapV3Pool.mint(address(this), params.lowerTick, params.upperTick, params.liquidity, "");
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

        IERC20(token0).approve(address(this), params.wethBalance);
        IERC20(token1).approve(address(this), params.daiBalance);

        UniswapV3Pool.CallbackData memory extra =
            UniswapV3Pool.CallbackData({token0: address(token0), token1: address(token1), payer: address(this)});

        shouldTransferInCallback = params.shouldTransferInCallback;

        if (params.mintLiquidity) {
            vm.expectRevert("ERC20: transfer amount exceeds balance");
            uniswapV3Pool.mint(address(this), params.lowerTick, params.upperTick, params.liquidity, abi.encode(extra));
        }
    }

    function testSwapBuyEth() public {
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

        uint256 swapAmount = 42 ether;
        token1.mint(address(this), swapAmount);
        IERC20(token1).approve(address(this), swapAmount);

        UniswapV3Pool.CallbackData memory extra =
            UniswapV3Pool.CallbackData({token0: address(token0), token1: address(token1), payer: address(this)});

        int256 userBalance0Before = int256(token0.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) = uniswapV3Pool.swap(address(this), abi.encode(extra));

        assertEq(amount0Delta, -0.008396714242162444 ether);
        assertEq(amount1Delta, 42 ether);

        assertEq(token1.balanceOf(address(this)), 0);
        assertEq(token0.balanceOf(address(this)), uint256(userBalance0Before - amount0Delta));

        assertEq(token0.balanceOf(address(uniswapV3Pool)), uint256(int256(poolBalance0) + amount0Delta));
        assertEq(token1.balanceOf(address(uniswapV3Pool)), uint256(int256(poolBalance1) + amount1Delta));

        (uint160 sqrtPriceX96, int24 tick) = uniswapV3Pool.slot0();

        assertEq(sqrtPriceX96, 5604469350942327889444743441197);
        assertEq(tick, 85184);
    }

    function testInsufficientInputAmount() public {
        testInput = true;

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
        console2.log("Balance of token0", token0.balanceOf(address(this)));
        token1.mint(address(this), 42 ether);

        int256 userBalance0Before = int256(token0.balanceOf(address(this)));

        IERC20(token0).approve(address(this), params.wethBalance);
        IERC20(token1).approve(address(this), params.daiBalance);

        UniswapV3Pool.CallbackData memory extra =
            UniswapV3Pool.CallbackData({token0: address(token0), token1: address(token1), payer: address(this)});

        vm.expectRevert(ErrorsLib.InsufficientInputAmount.selector);
        (int256 amount0Delta, int256 amount1Delta) = uniswapV3Pool.swap(address(this), abi.encode(extra));

        testInput = false;
    }

    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata data) public {
        if (shouldTransferInCallback) {
            UniswapV3Pool.CallbackData memory extra = abi.decode(data, (UniswapV3Pool.CallbackData));
            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
            IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
        }
    }

    function uniswapV3SwapCallback(int256 amount0, int256 amount1, bytes calldata data) public {
        if (amount0 > 0) {
            UniswapV3Pool.CallbackData memory extra = abi.decode(data, (UniswapV3Pool.CallbackData));
            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, uint256(amount0));
        }

        if (amount1 > 0) {
            UniswapV3Pool.CallbackData memory extra = abi.decode(data, (UniswapV3Pool.CallbackData));
            if (testInput) {
                IERC20(extra.token1).transferFrom(extra.payer, msg.sender, uint256(amount1) - 1 ether);
            } else {
                IERC20(extra.token1).transferFrom(extra.payer, msg.sender, uint256(amount1));
            }
        }
    }
}
