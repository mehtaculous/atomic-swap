// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "src/erc20/Token.sol";

contract DeployToken is Script {
    Token token;
    string constant NAME = "Fungible Token";
    string constant SYMBOL = "TOKEN";
    uint256 constant SUPPLY = 1000000;

    function run() public {
        vm.startBroadcast();
        deploy();
        vm.stopBroadcast();
    }

    function deploy() public {
        token = new Token(NAME, SYMBOL, SUPPLY);
    }
}
