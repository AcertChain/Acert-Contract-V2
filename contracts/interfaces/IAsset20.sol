//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IAsset.sol";

interface IAsset20 is IERC20Metadata, IAsset {
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

    function balanceOf(uint256 account) external view returns (uint256);

    function allowance(uint256 account, address spender) external view returns (uint256);

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
