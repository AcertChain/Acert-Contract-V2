//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract Initializable {
    bool private _initialized;

    event Initialized(uint8 version);

    modifier initializer() {
        _;
        _initialized = true;
        emit Initialized(1);
    }

    modifier onlyInitialized() {
        require(_initialized, "Initializable: contract is not initialized");
        _;
    }
}
