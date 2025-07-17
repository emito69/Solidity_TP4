// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Token1
 * @notice An ERC20 implementation with minting capability and initial token distribution
 * @dev Extends OpenZeppelin's ERC20 and Ownable contracts
 * @dev Includes pre-approvals for specific addresses and initial token transfers
 */
contract Token1 is ERC20, Ownable {
    /**
     * @notice Initializes the Token1 contract
     * @dev Mints initial supply, approves specific addresses, and transfers initial amounts
     * Sets the token name to "Token1" and symbol to "TK1"
     * The contract deployer is set as the initial owner
     */
    constructor() ERC20("Token1", "TK1") Ownable(msg.sender) {
        _mint(msg.sender, 999*(10**18));
        approve(address(msg.sender), 999*(10**18)); // approve owner
        approve(address(0x9f8F02DAB384DDdf1591C3366069Da3Fb0018220), 999*(10**18)); // approve to verify-contract
        approve(address(0x9041C3444Da876C4Ca43F3B3Cc3c68a5df67E85C), 999*(10**18)); // approve SWAP-contract

        transferFrom(msg.sender, address(0x9f8F02DAB384DDdf1591C3366069Da3Fb0018220), 100*(10**18)); // send tokens to verify-contract
    }

    /**
     * @notice Mints new tokens to a specified address
     * @dev Only callable by the contract owner
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
}