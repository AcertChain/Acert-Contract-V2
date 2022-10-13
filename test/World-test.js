const {
    shouldBehaveLikeWorld,
    shouldBehaveLikeWorldOperator,
    shouldBehaveLikeWorldTrust,
    shouldBehaveLikeWorldAsset,
} = require('./World.behavior');

const Asset20 = artifacts.require('MogaToken');
const Asset20Storage = artifacts.require('Asset20Storage');
const Asset721 = artifacts.require('MogaNFT');
const Asset721Storage = artifacts.require('Asset721Storage');
const World = artifacts.require('MonsterGalaxy');
const WorldStorage = artifacts.require('WorldStorage');
const Metaverse = artifacts.require('MogaMetaverse');
const MetaverseStorage = artifacts.require('MetaverseStorage');

contract('World', function (accounts) {
    const itemName = 'Non Fungible Token';
    const itemSymbol = 'NFT';
    const itemVersion = '1.0.0';

    const cashName = 'My Token';
    const cashSymbol = 'MTKN';
    const cashVersion = '1.0.0';

    beforeEach(async function () {
        this.MetaverseStorage = await MetaverseStorage.new();
        this.Metaverse = await Metaverse.new("metaverse", "1.0", 0, this.MetaverseStorage.address);
        await this.MetaverseStorage.updateMetaverse(this.Metaverse.address);

        this.tokenName = "world";
        this.tokenVersion = "1.0";
        this.WorldStorage = await WorldStorage.new();
        this.world = await World.new(this.Metaverse.address, this.WorldStorage.address, this.tokenName, this.tokenVersion);
        await this.WorldStorage.updateWorld(this.world.address);

        this.newTokenName = "newWorld";
        this.newWorldStorage = await WorldStorage.new();
        this.newWorld = await World.new(this.Metaverse.address, this.newWorldStorage.address, this.newTokenName, this.tokenVersion);
        await this.newWorldStorage.updateWorld(this.newWorld.address);

        this.chainId = await this.world.getChainId();

        this.token721Storage = await Asset721Storage.new();
        this.asset721 = await Asset721.new(itemName, itemSymbol, itemVersion, "", this.world.address, this.token721Storage.address);

        await this.token721Storage.updateAsset(this.asset721.address);

        this.token20Storage = await Asset20Storage.new();
        this.asset20 = await Asset20.new(cashName, cashSymbol, cashVersion, this.world.address, this.token20Storage.address);
        await this.token20Storage.updateAsset(this.asset20.address);


        // register world
        await this.Metaverse.registerWorld(this.world.address);

    });

    shouldBehaveLikeWorld(...accounts);
    shouldBehaveLikeWorldOperator(...accounts);
    shouldBehaveLikeWorldTrust(...accounts);
    shouldBehaveLikeWorldAsset(...accounts);
});