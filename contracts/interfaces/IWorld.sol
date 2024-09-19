//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
//import "./IAsset.sol";
import "./ShellCore.sol";

interface IWorldCore {
    //vchain
    function name() external view returns (string memory);

    function version() external view returns (string memory);

    // account
    function getNonce(address _address) external view returns (uint256 _id);

    // asset
    function getAssets() external view returns (address[] memory);

    function isEnabledAsset(address _address) external view returns (bool);

    // safeContract
    function getSafeContracts() external view returns (address[] memory);

    function isSafeContract(address _address) external view returns (bool);

    function checkBWO(address _address) external view returns (bool);
}

interface IWorld is IWorldCore {
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
    event RegisterAsset(address indexed asset);
    event EnableAsset(address indexed asset);
    event DisableAsset(address indexed asset);
    event AddSafeContract(address indexed safeContract);
    event RemoveSafeContract(address indexed safeContract);
}
