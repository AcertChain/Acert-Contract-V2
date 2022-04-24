//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IItem721 is IERC721Metadata {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event TransferById(
        uint256 indexed from,
        uint256 indexed to,
        uint256 indexed tokenId
    );

    event TransferByBWO(
        uint256 indexed from,
        uint256 indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event ApprovalById(
        uint256 indexed owner,
        uint256 indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalByBWO(
        uint256 indexed owner,
        uint256 indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAllById(
        uint256 indexed owner,
        uint256 indexed operator,
        bool approved
    );

    event ApprovalForAllByBWO(
        uint256 indexed owner,
        uint256 indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOfById(uint256 owner)
        external
        view
        returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOfById(uint256 tokenId) external view returns (uint256 owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero .
     * - `to` cannot be the zero .
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFromById(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFromByBWO(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata data,
        bytes memory signature
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero .
     * - `to` cannot be the zero .
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFromById(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) external;

    function safeTransferFromByBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero .
     * - `to` cannot be the zero .
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFromById(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) external;

    function transferFromByBWO(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero  clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approveById(uint256 to, uint256 tokenId) external;

    function approveByBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAllById(uint256 operator, bool _approved) external;

    function setApprovalForAllByBWO(
        uint256 sender,
        uint256 operator,
        bool _approved,
        uint256 deadline,
        bytes memory signature
    ) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApprovedById(uint256 tokenId)
        external
        view
        returns (uint256 operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAllById(uint256 owner, uint256 operator)
        external
        view
        returns (bool);

    /**
     * @dev Returns the address of the world.
     */
    function worldAddress() external view returns (address);

    function changeAccountAddress(
        uint256 id,
        address oldAddr,
        address newAddr
    ) external returns (bool);

    function getNonce(uint256 id) external view returns (uint256);
}
