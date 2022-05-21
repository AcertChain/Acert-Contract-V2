//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ICash20BWO.sol";
import "./IAsset.sol";

interface ICash20 is IERC20Metadata, ICash20BWO, IAsset {
    event TransferCash(uint256 indexed from, uint256 indexed to, uint256 value);

    event ApprovalCash(uint256 indexed owner, address spender, uint256 value);

    function balanceOfCash(uint256 account) external view returns (uint256);

    function allowanceCash(uint256 owner, address spender)
        external
        view
        returns (uint256);

    function approveCash(
        uint256 owner,
        address spender,
        uint256 amount
    ) external returns (bool);

    function transferCash(
        uint256 from,
        uint256 to,
        uint256 amount
    ) external returns (bool);
}
