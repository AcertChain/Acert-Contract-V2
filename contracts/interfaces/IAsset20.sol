//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ShellCore.sol";
import "./IAsset.sol";

interface IAsset20Metadata is IAsset , IERC20Metadata {

    function balanceOf(uint256 account) external view returns (uint256);

    function allowance(uint256 account, address spender) external view returns (uint256);
}

interface IAsset20 is IAsset20Metadata {
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

interface IAsset20Core is IAsset20Metadata {
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

    function approve_(address _msgSender, address spender, uint256 amount) external returns (bool);

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
    
    function mint_(address _msgSender, uint256 account, uint256 amount) external;
}

contract Asset20Shell is ShellContract {
    /**
     * @dev See {IERC20-event-Transfer}.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev See {IERC20-event-Approval}.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
// interface IERC20Metadata {

//     /**
//      * @dev Returns the amount of tokens in existence.
//      */
//     function totalSupply() external view returns (uint256);

//     /**
//      * @dev Returns the amount of tokens owned by `account`.
//      */
//     function balanceOf(address account) external view returns (uint256);

//     /**
//      * @dev Returns the remaining number of tokens that `spender` will be
//      * allowed to spend on behalf of `owner` through {transferFrom}. This is
//      * zero by default.
//      *
//      * This value changes when {approve} or {transferFrom} are called.
//      */
//     function allowance(address owner, address spender) external view returns (uint256);

//     /**
//      * @dev Returns the name of the token.
//      */
//     function name() external view returns (string memory);

//     /**
//      * @dev Returns the symbol of the token.
//      */
//     function symbol() external view returns (string memory);

//     /**
//      * @dev Returns the decimals places of the token.
//      */
//     function decimals() external view returns (uint8);
// }
