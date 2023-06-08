// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct RoyaltyInfo {
    uint96 percent;
    address receiver;
}

struct SaleInfo {
    uint32 currentId;
    uint32 maxSupply;
    uint64 startTime;
    uint128 price;
}

interface INFT721 {
    error InvalidPayment();
    error SaleInactive();
    error TransferFailed();

    function baseURI() external view returns (string memory);

    function batchBurn(uint256[] calldata _tokenIds) external payable;

    function batchMint(uint256 _amount) external payable;

    function burned() external view returns (uint96);

    function metadata() external view returns (address);

    function mint(uint256 _amount) external payable;

    function royalty() external view returns (uint96, address);

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256);

    function sale()
        external
        view
        returns (
            uint32,
            uint32,
            uint64,
            uint128
        );

    function setBaseURI(string memory _uri) external payable;

    function setMaxSupply(uint32 _supply) external payable;

    function setMetadata(address _metadata) external payable;

    function setStartTime(uint64 _timestamp) external payable;

    function setMintPrice(uint128 _price) external payable;

    function setRoyaltyInfo(uint96 _percent, address _receiver) external payable;

    function setTokenURIs(uint256[] calldata _tokenIds, string[] calldata _tokenURIs)
        external
        payable;

    function totalSupply() external view returns (uint256);

    function withdraw() external payable;
}
