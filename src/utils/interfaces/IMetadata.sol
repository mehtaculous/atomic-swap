// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMetadata {
    function render(
        uint256 _tokenId,
        address _pointer,
        string memory _seed
    ) external view returns (string memory);

    function generateImage(address _pointer, string memory _seed)
        external
        view
        returns (string memory);

    function generateAnimation(address _pointer, string memory _seed)
        external
        view
        returns (string memory);

    function generateAttributes(address _pointer, string memory _seed)
        external
        view
        returns (string memory);

    function getLibrary() external view returns (string memory);

    function getScript(string memory _script, string memory _seed)
        external
        view
        returns (string memory);
}
