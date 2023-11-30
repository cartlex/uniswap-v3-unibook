// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {console2, Script} from "forge-std/Script.sol";
import {Token} from "test/mock/Token.sol";
import {UniswapV3Pool} from "src/UniswapV3Pool.sol";
import {UniswapV3Manager} from "src/UniswapV3Manager.sol";


contract DeployDevelopment is Script {
    function run() public {
        Token token0;
        Token token1;
        UniswapV3Pool uniswapV3Pool;
        UniswapV3Manager uniswapV3Manager;

        uint256 wethBalance = 1 ether;
        uint256 daiBalance = 5042 ether;
        int24 currentTick = 85176;
        uint160 currentSqrtP = 5602277097478614198912276234240;

        vm.startBroadcast();

        token0 = new Token("Ether", "ETH");
        token1 = new Token("DAI", "DAI");

        uniswapV3Pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            currentSqrtP,
            currentTick
        );

        uniswapV3Manager = new UniswapV3Manager();

        token0.mint(msg.sender, wethBalance);
        token1.mint(msg.sender, daiBalance);

        console2.log("WETH address:", address(token0));
        console2.log("DAI address:", address(token1));
        console2.log("Pool address:", address(uniswapV3Pool));
        console2.log("Manager address:", address(uniswapV3Manager));

        vm.stopBroadcast();
    }
}