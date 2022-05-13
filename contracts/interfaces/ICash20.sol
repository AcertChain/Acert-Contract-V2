//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ICash20BWO.sol";
import "./IAsset.sol";

interface ICash20 is IERC20Metadata, ICash20BWO, IAsset {
    event TransferId(uint256 indexed from, uint256 indexed to, uint256 value);

    event ApprovalId(
        uint256 indexed owner,
        uint256 indexed spender,
        uint256 value
    );

    function balanceOfId(uint256 account) external view returns (uint256);

    function allowanceId(uint256 owner, uint256 spender)
        external
        view
        returns (uint256);

    function transferCash(
        uint256 from,
        uint256 to,
        uint256 amount
    ) external returns (bool);

    function approveId(
        uint256 owner,
        uint256 spender,
        uint256 amount
    ) external returns (bool);

    function transferCashFrom(
        uint256 from,
        uint256 to,
        uint256 amount
    ) external returns (bool);
}
