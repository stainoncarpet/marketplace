//SPDX-License-Identifier: MIT

pragma solidity >=0.8.11 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

// Some basic ERC20
contract MarketToken is ERC20, Ownable {
    // function name() public view returns (string)
    // function symbol() public view returns (string)
    // function decimals() public view returns (uint8)
    // function totalSupply() public view returns (uint256)
    // function balanceOf(address _owner) public view returns (uint256 balance)
    // function transfer(address _to, uint256 _value) public returns (bool success)
    // function transfer(address _to, uint256 _value) public returns (bool success)
    // function transfer(address _to, uint256 _value) public returns (bool success)
    // function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    // event Transfer(address indexed _from, address indexed _to, uint256 _value)
    // event Approval(address indexed _owner, address indexed _spender, uint256 _value)

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