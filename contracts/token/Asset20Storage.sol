//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IAsset20.sol";
import "../interfaces/IAcertContract.sol";

contract Asset20Storage is IAcertContract, Ownable {
    mapping(uint256 => uint256) public balancesById;
    mapping(uint256 => mapping(address => uint256)) public allowancesById;
    mapping(address => uint256) public nonces;

    uint256 public totalSupply;
    address public asset;

    constructor() {}

    modifier onlyAsset() {
        require(asset == msg.sender);
        _;
    }

    /**
     * @dev See {IAcertContract-metaverseAddress}.
     */
    function metaverseAddress() public view override returns (address) {
        return address(IAcertContract(asset).metaverseAddress());
    }

    function updateAsset(address _address) public onlyOwner {
        require(_address != address(0));
        asset = _address;
    }

    function incrementNonce(address _sender) public onlyAsset {
        nonces[_sender]++;
    }

    function setTotalSupply(uint256 _totalSupply) public onlyAsset {
        totalSupply = _totalSupply;
    }

    function setBalanceById(uint256 _id, uint256 _balance) public onlyAsset {
        balancesById[_id] = _balance;
    }

    function setAllowanceById(
        uint256 _id,
        address _spender,
        uint256 _allowance
    ) public onlyAsset {
        allowancesById[_id][_spender] = _allowance;
    }
}

