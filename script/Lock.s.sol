// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import {Script, console} from "lib/forge-std/src/Script.sol";
// import {TokenLock} from "../src/lock.sol";
// import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// contract TokenLockScript is Script {
//     TokenLock public token_lock;

//     function setUp() public {}

//     function run() public {
//         // 获取部署者私钥
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         vm.startBroadcast(deployerPrivateKey);

//         // 获取要锁定的 token 地址
//         address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
//         IERC20 token = IERC20(tokenAddress);

//         // 部署锁仓合约
//         token_lock = new TokenLock(token);

//         // 输出部署地址
//         console.log("TokenLock deployed at:", address(token_lock));

//         vm.stopBroadcast();
//     }
// }
