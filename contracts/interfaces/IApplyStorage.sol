//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IApplyStorage {

    function getStorageAddress() external view returns (address _storage);
}
