//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./ShellCore.sol";

interface IVChainMetadata {
    //vchain
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

    function getNonce(address _address) external view returns (uint256 _id);

    // world
    function getWorlds() external view returns (address[] memory);
}

interface IVChain is IVChainMetadata {
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
        bool isBWO,
        address indexed sender,
        uint256 nonce
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

    function createAccount(address _address, bool _isTrustAdmin) external returns (uint256 id);

    function createAccountBWO(
        address _address,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) external returns (uint256 id);

    function addAuthAddress(
        uint256 _id,
        address _address,
        uint256 deadline,
        bytes calldata signature
    ) external;

    function addAuthAddressBWO(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes calldata signature,
        bytes memory authSignature
    ) external;

    function removeAuthAddress(uint256 _id, address _address) external;

    function removeAuthAddressBWO(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) external;

    function trustAdmin(uint256 _id, bool _isTrustAdmin) external;

    function trustAdminBWO(
        uint256 _id,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) external;

    function freezeAccount(uint256 _id) external;

    function freezeAccountBWO(
        uint256 _id,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) external;
}

interface IVChainCore is IVChainMetadata {
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
        bytes calldata signature
    ) external returns (uint256 id);

    function addAuthAddress_(
        address _msgSender,
        uint256 _id,
        address _address,
        uint256 deadline,
        bytes calldata signature
    ) external;

    function addAuthAddressBWO_(
        address _msgSender,
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes calldata signature,
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
        bytes calldata signature
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
        bytes calldata signature
    ) external;

    function freezeAccount_(address _msgSender, uint256 _id) external;

    function freezeAccountBWO_(
        address _msgSender,
        uint256 _id,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) external;
}
