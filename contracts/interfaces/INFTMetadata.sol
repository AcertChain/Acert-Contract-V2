//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface INFTMetadata {

    event SetString(
        address indexed assetContract,
        uint256 indexed tokenId,
        string key,
        string value
    );

    event SetUint256(
        address indexed assetContract,
        uint256 indexed tokenId,
        string key,
        uint256 value
    );    

    function setString(uint256 tokenId, string memory key, string memory value) external returns (bool);
    function getStringKeys(uint256 tokenId) external returns (string[] memory);
    function getString(uint256 tokenId, string memory key) external returns (string memory);
    
    function setUint256(uint256 tokenId, string memory key, uint256 value) external returns (bool);
    function getUint256Keys(uint256 tokenId) external returns (string[] memory);
    function getUint256(uint256 tokenId, string memory key) external returns (uint256);
}
