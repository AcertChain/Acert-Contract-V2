//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./IAsset.sol";

interface IWorld {
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
    event RegisterAsset(address indexed asset, IAsset.ProtocolEnum protocol);
    event DisableAsset(address indexed asset);
    event AddSafeContract(address indexed safeContract, string name);
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

    //metaverse
    function name() external view returns (string memory);

    function version() external view returns (string memory);

    // account
    function trustContract(uint256 _id, address _address, bool _isTrustContract) external;
    
    function trustContractBWO(uint256 _id, address _address, bool _isTrustContract, address sender, uint256 deadline, bytes memory signature) external;
    
    function trustWorld(uint256 _id, bool _isTrustWorld) external;

    function trustWorld(uint256 _id, bool _isTrustWorld, address sender, uint256 deadline, bytes memory signature) external;
    
    function isTrustWorld(uint256 _id) external view returns (bool _isTrustWorld);

    function isTrustContract(address _contract, uint256 _id) external view returns (bool _isTrustContract);

    function isTrust(address _contract, uint256 _id) external view returns (bool _isTrust);

    // asset
    function getAssets() external view returns (address[] memory);

    // safeContract
    function getSafeContracts() external view returns (address[] memory);

    function checkBWO(address _address) external view returns (bool);

    function checkAsset(address _address) external view returns (bool);

}
