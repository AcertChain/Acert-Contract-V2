//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWorld {
    function getOrCreateAccountId(address _address) external returns (uint256 id);
    
    function getAddressById(uint256 _id) external view returns (address _address);
}
