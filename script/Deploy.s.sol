// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "src/AtomicSwap.sol";
import "src/Token.sol";

contract Deploy is Script {
    AtomicSwap atomicSwap;
    Token tokenX;
    Token tokenY;
    uint256 constant SUPPLY = 1000000000;

    function run() public {
        vm.startBroadcast();
        deploy();
        vm.stopBroadcast();
    }

    function deploy() public {
        tokenX = new Token("TokenX", "X", SUPPLY);
        tokenY = new Token("TokenY", "Y", SUPPLY);
        atomicSwap = new AtomicSwap();
    }
}