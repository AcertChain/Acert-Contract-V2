//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMetaverseBase {
    //metaverse
    function name() external view returns (string memory);

    function version() external view returns (string memory);

    // account
    function getAccountIdByAddress(address _address) external view returns (uint256 _id);

    function getAddressByAccountId(uint256 _id) external view returns (address _address);

    function getAccountAuthAddress(uint256 _id) external view returns (address[] memory);

    function accountIsExist(uint256 _id) external view returns (bool _isExist);

    function accountIsTrustAdmin(uint256 _id) external view returns (bool _isFreeze);

    function accountIsFreeze(uint256 _id) external view returns (bool _isFreeze);

    function checkSender(uint256 _id, address _sender) external view returns (bool);

    function getTotalAccount() external view returns (uint256);

    // world
    function getWorlds() external view returns (address[] memory);
}

interface IMetaverse is IMetaverseBase {
    function createAccount(address _address, bool _isTrustAdmin) external returns (uint256 id);

    function createAccountBWO(
        address _address,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external returns (uint256 id);

    function addAuthAddress(
        uint256 _id,
        address _address,
        uint256 deadline,
        bytes memory signature
    ) external;

    function addAuthAddressBWO(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes memory signature,
        bytes memory authSignature
    ) external;

    function removeAuthAddress(uint256 _id, address _address) external;

    function removeAuthAddressBWO(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external;

    function trustAdmin(uint256 _id, bool _isTrustAdmin) external;

    function trustAdminBWO(
        uint256 _id,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external;

    function freezeAccount(uint256 _id) external;

    function freezeAccountBWO(
        uint256 _id,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external;
}

interface IMetaverseCore is IMetaverseBase {
    function createAccount_(
        address _msgSender,
        address _address,
        bool _isTrustAdmin
    ) external returns (uint256 id);

    function createAccountBWO_(
        address _msgSender,
        address _address,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external returns (uint256 id);

    function addAuthAddress_(
        address _msgSender,
        uint256 _id,
        address _address,
        uint256 deadline,
        bytes memory signature
    ) external;

    function addAuthAddressBWO_(
        address _msgSender,
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes memory signature,
        bytes memory authSignature
    ) external;

    function removeAuthAddress_(
        address _msgSender,
        uint256 _id,
        address _address
    ) external;

    function removeAuthAddressBWO_(
        address _msgSender,
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external;

    function trustAdmin_(
        address _msgSender,
        uint256 _id,
        bool _isTrustAdmin
    ) external;

    function trustAdminBWO_(
        address _msgSender,
        uint256 _id,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external;

    function freezeAccount_(address _msgSender, uint256 _id) external;

    function freezeAccountBWO_(
        address _msgSender,
        uint256 _id,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external;
}

interface IMetaverseShell {
    event SetAdmin(address indexed admin);
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
    event RegisterWorld(address indexed world);
    event EnableWorld(address indexed world);
    event DisableWorld(address indexed world);
    event CreateAccount(
        uint256 indexed accountId,
        address indexed authAddress,
        bool isTrustAdmin,
        bool isBWO_,
        address indexed sender_,
        uint256 nonce_
    );
    event TrustAdmin(uint256 indexed accountId, bool isTrustAdmin, bool isBWO, address indexed sender, uint256 nonce);
    event FreezeAccount(uint256 indexed accountId, bool isBWO, address indexed sender, uint256 nonce);
    event UnFreezeAccount(uint256 indexed accountId, address indexed newAuthAddress);
    event AddAuthAddress(
        uint256 indexed accountId,
        address indexed authAddress,
        bool isBWO,
        address indexed sender,
        uint256 nonce
    );
    event RemoveAuthAddress(
        uint256 indexed accountId,
        address indexed authAddress,
        bool isBWO,
        address indexed sender,
        uint256 nonce
    );

    function emitSetAdmin(address admin) external;

    function emitAddOperator(address operator_) external;

    function emitRemoveOperator(address operator_) external;

    function emitRegisterWorld(address world_) external;

    function emitEnableWorld(address world_) external;

    function emitDisableWorld(address world_) external;

    function emitCreateAccount(
        uint256 accountId_,
        address authAddress_,
        bool isTrustAdmin_,
        bool isBWO_,
        address sender_,
        uint256 nonce_
    ) external;

    function emitTrustAdmin(
        uint256 accountId_,
        bool isTrustAdmin_,
        bool isBWO,
        address sender_,
        uint256 nonce_
    ) external;

    function emitFreezeAccount(
        uint256 accountId_,
        bool isBWO_,
        address sender_,
        uint256 nonce_
    ) external;

    function emitUnFreezeAccount(uint256 accountId_, address newAuthAddress_) external;

    function emitAddAuthAddress(
        uint256 accountId_,
        address authAddress_,
        bool isBWO_,
        address sender_,
        uint256 nonce_
    ) external;

    function emitRemoveAuthAddress(
        uint256 accountId_,
        address authAddress_,
        bool isBWO_,
        address sender_,
        uint256 nonce_
    ) external;
}
