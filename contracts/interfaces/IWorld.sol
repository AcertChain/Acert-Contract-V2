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

    function name() external view returns (string memory);

    function isTrustWorld(uint256 _id) external view returns (bool _isTrustWorld);

    function isTrust(address _contract, uint256 _id) external view returns (bool _isTrust);

    function isTrustContract(address _contract, uint256 _id) external view returns (bool _isTrustContract);

    function checkBWOByAsset(address _address) external view returns (bool _isBWO);

    function isTrustByAsset(address _address, uint256 _id) external view returns (bool _isTrust);
}
