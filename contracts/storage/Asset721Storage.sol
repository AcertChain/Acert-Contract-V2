//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../common/Ownable.sol";

contract Asset721Storage is Ownable {
    // nonce
    mapping(address => uint256) public nonces;

    // Mapping from token ID to owner address
    mapping(uint256 => uint256) public ownersById;

    // Mapping owner address to token count
    mapping(uint256 => uint256) public balancesById;

    // Mapping from token ID to approved address
    mapping(uint256 => address) public tokenApprovalsById;

    // Mapping from owner to operator approvals
    mapping(uint256 => mapping(address => bool)) public operatorApprovalsById;

    // Mapping from owner to list of owned token IDs
    mapping(uint256 => mapping(uint256 => uint256)) public ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) public ownedTokensIndex;

    address public asset;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyAsset() {
        require(asset == msg.sender);
        _;
    }

    function updateAsset(address _address) public onlyOwner {
        require(_address != address(0));
        asset = _address;
    }

    function incrementNonce(address _sender) public onlyAsset {
        nonces[_sender]++;
    }

    function setOwnerById(uint256 _id, uint256 _owner) public onlyAsset {
        ownersById[_id] = _owner;
    }

    function deleteOwnerById(uint256 _id) public onlyAsset {
        delete ownersById[_id];
    }

    function setBalanceById(uint256 _id, uint256 _balance) public onlyAsset {
        balancesById[_id] = _balance;
    }

    function setTokenApprovalById(uint256 _id, address _approval) public onlyAsset {
        tokenApprovalsById[_id] = _approval;
    }

    function setOperatorApprovalById(
        uint256 _id,
        address _operator,
        bool _approval
    ) public onlyAsset {
        operatorApprovalsById[_id][_operator] = _approval;
    }

    function setOwnedToken(
        uint256 _id,
        uint256 _index,
        uint256 _tokenId
    ) public onlyAsset {
        ownedTokens[_id][_index] = _tokenId;
    }

    function setOwnedTokenIndex(uint256 _id, uint256 _index) public onlyAsset {
        ownedTokensIndex[_id] = _index;
    }

    function deleteOwnedToken(uint256 _id, uint256 _index) public onlyAsset {
        delete ownedTokens[_id][_index];
    }

    function deleteOwnedTokenIndex(uint256 _id) public onlyAsset {
        delete ownedTokensIndex[_id];
    }
}
