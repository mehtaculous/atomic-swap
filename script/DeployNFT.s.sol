// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "src/erc721/NFT721.sol";
import "src/erc1155/NFT1155.sol";

contract DeployNFT is Script {
    NFT721 nft721;
    NFT1155 nft1155;
    string constant NAME = "Non-Fungible Token";
    string constant SYMBOL = "NFT";

    function run() public {
        vm.startBroadcast();
        deploy();
        vm.stopBroadcast();
    }

    function deploy() public {
        nft721 = new NFT721(NAME, SYMBOL);
        nft1155 = new NFT1155(NAME, SYMBOL, "");
    }
}
