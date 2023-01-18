//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Mineable is Ownable {
    event UpdateMiner(address indexed _miner, bool _vaild);

    mapping(address => bool) public miners;

    modifier onlyMiner() {
        require(miners[msg.sender], "Mineable: caller is not the miner");
        _;
    }

    function updateMiner(address _miner, bool _vaild) public onlyOwner {
        miners[_miner] = _vaild;
        emit UpdateMiner(_miner, _vaild);
    }
}
