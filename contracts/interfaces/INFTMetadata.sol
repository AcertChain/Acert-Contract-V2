//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface INFTMetadata {
    enum ValueType {
        STRING,
        UINT256
    }

    event SetMetadata(
        address indexed assetContract,
        uint256 indexed tokenId,
        string key,
        string value,
        ValueType valueType
    );

    event RemoveMetadata(address indexed assetContract, uint256 indexed tokenId, string key);

    event ClearMetadata(address indexed assetContract, uint256 indexed tokenId);

    function setMetadata(
        uint256 tokenId,
        string memory key,
        string memory value,
        INFTMetadata.ValueType valueType
    ) external returns (bool);

    function batchSetMetadata(
        uint256[] memory tokenIds,
        string[][] memory keys,
        string[][] memory values,
        INFTMetadata.ValueType[][] memory valueTypes
    ) external returns (bool);

    function getKeys(uint256 tokenId) external returns (string[] memory);

    function getValue(uint256 tokenId, string memory key) external returns (string memory, INFTMetadata.ValueType);

    function removeMetadata(uint256 tokenId, string memory key) external returns (bool);

    function clearMetadata(uint256 tokenId) external returns (bool);
}
