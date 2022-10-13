//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMetaverse {
    enum OperationEnum {
        ADD,
        REMOVE
    }
    event SetName(string name);
    event SetAdmin(address indexed admin);
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
    event RegisterWorld(address indexed world, string name);
    event DisableWorld(address indexed world);
    event CreateAccount(uint256 indexed accountId, address indexed authAddress, bool isTrustAdmin);
    event TrustAdmin(uint256 indexed accountId, bool isTrustAdmin, bool isBWO, address indexed Sender, uint256 nonce);
    event FreezeAccount(uint256 indexed accountId, bool isBWO, address indexed Sender, uint256 nonce);
    event UnFreezeAccount(uint256 indexed accountId, address indexed newAuthAddress);
    event AuthAddressChanged(
        uint256 indexed accountId,
        address indexed authAddress,
        OperationEnum operation,
        bool isBWO,
        address indexed sender,
        uint256 nonce
    );

    function name() external view returns (string memory);

    function accountIsExist(uint256 _id) external view returns (bool _isExist);

    function isFreeze(uint256 _id) external view returns (bool _isFreeze);

    function getOrCreateAccountId(address _address) external returns (uint256 id);

    function getAccountIdByAddress(address _address) external view returns (uint256 _id);

    function getAddressByAccountId(uint256 _id) external view returns (address _address);

    function checkSender(uint256 _id, address _address) external view;
}
