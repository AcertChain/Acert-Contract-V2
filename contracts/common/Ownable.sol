//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Ownable {
    event ChangeOwner(address owner);

    address public _owner;

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "only owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
        emit ChangeOwner(_owner);
    }
}
