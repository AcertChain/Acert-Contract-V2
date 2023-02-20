//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/IAsset721.sol";
import "../interfaces/IAcertContract.sol";
import "../interfaces/Mineable.sol";

contract Asset721 is IAsset721, ShellContract, IAcertContract, Mineable {
    function mint(uint256 to, uint256 tokenId) public onlyMiner {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function safeMint(
        uint256 to,
        uint256 tokenId,
        bytes memory _data
    ) public onlyMiner {
        _safeMint(to, tokenId, _data);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function mintBatch(uint256[] calldata tos, uint256[][] calldata tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tos.length; i++) {
            for (uint256 j = 0; j < tokenIds[i].length; j++) {
                _mint(tos[i], tokenIds[i][j]);
            }
        }
    }

    function core() internal view returns (IAsset721Core) {
        return IAsset721Core(coreContract);
    }

    function emitTransfer(
        address from,
        address to,
        uint256 tokenId
    ) public onlyCore {
        emit Transfer(from, to, tokenId);
    }

    function emitApproval(
        address owner,
        address approved,
        uint256 tokenId
    ) public onlyCore {
        emit Approval(owner, approved, tokenId);
    }

    function emitApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) public onlyCore {
        emit ApprovalForAll(owner, operator, approved);
    }

    function emitAssetTransfer(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bool isBWO,
        address sender,
        uint256 nonce
    ) public onlyCore {
        emit AssetTransfer(from, to, tokenId, isBWO, sender, nonce);
    }

    function emitAssetApproval(
        uint256 ownerId,
        address spender,
        uint256 tokenId,
        bool isBWO,
        address sender,
        uint256 nonce
    ) public onlyCore {
        emit AssetApproval(ownerId, spender, tokenId, isBWO, sender, nonce);
    }

    function emitAssetApprovalForAll(
        uint256 from,
        address to,
        bool approved,
        bool isBWO,
        address sender,
        uint256 nonce
    ) public onlyCore {
        emit AssetApprovalForAll(from, to, approved, isBWO, sender, nonce);
    }

    /**
     * @dev See {IAcertContract-metaverseAddress}.
     */
    function metaverseAddress() external view override returns (address) {
        return IAcertContract(coreContract).metaverseAddress();
    }

    /**
     * @dev See {IERC721-name}.
     */
    function name() public view override returns (string memory) {
        return core().name();
    }

    /**
     * @dev See {IERC721-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return core().symbol();
    }

    /**
     * @dev See {IERC721-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return core().tokenURI(tokenId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        return core().balanceOf(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address owner) {
        return core().ownerOf(tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     * @dev See {IAsset721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        return core().getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return core().isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IAsset-protocol}.
     */
    function protocol() public view override returns (IAsset.ProtocolEnum) {
        return core().protocol();
    }

    /**
     * @dev See {IAsset-worldAddress}.
     */
    function worldAddress() external view override returns (address) {
        return core().worldAddress();
    }

    /**
     * @dev See {IAsset-getNonce}.
     */
    function getNonce(address account) public view override returns (uint256) {
        return core().getNonce(account);
    }

    /**
     * @dev See {IAsset721-balanceOf}.
     */
    function balanceOf(uint256 accountId) public view override returns (uint256) {
        return core().balanceOf(accountId);
    }

    /**
     * @dev See {IAsset721-ownerAccountOf}.
     */
    function ownerAccountOf(uint256 tokenId) public view override returns (uint256 ownerId) {
        return core().ownerAccountOf(tokenId);
    }

    /**
     * @dev See {IAsset721-isApprovedForAll}.
     */
    function isApprovedForAll(uint256 ownerId, address operator) public view override returns (bool) {
        return core().isApprovedForAll(ownerId, operator);
    }

    /**
     * @dev See {IAsset721-itemsOf}.
     */
    function itemsOf(
        uint256 owner,
        uint256 startAt,
        uint256 endAt
    ) public view override returns (uint256[] memory) {
        return core().itemsOf(owner, startAt, endAt);
    }

    /**
     * @dev See {IAsset721-getNFTMetadataContract}.
     */
    function getNFTMetadataContract() public view override returns (address) {
        return core().getNFTMetadataContract();
    }

    // approve
    /**
     * @dev See {IERC721-approve}.
     * @dev See {IAsset721-approve}.
     */
    function approve(address spender, uint256 tokenId) public override {
        return core().approve_(_msgSender(), spender, tokenId);
    }

    /**
     * @dev See {IAsset721-approveBWO}.
     */
    function approveBWO(
        address spender,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override {
        return core().approveBWO_(_msgSender(), spender, tokenId, sender, deadline, signature);
    }

    // approveForALl
    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        return core().setApprovalForAll_(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IAsset721-setApprovalForAll}.
     */
    function setApprovalForAll(
        uint256 accountId,
        address operator,
        bool approved
    ) public override {
        return core().setApprovalForAll_(_msgSender(), accountId, operator, approved);
    }

    /**
     * @dev See {IAsset721-setApprovalForAllBWO}.
     */
    function setApprovalForAllBWO(
        uint256 accountId,
        address operator,
        bool approved,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override {
        return core().setApprovalForAllBWO_(_msgSender(), accountId, operator, approved, sender, deadline, signature);
    }

    // transfer
    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        return core().transferFrom_(_msgSender(), from, to, tokenId);
    }

    /**
     * @dev See {IAsset721-transferFrom}.
     */
    function transferFrom(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 tokenId
    ) public override {
        return core().transferFrom_(_msgSender(), fromAccount, toAccount, tokenId);
    }

    /**
     * @dev See {IAsset721-transferFromBWO}.
     */
    function transferFromBWO(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override {
        return core().transferFromBWO_(_msgSender(), fromAccount, toAccount, tokenId, sender, deadline, signature);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        return core().safeTransferFrom_(_msgSender(), from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        return core().safeTransferFrom_(_msgSender(), from, to, tokenId, data);
    }

    /**
     * @dev See {IAsset721-safeTransferFrom}.
     */
    function safeTransferFrom(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        return core().safeTransferFrom_(_msgSender(), from, to, tokenId, data);
    }

    /**
     * @dev See {IAsset721-safeTransferFromBWO}.
     */
    function safeTransferFromBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory data,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override {
        return core().safeTransferFromBWO_(_msgSender(), from, to, tokenId, data, sender, deadline, signature);
    }

    function _safeMint(
        uint256 to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        return core().safeMint_(_msgSender(), to, tokenId, data);
    }

    function _mint(uint256 to, uint256 tokenId) internal {
        return core().mint_(_msgSender(), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        return core().burn_(_msgSender(), tokenId);
    }
}
