//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../../interfaces/IWorld.sol";
import "../../interfaces/IMetaverse.sol";
import "../../interfaces/IApplyStorage.sol";
import "../../interfaces/IAsset721.sol";
import "../../interfaces/IAsset20.sol";
import "../../interfaces/IAsset.sol";
import "../../storage/WorldStorage.sol";
import "../../common/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract ImportMonsterGalaxyV1 is IWorld, IApplyStorage, Ownable, EIP712 {

    string public override name;
    IMetaverse public metaverse;
    WorldStorage public worldStorage;

    constructor(
        address metaverse_,
        address worldStorage_,
        string memory name_,
        string memory version_
    ) EIP712(name_, version_) {
        metaverse = IMetaverse(metaverse_);
        _owner = msg.sender;
        name = name_;
        worldStorage = WorldStorage(worldStorage_);
    }

    /**
     * @dev See {IApplyStorage-getStorageAddress}.
     */
    function getStorageAddress() external view override returns (address) {
        return address(worldStorage);
    }

    function registerAsset(address _address) public onlyOwner {
        require(_address != address(0), "World: zero address");
        require(address(this) == IAsset(_address).worldAddress(), "World: world address is not match");
        require(worldStorage.getAsset(_address).isExist == false, "World: asset is exist");

        worldStorage.setAsset(_address);
        emit RegisterAsset(_address, IAsset(_address).protocol());
    }

    function getAsset(address _address) public view returns (WorldStorage.Asset memory) {
        return worldStorage.getAsset(_address);
    }

    function trustWorld(uint256 _id, bool _isTrustWorld) public onlyOwner {
        worldStorage.setTrustWorld(_id, _isTrustWorld);
        emit TrustWorld(_id, _isTrustWorld, false, address(0), 0);
    }

    /**
     * @dev See {IWorld-isTrustWorld}.
     */
    function isTrustWorld(uint256 _id) public view virtual override returns (bool _isTrustWorld) {
        return worldStorage.isTrustWorld(_id);
    }

    /**
     * @dev See {IWorld-isTrust}.
     */
    function isTrust(address _contract, uint256 _id) public view virtual override returns (bool _isTrust) {
        return false;
    }

    /**
     * @dev See {IWorld-isTrustContract}.
     */
    function isTrustContract(address _contract, uint256 _id)
        public
        view
        virtual
        override
        returns (bool _isTrustContract)
    {
        return false;
    }

    /**
     * @dev See {IWorld-isBWOByAsset}.
     */
    function checkBWOByAsset(address _address) public view virtual override returns (bool) {
        return false;
    }

    /**
     * @dev See {IWorld-isTrustByAsset}.
     */
    function isTrustByAsset(address _address, uint256 _id)
        public
        view
        virtual
        override
        returns (bool _isTrust)
    {
        return false;
    }

    /**
     * @dev See {IWorld-getMetaverse}.
     */
    function getMetaverse() public view override returns (address) {
        return address(metaverse);
    }

}
