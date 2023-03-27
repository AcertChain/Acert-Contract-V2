//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ShellCore.sol";
import "./IAsset.sol";

interface IAsset20Metadata is IAsset {
    function balanceOf(uint256 account) external view returns (uint256);

    function allowance(uint256 account, address spender) external view returns (uint256);
}

interface IAsset20 is IERC20Event, IAsset20Metadata, IERC20 {
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
        bytes calldata signature
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
        bytes calldata signature
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
        bytes calldata signature
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
        bytes calldata signature
    ) external returns (bool);

    function mint_(
        address _msgSender,
        uint256 account,
        uint256 amount
    ) external;

    function burn_(
        address _msgSender,
        uint256 account,
        uint256 amount
    ) external;
}
