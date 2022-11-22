//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
//import "./IAsset.sol";
import "./ShellCore.sol";

interface IWorldMetadata {
    //metaverse
    function name() external view returns (string memory);

    function version() external view returns (string memory);

    // account
    function isTrustWorld(uint256 _id) external view returns (bool _isTrustWorld);

    function isTrustContract(address _contract, uint256 _id) external view returns (bool _isTrustContract);

    function isTrust(address _contract, uint256 _id) external view returns (bool _isTrust);

    // asset
    function getAssets() external view returns (address[] memory);

    function isEnabledAsset(address _address) external view returns (bool);

    // safeContract
    function getSafeContracts() external view returns (address[] memory);

    function isSafeContract(address _address) external view returns (bool);

    function checkBWO(address _address) external view returns (bool);

}

interface IWorld is IWorldMetadata {
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
        bytes memory signature
    ) external;
    
    function trustWorld(uint256 _id, bool _isTrustWorld) external;

    function trustWorldBWO(
        uint256 _id, bool _isTrustWorld,
        address sender,
        uint256 deadline,
        bytes memory signature
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
        bytes memory signature
    ) external;
    
    function trustWorld_(address _msgSender, uint256 _id, bool _isTrustWorld) external;

    function trustWorldBWO_(
        address _msgSender,
        uint256 _id,
        bool _isTrustWorld,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external;
    
}

contract WorldShell is ShellContract {
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
    event RegisterAsset(address indexed asset);
    event EnableAsset(address indexed asset);
    event DisableAsset(address indexed asset);
    event AddSafeContract(address indexed safeContract);
    event RemoveSafeContract(address indexed safeContract);
    event TrustWorld(
        uint256 indexed accountId,
        bool isTrustWorld,
        bool isBWO,
        address indexed sender,
        uint256 nonce
    );
    event TrustContract(
        uint256 indexed accountId,
        address indexed safeContract,
        bool isTrustContract,
        bool isBWO,
        address indexed sender,
        uint256 nonce
    );
    
    //IWorldShell
    function emitAddOperator(address operator_) public onlyCore {
        emit AddOperator(operator_);
    }
    function emitRemoveOperator(address operator_) public onlyCore {
        emit AddOperator(operator_);
    }
    function emitRegisterAsset(address _asset) public onlyCore {
        emit RegisterAsset(_asset);
    }
    function emitEnableAsset(address _asset) public onlyCore {
        emit EnableAsset(_asset);
    }
    function emitDisableAsset(address _asset) public onlyCore {
        emit DisableAsset(_asset);
    }
    function emitAddSafeContract(address _contract) public onlyCore {
        emit AddSafeContract(_contract);
    }
    function emitRemoveSafeContract(address _contract) public onlyCore {
        emit RemoveSafeContract(_contract);
    }
    function emitTrustWorld(
        uint256 _accountId,
        bool _isTrustWorld,
        bool isBWO,
        address sender,
        uint256 nonce
    ) public onlyCore {
        emit TrustWorld(_accountId, _isTrustWorld, isBWO, sender, nonce);
    }
    function emitTrustContract(
        uint256 _accountId,
        address _safeContract,
        bool _isTrustContract,
        bool isBWO,
        address sender,
        uint256 nonce
    ) public onlyCore {
        emit TrustContract(_accountId, _safeContract,_isTrustContract, isBWO, sender, nonce);
    }

}
