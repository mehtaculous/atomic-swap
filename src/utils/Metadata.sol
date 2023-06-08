// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {FileStore} from "@ethfs/FileStore.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {SSTORE2} from "@sstore2/SSTORE2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Metadata is IMetadata {
    using Strings for uint256;
    FileStore public immutable fileStore;

    constructor(address _fileStore) {
        fileStore = FileStore(_fileStore);
    }

    function render(
        uint256 _tokenId,
        address _pointer,
        string memory _seed
    ) external view returns (string memory) {
        string memory name = string.concat("ERC-721 Token #", _tokenId.toString());
        string memory description = "On-chain metadata";
        string memory image = generateImage(_pointer, _seed);
        string memory animationURL = generateAnimation(_pointer, _seed);
        string memory attributes = generateAttributes(_pointer, _seed);

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        string.concat(
                            '{"name":"',
                            name,
                            '", "description":"',
                            description,
                            '", "image": "',
                            image,
                            '", "animation_url": "',
                            animationURL,
                            '", "attributes": [',
                            attributes,
                            "]}"
                        )
                    )
                )
            );
    }

    function generateImage(address _pointer, string memory _seed)
        public
        view
        returns (string memory encodedString)
    {
        return
            string.concat(
                "data:text/html;base64,",
                Base64.encode(
                    abi.encodePacked(
                        string.concat(
                            "<!DOCTYPE html><html style='height: 100%;'><body style='margin: 0;display: flex;justify-content: center;align-items: center;height: 100%;'>",
                            getLibrary(),
                            getScript(string(SSTORE2.read(_pointer)), _seed),
                            "</body></html>"
                        )
                    )
                )
            );
    }

    function generateAnimation(address _pointer, string memory _seed)
        public
        view
        returns (string memory)
    {
        return
            string.concat(
                "data:text/html;base64,",
                Base64.encode(
                    abi.encodePacked(
                        string.concat(
                            "<!DOCTYPE html><html style='height: 100%;'><body style='margin: 0;display: flex;justify-content: center;align-items: center;height: 100%;'>",
                            getLibrary(),
                            getScript(string(SSTORE2.read(_pointer)), _seed),
                            "</body></html>"
                        )
                    )
                )
            );
    }

    function generateAttributes(address _pointer, string memory _seed)
        public
        view
        returns (string memory encodedString)
    {
        return
            string.concat(
                "data:text/html;base64,",
                Base64.encode(
                    abi.encodePacked(
                        string.concat(
                            "<!DOCTYPE html><html style='height: 100%;'><body style='margin: 0;display: flex;justify-content: center;align-items: center;height: 100%;'>",
                            getLibrary(),
                            getScript(string(SSTORE2.read(_pointer)), _seed),
                            "</body></html>"
                        )
                    )
                )
            );
    }

    function getLibrary() public view returns (string memory) {
        return
            string.concat(
                "<script type='text/javascript+gzip' src='data:text/javascript;base64,",
                fileStore.getFile("p5-v1.5.0.min.js.gz").read(),
                "'></script>",
                "<script src='data:text/javascript;base64,",
                fileStore.getFile("gunzipScripts-0.0.1.js").read(),
                "'></script>"
            );
    }

    function getScript(string memory _script, string memory _seed)
        public
        pure
        returns (string memory)
    {
        return
            string.concat(
                "<script src='data:text/javascript;base64,",
                Base64.encode(abi.encodePacked(string.concat(_seed, _script))),
                "'></script>"
            );
    }
}
