//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ShellCore.sol";
import "./IAsset.sol";

interface IAsset20Metadata is IAsset {
    function balanceOf(uint256 account) external view returns (uint256);

    function allowance(uint256 account, address spender) external view returns (uint256);
}

interface IAsset20 is IAsset20Metadata, IERC20 {
    function transferFrom(
        uint256 from,
        uint256 to,
        uint256 amount
    ) external returns (bool);

    function transferFromBWO(
        uint256 from,
        uint256 to,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external returns (bool);

    function approve(
        uint256 account,
        address spender,
        uint256 amount
    ) external returns (bool);

    function approveBWO(
        uint256 account,
        address spender,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external returns (bool);
}

interface IAsset20Core is IAsset20Metadata, IERC20Metadata {
    function transfer_(
        address _msgSender,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferFrom_(
        address _msgSender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferFrom_(
        address _msgSender,
        uint256 from,
        uint256 to,
        uint256 amount
    ) external returns (bool);

    function transferFromBWO_(
        address _msgSender,
        uint256 from,
        uint256 to,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external returns (bool);

    function approve_(
        address _msgSender,
        address spender,
        uint256 amount
    ) external returns (bool);

    function approve_(
        address _msgSender,
        uint256 account,
        address spender,
        uint256 amount
    ) external returns (bool);

    function approveBWO_(
        address _msgSender,
        uint256 account,
        address spender,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external returns (bool);

    function mint_(
        address _msgSender,
        uint256 account,
        uint256 amount
    ) external;

    function mint_(
        address _msgSender,
        address account,
        uint256 amount
    ) external;

    function burn_(
        address _msgSender,
        uint256 account,
        uint256 amount
    ) external;

    function burn_(
        address _msgSender,
        address account,
        uint256 amount
    ) external;

}

abstract contract Asset20Shell is IERC20Event, ShellContract {
    event AssetTransfer(
        uint256 indexed from,
        uint256 indexed to,
        uint256 value,
        bool isBWO,
        address indexed sender,
        uint256 nonce
    );

    event AssetApproval(
        uint256 indexed owner,
        address indexed spender,
        uint256 value,
        bool isBWO,
        address indexed sender,
        uint256 nonce
    );

    function emitTransfer(
        address from,
        address to,
        uint256 value
    ) public onlyCore {
        emit Transfer(from, to, value);
    }

    function emitApproval(
        address owner,
        address spender,
        uint256 value
    ) public onlyCore {
        emit Approval(owner, spender, value);
    }

    function emitAssetTransfer(
        uint256 from,
        uint256 to,
        uint256 value,
        bool isBWO,
        address sender,
        uint256 nonce
    ) public onlyCore {
        emit AssetTransfer(from, to, value, isBWO, sender, nonce);
    }

    function emitAssetApproval(
        uint256 owner,
        address spender,
        uint256 value,
        bool isBWO,
        address sender,
        uint256 nonce
    ) public onlyCore {
        emit AssetApproval(owner, spender, value, isBWO, sender, nonce);
    }
}
