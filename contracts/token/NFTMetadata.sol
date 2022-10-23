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
    mapping(uint256 => mapping(string => string)) public metadata;
    mapping(uint256 => mapping(string => INFTMetadata.ValueType)) public metadataTypes;
    mapping(uint256 => string[]) public metadataKeys;

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

    function setMetadata(
        uint256 tokenId,
        string memory key,
        string memory value,
        INFTMetadata.ValueType valueType
    ) public override onlyOwner returns (bool) {
        require(tokenId > 0, "tokenId must be greater than 0");
        require(bytes(key).length > 0, "key cannot be empty");
        require(bytes(value).length > 0, "value cannot be empty");

        metadata[tokenId][key] = value;
        metadataKeys[tokenId].push(key);
        metadataTypes[tokenId][key] = valueType;
        emit SetMetadata(assetStorageContract, tokenId, key, value, valueType);
        return true;
    }

    function batchSetMetadata(
        uint256[] memory tokenIds,
        string[][] memory keys,
        string[][] memory values,
        INFTMetadata.ValueType[][] memory valueTypes
    ) public override onlyOwner returns (bool) {
        require(
            tokenIds.length == keys.length && tokenIds.length == values.length && tokenIds.length == valueTypes.length,
            "tokenIds and keys and values and types length mismatch"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            for (uint256 j = 0; j < keys[i].length; j++) {
                uint256 tokenId = tokenIds[i];
                string memory key = keys[i][j];
                string memory value = values[i][j];
                INFTMetadata.ValueType valueType = valueTypes[i][j];
                require(tokenId > 0, "tokenId must be greater than be 0");
                require(bytes(key).length > 0, "key cannot be empty");
                require(bytes(value).length > 0, "value cannot be empty");

                metadata[tokenId][key] = value;
                metadataKeys[tokenId].push(key);
                metadataTypes[tokenId][key] = valueType;
                emit SetMetadata(assetStorageContract, tokenId, key, value, valueType);
            }
        }
        return true;
    }

    function getKeys(uint256 tokenId) public view override onlyOwner returns (string[] memory) {
        return metadataKeys[tokenId];
    }

    function getValue(uint256 tokenId, string memory key)
        public
        view
        override
        onlyOwner
        returns (string memory, INFTMetadata.ValueType)
    {
        return (metadata[tokenId][key], metadataTypes[tokenId][key]);
    }

    function removeMetadata(uint256 tokenId, string memory key) public override onlyOwner returns (bool) {
        (bool found, uint256 index) = Utils.search(metadataKeys[tokenId], key);
        if (found) {
            Utils.remove(metadataKeys[tokenId], index);
        }
        delete metadata[tokenId][key];
        delete metadataTypes[tokenId][key];
        return true;
    }

    function clearMetadata(uint256 tokenId) public override onlyOwner returns (bool) {
        for (uint256 i = 0; i < metadataKeys[tokenId].length; i++) {
            string memory key =  metadataKeys[tokenId][i];
            delete metadata[tokenId][key];
            delete metadataTypes[tokenId][key];
        }
        delete metadataKeys[tokenId];

        emit ClearMetadata(assetStorageContract, tokenId);
        return true;
    }
}
