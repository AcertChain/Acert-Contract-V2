//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../common/Ownable.sol";
import "../storage/MetaverseStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract AuthProxy is Ownable, EIP712 {
    mapping(address => bool) public authAddresses;
    MetaverseStorage public metaStorage;

    constructor(
        string memory name_,
        string memory version_,
        address metaStorage_
    ) EIP712(name_, version_) {
        _owner = msg.sender;
        metaStorage = MetaverseStorage(metaStorage_);
    }

    function addAddrBWO(
        address addr,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(
            authAddresses[sender],
            "AuthProxy: Only authorized address can add address"
        );
        _recoverSig(addr,deadline,sender,signature);
        authAddresses[addr] = true;
    }

    function removeAddrBWO(
        address addr,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(
            authAddresses[sender],
            "AuthProxy: Only authorized address can add address"
        );
        _recoverSig(addr,deadline,sender,signature);
        delete authAddresses[addr];
    }

    function removeAddr(address addr) public onlyOwner {
        delete authAddresses[addr];
    }

    function addAddr(address addr) public onlyOwner {
        authAddresses[addr] = true;
    }

    function _recoverSig(
        address addr,
        uint256 deadline,
        address signer,
        bytes memory signature
    ) internal view {
        require(block.timestamp < deadline, "AuthProxy: BWO call expired");

        uint256 nonce = metaStorage.nonces(signer);
        require(
            signer == ECDSA.recover(_hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(address addr,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        addr,
                        signer,
                        nonce,
                        deadline
                    )
                )
            )
        , signature),
            "AuthProxy: recoverSig failed"
        );
    }
}
