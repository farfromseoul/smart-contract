// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TokenSale {
    address public owner;
    IERC20 public token;

    uint256 public pricePerToken = 0.000001 ether;

    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
    }

    function buyToken() external payable {
        require(msg.value > 0, "Send ETH");

        uint256 tokenAmount = msg.value / pricePerToken;
        require(tokenAmount > 0, "Too small ETH");

        token.transfer(msg.sender, tokenAmount * (10 ** 18));
    }

    function withdrawETH() external {
        require(msg.sender == owner, "Only owner");

        uint256 amount = address(this).balance;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

}
