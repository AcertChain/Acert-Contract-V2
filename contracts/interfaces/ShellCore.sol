//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ShellContract is Ownable {
    event UpdateCore(address indexed _contract);

    address public coreContract;

    modifier onlyCore() {
        require(coreContract == _msgSender(), "ShellContract: caller is not the CoreContract");
        _;
    }

    function updateCore(address _address) public virtual onlyOwner {
        coreContract = _address;
        emit UpdateCore(_address);
    }
}

abstract contract CoreContract is Ownable {
    event UpdateShell(address indexed _contract);

    address public shellContract;

    modifier onlyShell() {
        require(shellContract == _msgSender(), "CoreContract: caller is not the ShellContract");
        _;
    }

    function updateShell(address _address) public onlyOwner {
        shellContract = _address;
        emit UpdateShell(_address);
    }
}
