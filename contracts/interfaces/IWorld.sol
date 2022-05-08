//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWorld  {

    function getOrCreateAccountId(address _address)
        external
        returns (uint256 id);

    function getAddressById(uint256 _id)
        external
        view
        returns (address _address);

    function isBWO(address _contract) external view returns (bool _isBWO);

    function isTrust(address _contract, uint256 _id)
        external
        view
        returns (bool _isTrust);
}
