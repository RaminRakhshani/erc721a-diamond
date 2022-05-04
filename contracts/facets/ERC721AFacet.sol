// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage, TokenOwnership} from "../libraries/LibAppStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../ERC721A.sol";
// import "erc721a/contracts/ERC721A.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ERC721AFacet is ERC721A {
    AppStorage internal s;

    using Strings for uint256;

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= s.maxMintAmountPerTx, "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= s.maxSupply, "Max supply exceeded!");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= s.cost * _mintAmount, "Insufficient funds!");
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(s.whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!s.whitelistClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, s.merkleRoot, leaf), "Invalid proof!");

        s.whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(!s.paused, "The contract is paused!");

        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId < s.currentIndex) {
            TokenOwnership memory ownership = s.ownerships[currentTokenId];

            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    latestOwnerAddress = ownership.addr;
                }

                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;

                    ownedTokenIndex++;
                }
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (s.revealed == false) {
            return s.hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), s.uriSuffix)) : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        s.revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        s.cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        s.maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        s.hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        s.uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        s.uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        s.paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        s.merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        s.whitelistMintEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        // This will pay HashLips Lab Team 5% of the initial sale.
        // By leaving the following lines as they are you will contribute to the
        // development of tools like this and many others.
        // =============================================================================
        (bool hs, ) = payable(0x146FB9c3b2C13BA88c6945A759EbFa95127486F4).call{value: (address(this).balance * 5) / 100}("");
        require(hs);
        // =============================================================================

        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return s.uriPrefix;
    }

    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }
}
