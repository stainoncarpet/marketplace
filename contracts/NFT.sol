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

    constructor() ERC721("Basic NFT", "BNFT") {}

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter can call this function");
        _;
    }

    function setMinter(address minterAddress) external onlyOwner returns(bool) {
        minter = minterAddress;
        return true;
    }

    function mint(address addr) external returns(bool) {
        _safeMint(addr, _tokenId.current());
        emit Transfer(address(0), addr, _tokenId.current());
         _tokenId.increment();
        return true;
    }

    function destroyContract() external onlyOwner {
        selfdestruct(payable(owner()));
    }
}