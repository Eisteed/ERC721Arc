// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./contracts/ERC721A.sol";
import "./opensea-filters/DefaultOperatorFilterer.sol";
import "./openzeppelin/contracts/token/common/ERC2981.sol";
import "./openzeppelin/contracts/access/Ownable.sol";

contract MyNFTs is ERC721A, ERC2981, DefaultOperatorFilterer, Ownable {

    RoyaltyInfo private _defaultRoyaltyInfo;

    // Set maximum amount of NFTs
    uint16 public constant maxSupply = 1000;

    // Set toyalty in percentage of the sale (Globally)
    uint8 royaltyPercent = 3;

    // Set where to send the royalties
    address royaltyAddress = 0x0000000000000000000000000000000000000000;

    // Signals collection metadata for OpenSea (description, image, link).
    string  _contractURI = "https://example.com/metadata";

    // BaseURI for tokens metadata
    string  _baseTokenURI = "";

    // First NFT number (default= 0)
    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    constructor() ERC721A("MyNFTs Collection", "MyNFTs") {
        royaltyAddress = owner();
    }
    
    function mint(uint256 quantity) external payable {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
       require (totalSupply() < maxSupply, "Maximum supply of NFTs reached");
        _mint(msg.sender, quantity);

    }

    // Batch mint in lot of 10, quantity must be divisble by 10.
    function batchMint10(uint256 quantity) external payable {
        require (quantity>=10, "Quantity must be 10 or more.");
        require (quantity%10==0, "Quantity must be divisible by 10.");
        require ((totalSupply() + quantity) <= maxSupply, "Batch minting would produce more NFTs than maximum supply.");
            for(uint256 i = 0; i < quantity / 10; i++) {
                _mint(msg.sender, 10);
            }
    }

    // Base URI where metadata are hosted
    function _baseURI() override internal view virtual returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setContractURI(string calldata contractURI) external onlyOwner {
        _contractURI = contractURI;
    }

    // WIP freeze all metadata when ready, not showing up on opensea frontend and cost a tremendous amount of gas..
    // Kind of useless atm, I hope this can be applied to baseURI 1 time in the future.
    // function FreezeAllMetadata() external
    // {
    //    for(uint256 tokenId = _startTokenId(); tokenId <= totalSupply(); tokenId++) {
    //        emit PermanentURI(tokenURI(tokenId),tokenId);
    //    }
    // }

    // ####################################
    // ROYALTIES (Set globally to save gas)
    // ####################################


    function setRoyalty(uint8 _royaltyPercent, address _royaltyAddress) external onlyOwner
    {
        royaltyAddress = _royaltyAddress;
        royaltyPercent = _royaltyPercent;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) override view public returns (address receiver, uint256 royaltyAmount)   {
        // Just to avoid some warning, this does nothing
        _tokenId = 0;
        
        // Assign what has been defined earlier
        receiver = royaltyAddress;
        royaltyAmount = (royaltyPercent * _salePrice) / 100;
    }

    // #######################
    // OpenSea Filter Operator
    // #######################

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // #######################
    // 2981 Royalties Standard Support
    // #######################

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

}