//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
//import "./IAsset.sol";
import "./ShellCore.sol";

interface IWorldMetadata {
    //vchain
    function name() external view returns (string memory);

    function version() external view returns (string memory);

    // account
    function isTrustWorld(uint256 _id) external view returns (bool _isTrustWorld);

    function isTrustContract(address _contract, uint256 _id) external view returns (bool _isTrustContract);

    function isTrust(address _contract, uint256 _id) external view returns (bool _isTrust);

    function getNonce(address _address) external view returns (uint256 _id);

    // asset
    function getAssets() external view returns (address[] memory);

    function isEnabledAsset(address _address) external view returns (bool);

    // safeContract
    function getSafeContracts() external view returns (address[] memory);

    function isSafeContract(address _address) external view returns (bool);

    function checkBWO(address _address) external view returns (bool);
}

interface IWorld is IWorldMetadata {
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
    event RegisterAsset(address indexed asset);
    event EnableAsset(address indexed asset);
    event DisableAsset(address indexed asset);
    event AddSafeContract(address indexed safeContract);
    event RemoveSafeContract(address indexed safeContract);
    event TrustWorld(uint256 indexed accountId, bool isTrustWorld, bool isBWO, address indexed sender, uint256 nonce);
    event TrustContract(
        uint256 indexed accountId,
        address indexed safeContract,
        bool isTrustContract,
        bool isBWO,
        address indexed sender,
        uint256 nonce
    );

    function trustContract(
        uint256 _id,
        address _contract,
        bool _isTrustContract
    ) external;

    function trustContractBWO(
        uint256 _id,
        address _contract,
        bool _isTrustContract,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) external;

    function trustWorld(uint256 _id, bool _isTrustWorld) external;

    function trustWorldBWO(
        uint256 _id,
        bool _isTrustWorld,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) external;
}

interface IWorldCore is IWorldMetadata {
    function trustContract_(
        address _msgSender,
        uint256 _id,
        address _contract,
        bool _isTrustContract
    ) external;

    function trustContractBWO_(
        address _msgSender,
        uint256 _id,
        address _contract,
        bool _isTrustContract,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) external;

    function trustWorld_(
        address _msgSender,
        uint256 _id,
        bool _isTrustWorld
    ) external;

    function trustWorldBWO_(
        address _msgSender,
        uint256 _id,
        bool _isTrustWorld,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) external;
}
