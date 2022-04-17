//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IItem721 is IERC721Metadata{
    /**
     * @dev Returns the name of the token.
     */
    function worldAddress() external view returns (address);

    function changeAccountAddress(address oldAddr, address newAddr) external returns (bool);
}