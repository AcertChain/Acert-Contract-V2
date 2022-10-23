// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/INFTMetadata.sol";
import "../interfaces/IAcertContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

library Utils {
    function remove(string[] storage arr, uint256 _index) public {
        require(_index < arr.length, "index out of bound");

        for (uint256 i = _index; i < arr.length - 1; i++) {
            arr[i] = arr[i + 1];
        }
        arr.pop();
    }

    function search(string[] storage array, string memory key) public view returns (bool, uint256) {
        if (array.length == 0) {
            return (false, 0);
        }

        for (uint256 i = 0; i < array.length; i++) {
            if (keccak256(abi.encodePacked(array[i])) == keccak256(abi.encodePacked(key))) {
                return (true, i);
            }
        }
        return (false, 0);
    }
}

contract NFTMetadata is INFTMetadata, IAcertContract, Ownable {
    mapping(uint256 => mapping(string => string)) public stringMetadata;
    mapping(uint256 => string[]) public stringMetadataKeys;
    mapping(uint256 => mapping(string => uint256)) public uint256Metadata;
    mapping(uint256 => string[]) public uint256MetadataKeys;

    address public assetStorageContract;

    constructor(address _assetStorageContract, address _owner) {
        assetStorageContract = _assetStorageContract;
        _transferOwnership(_owner);
    }

    /**
     * @dev See {IAcertContract-metaverseAddress}.
     */
    function metaverseAddress() public view override returns (address) {
        return address(IAcertContract(assetStorageContract).metaverseAddress());
    }

    function setString(
        uint256 tokenId,
        string memory key,
        string memory value
    ) public override onlyOwner returns (bool) {
        stringMetadata[tokenId][key] = value;
        stringMetadataKeys[tokenId].push(key);
        emit SetString(assetStorageContract, tokenId, key, value);
        return true;
    }

    function setStringBatch(
        uint256[] memory tokenIds,
        string[][] memory keys,
        string[][] memory values
    ) public override onlyOwner returns (bool) {
        require(tokenIds.length == keys.length, "tokenIds and keys length mismatch");
        require(tokenIds.length == values.length, "tokenIds and values length mismatch");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            for (uint256 j = 0; j < keys[i].length; j++) {
                setString(tokenIds[i], keys[i][j], values[i][j]);
            }
        }

        return true;
    }

    function deleteString(uint256 tokenId, string memory key) public override onlyOwner returns (bool) {
        delete stringMetadata[tokenId][key];

        (bool found, uint256 index) = Utils.search(stringMetadataKeys[tokenId], key);
        if (found) {
            Utils.remove(stringMetadataKeys[tokenId], index);
        }

        emit DeleteStringByKey(assetStorageContract, tokenId, key);
        return true;
    }

    function deleteString(uint256 tokenId) public override onlyOwner returns (bool) {
        for (uint256 i = 0; i < stringMetadataKeys[tokenId].length; i++) {
            delete stringMetadata[tokenId][stringMetadataKeys[tokenId][i]];
        }
        delete stringMetadataKeys[tokenId];
        return true;
    }

    function getStringKeys(uint256 tokenId) public view override returns (string[] memory) {
        return stringMetadataKeys[tokenId];
    }

    function getString(uint256 tokenId, string memory key) public view override returns (string memory) {
        return stringMetadata[tokenId][key];
    }

    function setUint256(
        uint256 tokenId,
        string memory key,
        uint256 value
    ) public override onlyOwner returns (bool) {
        uint256Metadata[tokenId][key] = value;
        uint256MetadataKeys[tokenId].push(key);
        emit SetUint256(assetStorageContract, tokenId, key, value);
        return true;
    }

    function setUint256Batch(
        uint256[] memory tokenIds,
        string[][] memory keys,
        uint256[][] memory values
    ) public override onlyOwner returns (bool) {
        require(tokenIds.length == keys.length, "tokenIds and keys length mismatch");
        require(tokenIds.length == values.length, "tokenIds and values length mismatch");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            for (uint256 j = 0; j < keys[i].length; j++) {
                setUint256(tokenIds[i], keys[i][j], values[i][j]);
            }
        }

        return true;
    }

    function deleteUint256(uint256 tokenId, string memory key) public override onlyOwner returns (bool) {
        delete uint256Metadata[tokenId][key];

        (bool found, uint256 index) = Utils.search(uint256MetadataKeys[tokenId], key);
        if (found) {
            Utils.remove(uint256MetadataKeys[tokenId], index);
        }

        emit DeleteUint256ByKey(assetStorageContract, tokenId, key);
        return true;
    }

    function deleteUint256(uint256 tokenId) public override onlyOwner returns (bool) {
        for (uint256 i = 0; i < uint256MetadataKeys[tokenId].length; i++) {
            delete uint256Metadata[tokenId][uint256MetadataKeys[tokenId][i]];
        }
        delete uint256MetadataKeys[tokenId];
        emit DeleteUint256(assetStorageContract, tokenId);
        return true;
    }

    function getUint256Keys(uint256 tokenId) public view override returns (string[] memory) {
        return uint256MetadataKeys[tokenId];
    }

    function getUint256(uint256 tokenId, string memory key) public view override returns (uint256) {
        return uint256Metadata[tokenId][key];
    }
}
