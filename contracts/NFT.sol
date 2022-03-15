//SPDX-License-Identifier: MIT

pragma solidity >=0.8.11 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

// Some basic ERC721
contract NFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter _tokenId;
    address public minter;
    mapping(uint256 => string) tokenUriById;

    constructor() ERC721("Basic NFT", "BNFT") {}

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter can mint tokens");
        _;
    }

    function setMinter(address minterAddress) external onlyOwner returns(bool) {
        minter = minterAddress;
        return true;
    }

    function mint(string memory tokenURI, address addr) external onlyMinter returns(bool) {
        _safeMint(addr, _tokenId.current());
        tokenUriById[_tokenId.current()] = tokenURI;
        emit Transfer(address(0), addr, _tokenId.current());
         _tokenId.increment();
        return true;
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        string memory tokenUri = string(abi.encodePacked(tokenUriById[_tokenId.current()], Strings.toString(tokenId), ".json"));
        return tokenUri;
    }

    function destroyContract() external onlyOwner {
        selfdestruct(payable(owner()));
    }
}