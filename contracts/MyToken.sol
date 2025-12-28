// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyToken {
    string public name = "Giwa Test Token";
    string public symbol = "GTG";
    uint8 public decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    address public owner;

    constructor(uint256 _initialSupply) {
        owner = msg.sender;

        totalSupply = _initialSupply * (10 ** decimals);
        balanceOf[owner] = totalSupply;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Not enough token");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        return true;
    }
}
