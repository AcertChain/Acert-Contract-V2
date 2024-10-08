//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IAcertContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Asset721Storage is IAcertContract, Ownable {
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

    address public asset;

    modifier onlyAsset() {
        require(asset == msg.sender);
        _;
    }

    /**
     * @dev See {IAcertContract-vchainAddress}.
     */
    function vchainAddress() public view override returns (address) {
        return address(IAcertContract(asset).vchainAddress());
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
}
