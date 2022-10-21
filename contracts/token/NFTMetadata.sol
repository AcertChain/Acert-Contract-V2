// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/INFTMetadata.sol";
import "../interfaces/IAcertContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract NFTMetadata is INFTMetadata, IAcertContract, Ownable {

    mapping(uint256 => mapping(string => string)) public stringMetadata;
    mapping(uint256 => mapping(string => uint256)) public uint256Metadata;
    address public assetStorageContract;

    constructor(address assetStorageContract_) {
        assetStorageContract = assetStorageContract_;
        _transferOwnership(Ownable(assetStorageContract_).owner());
    }

    /**
     * @dev See {IAcertContract-metaverseAddress}.
     */
    function metaverseAddress() public view override returns (address) {
        return address(IAcertContract(assetStorageContract).metaverseAddress());
    }

    function setString(uint256 tokenId, string memory key, string memory value) 
        public 
        override
        onlyOwner
        returns (bool) 
    {
        stringMetadata[tokenId][key] = value;
        emit SetString(assetStorageContract, tokenId, key, value);
        return true;
    }

    function getStringKeys(uint256 tokenId) public override view  returns (string[] memory) {
        // todo
    }

    function getString(uint256 tokenId, string memory key)
        public
        override
        view
        returns (string memory) 
    {
        return stringMetadata[tokenId][key];
    }
    
    function setUint256(uint256 tokenId, string memory key, uint256 value) 
        public 
        override
        onlyOwner
        returns (bool) 
    {
        uint256Metadata[tokenId][key] = value;
        emit SetUint256(assetStorageContract, tokenId, key, value);
        return true;
    }

    function getUint256Keys(uint256 tokenId) public override view  returns (string[] memory) {
        // todo
    }

    function getUint256(uint256 tokenId, string memory key)
        public
        override
        view
        returns (uint256) 
    {
        return uint256Metadata[tokenId][key];
    }
}
