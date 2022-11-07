// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Miner is Ownable{
    using Address for address;

    mapping (address => bool) public miners;

    event MinerAdded(address indexed account);
    event MinerRemoved(address indexed account);

    constructor() {}

    modifier onlyMiner() {
        require(miners[msg.sender], "Minter: caller is not the minter");
        _;
    }

    function addMiner(address account) public onlyOwner {
        require(account != address(0), "Minter: add the zero address");
        miners[account] = true;
        emit MinerAdded(account);
    }

    function removeMiner(address account) public onlyOwner {
        require(account != address(0), "Minter: remove the zero address");
        miners[account] = false;
        emit MinerRemoved(account);
    }

    function isMiner(address account) public view returns (bool) {
        return miners[account];
    }

    function call(address to, bytes memory data) public onlyMiner returns (bytes memory) {
        return to.functionCall(data);
    }

}