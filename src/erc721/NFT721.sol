// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC721, ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {INFT721, RoyaltyInfo, SaleInfo} from "./interfaces/INFT721.sol";
import {IMetadata} from "../utils/interfaces/IMetadata.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NFT721 is INFT721, ERC721URIStorage, Ownable {
    string public baseURI;
    uint96 public burned;
    address public metadata;
    SaleInfo public sale;
    RoyaltyInfo public royalty;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    /// ============================
    /// ========== PUBLIC ==========
    /// ============================

    function mint(uint256 _amount) external payable {
        if (block.timestamp < sale.startTime || sale.currentId == sale.maxSupply)
            revert SaleInactive();
        if (msg.value != _amount * sale.price) revert InvalidPayment();
        unchecked {
            for (uint256 i; i < _amount; ++i) {
                _safeMint(msg.sender, ++sale.currentId);
            }
        }
    }

    /// ===========================
    /// ========== ADMIN ==========
    /// ===========================

    function setBaseURI(string memory _uri) external payable onlyOwner {
        baseURI = _uri;
    }

    function setMetadata(address _metadata) external payable onlyOwner {
        metadata = _metadata;
    }

    function setMaxSupply(uint32 _supply) external payable onlyOwner {
        sale.maxSupply = _supply;
    }

    function setStartTime(uint64 _timestamp) external payable onlyOwner {
        sale.startTime = _timestamp;
    }

    function setMintPrice(uint128 _price) external payable onlyOwner {
        sale.price = _price;
    }

    function setRoyaltyInfo(uint96 _percent, address _receiver) external payable onlyOwner {
        royalty.percent = _percent;
        royalty.receiver = _receiver;
    }

    function setTokenURIs(uint256[] calldata _tokenIds, string[] calldata _tokenURIs)
        external
        payable
        onlyOwner
    {
        uint256 length = _tokenIds.length;
        for (uint256 i; i < length; ) {
            _setTokenURI(_tokenIds[i], _tokenURIs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function batchMint(uint256 _amount) external payable onlyOwner {
        unchecked {
            for (uint256 i; i < _amount; ++i) {
                _mint(msg.sender, ++sale.currentId);
            }
        }
    }

    function batchBurn(uint256[] calldata _tokenIds) external payable onlyOwner {
        uint256 length = _tokenIds.length;
        unchecked {
            for (uint256 i; i < length; ++i) {
                burned++;
                _burn(_tokenIds[i]);
            }
        }
    }

    function withdraw() external payable onlyOwner {
        (bool successful, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!successful) revert TransferFailed();
    }

    /// ==========================
    /// ========== VIEW ==========
    /// ==========================

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (metadata != address(0)) {
            return IMetadata(metadata).render(_tokenId, address(0), "");
        } else {
            return super.tokenURI(_tokenId);
        }
    }

    function totalSupply() public view returns (uint256) {
        return sale.currentId - burned;
    }

    function royaltyInfo(
        uint256, /* _tokenId */
        uint256 _salePrice
    ) external view returns (address, uint256 amount) {
        amount = (_salePrice * royalty.percent) / 10000;
        return (royalty.receiver, amount);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == 0x2a55205a || super.supportsInterface(_interfaceId);
    }

    /// ==============================
    /// ========== INTERNAL ==========
    /// ==============================

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
