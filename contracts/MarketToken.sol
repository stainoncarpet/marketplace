//SPDX-License-Identifier: MIT

pragma solidity >=0.8.11 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

// Some basic ERC20
contract MarketToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("MarketToken", "MTN") {
        _mint(msg.sender, initialSupply);
    }

    // mints 1 token when called, no questions asked
    function mint() external {
        _mint(msg.sender, 1 * 10**decimals());
        emit Transfer(address(0), msg.sender, 1 * 10**decimals());
    }

    function destroyContract() external onlyOwner {
        selfdestruct(payable(owner()));
    }
}