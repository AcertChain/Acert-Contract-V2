//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMetaverse {
    function accountIsExist(uint256 _id) external view returns (bool _isExist);

    function isFreeze(uint256 _id) external view returns (bool _isFreeze);

    function getOrCreateAccountId(address _address) external returns (uint256 id);

    function getAccountIdByAddress(address _address) external view returns (uint256 _id);

    function getAddressByAccountId(uint256 _id) external view returns (address _address);

    function checkSender(uint256 _id, address _address) external view ;
}
