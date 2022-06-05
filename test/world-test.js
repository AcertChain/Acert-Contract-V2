const {
    shouldBehaveLikeWorld,
    shouldBehaveLikeWorldOperator,
    shouldBehaveLikeWorldTrust,
    shouldBehaveLikeWorldAccount,
    shouldBehaveLikeWorldAsset,
    shouldBehaveLikeWorldAvatar,
} = require('./World.behavior');

const Cash20 = artifacts.require('Cash20Mock');
const Item721 = artifacts.require('Item721Mock');
const Avatar = artifacts.require('AvatarMock');
const World = artifacts.require('World');

contract('World', function (accounts) {
    const itemName = 'Non Fungible Token';
    const itemSymbol = 'NFT';
    const itemVersion = '1.0.0';

    const cashName = 'My Token';
    const cashSymbol = 'MTKN';
    const cashVersion = '1.0.0';

    const avatarName = 'My Avatar';
    const avatarSymbol = 'MAVT';
    const avatarVersion = '1.0.0';
    const avataSupply = 100;
    const maxAvatarId =100;
    
    beforeEach(async function () {
        this.world = await World.new();
        this.avatar = await Avatar.new(avataSupply,maxAvatarId, avatarName, avatarSymbol, avatarVersion, this.world.address);
        this.item = await Item721.new(itemName, itemSymbol, itemVersion, this.world.address);
        this.cash = await Cash20.new(cashName, cashSymbol, cashVersion, this.world.address);
        await this.world.registerAvatar(this.avatar.address,  "");
    });

    shouldBehaveLikeWorld(...accounts);
    shouldBehaveLikeWorldOperator(...accounts);
    shouldBehaveLikeWorldTrust(...accounts);
    shouldBehaveLikeWorldAccount(...accounts);
    shouldBehaveLikeWorldAsset(...accounts);
    shouldBehaveLikeWorldAvatar(...accounts);
});