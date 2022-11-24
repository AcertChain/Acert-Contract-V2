//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Mineable is Ownable {
    event UpdateMiner(address indexed _miner);

    address public miner;

    modifier onlyMiner() {
        require(miner == _msgSender(), "Mineable: caller is not the miner");
        _;
    }

    function updateMiner(address _miner) public onlyOwner {
        miner = _miner;
        emit UpdateMiner(_miner);
    }
}
