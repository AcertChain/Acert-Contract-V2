//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWorld {
    function getOrCreateAccountId(address _address)
        external
        returns (uint256 id);

    function checkSender(uint256 _id, address _address)
        external
        view
        returns (bool);

    function getAddressById(uint256 _id)
        external
        view
        returns (address _address);

    function getAccountIdByAddress(address _address)
        external
        view
        returns (uint256 _id);

    function checkBWO(address _address) external view returns (bool _isBWO);

    function isTrust(address _address, uint256 _id)
        external
        view
        returns (bool _isTrust);

    function isTrustContract(address _address, uint256 _id)
        external
        view
        returns (bool _isTrust);

    function isBWOByAsset(address _address)
        external
        view
        returns (bool _isBWO);

    function isTrustByAsset(address _address, uint256 _id)
        external
        view
        returns (bool _isTrust);

    function isFreeze(uint256 _id) external view returns (bool _isFreeze);

    function getMetaverse() external view returns (address _metaverse);
}
