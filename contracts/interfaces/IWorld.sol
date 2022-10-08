//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWorld {
    function isTrustWorld(uint256 _id) external view returns (bool _isTrustWorld);

    function isTrust(address _contract, uint256 _id) external view returns (bool _isTrust);

    function isTrustContract(address _contract, uint256 _id) external view returns (bool _isTrustContract);

    function checkBWOByAsset(address _address) external view returns (bool _isBWO);

    function isTrustByAsset(address _address, uint256 _id) external view returns (bool _isTrust);

    function getMetaverse() external view returns (address _metaverse);
}
