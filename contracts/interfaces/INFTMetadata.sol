//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface INFTMetadata {
    event SetString(address indexed assetContract, uint256 indexed tokenId, string key, string value);

    event SetMetadata(address indexed assetContract, uint256 indexed tokenId, string key, uint256 value, string valueType);

    event RemoveMetadata(address indexed assetContract, uint256 indexed tokenId, string key);

    event ClearMetadata(address indexed assetContract, uint256 indexed tokenId);

    function setMetadata(
        uint256 tokenId,
        string memory key,
        string memory value,
        string memory valueType
    ) external returns (bool);

    function batchSetMetadata(
        uint256[] memory tokenId,
        string[][] memory keys,
        string[][] memory values,
        string[][] memory valueTypes
    ) external returns (bool);

    function getKeys(uint256 tokenId) external returns (string[] memory);

    function getValue(uint256 tokenId, string memory key) external returns (string memory);

    function removeMetadata(uint256 tokenId, string memory key) external returns (bool);

    function clearMetadata(uint256 tokenId) external returns (bool);

}
