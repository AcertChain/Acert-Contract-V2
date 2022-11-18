//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMetaverse {
    enum OperationEnum {
        REMOVE,
        ADD
    }
    event SetAdmin(address indexed admin);
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
    event RegisterWorld(address indexed world, string name);
    event DisableWorld(address indexed world);
    event CreateAccount(uint256 indexed accountId, address indexed authAddress, bool isTrustAdmin);
    event TrustAdmin(uint256 indexed accountId, bool isTrustAdmin, bool isBWO, address indexed sender, uint256 nonce);
    event FreezeAccount(uint256 indexed accountId, bool isBWO, address indexed sender, uint256 nonce);
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

    function coreVersion() external view returns (string memory);

    function coreContract() external view returns (address);

    // account
    function createAccount(address _address, bool _isTrustAdmin) external returns (uint256 id);

    function getOrCreateAccountId(address _address) external returns (uint256 id);
    
    function addAuthAddress(uint256 _id, address _address, uint256 deadline, bytes memory signature) external;

    function addAuthAddressBWO(uint256 _id, address _address, address sender, uint256 deadline, bytes memory signature, bytes memory authSignature) external;
    
    function removeAuthAddress(uint256 _id, address _address) external;
    
    function removeAuthAddressBWO( uint256 _id, address _address, address sender, uint256 deadline, bytes memory signature) external;

    function trustAdmin(uint256 _id, bool _isTrustAdmin) external;

    function trustAdminBWO(uint256 _id, bool _isTrustAdmin, address sender, uint256 deadline, bytes memory signature) external;

    function freezeAccount(uint256 _id) external;

    function freezeAccountBWO(uint256 _id, address sender, uint256 deadline, bytes memory signature) external;

    function getAccountIdByAddress(address _address) external view returns (uint256 _id);

    function getAddressByAccountId(uint256 _id) external view returns (address _address);

    function getAccountAuthAddress(uint256 _id) external view returns (address[] memory);

    function accountIsExist(uint256 _id) external view returns (bool _isExist);

    function accountIsTrustAdmin(uint256 _id) external view returns (bool _isFreeze);

    function accountIsFreeze(uint256 _id) external view returns (bool _isFreeze);

    function checkSender(uint256 _id, address _address) external view returns (bool);

    // world
    function getWorlds() external view returns (address[] memory);

    function getWorldInfo(address _world) external view returns (string memory _name, bool _isEnable);
}
