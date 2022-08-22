const {
    BN,
    constants,
    expectEvent,
    expectRevert
} = require('@openzeppelin/test-helpers');

const {
    expect
} = require('chai');

const {
    shouldBehaveLikeWorld,
    shouldBehaveLikeWorldOperator,
    shouldBehaveLikeWorldTrust,
    shouldBehaveLikeWorldAsset,
} = require('./World.behavior');

const Cash20 = artifacts.require('Cash20Mock');
const Item721 = artifacts.require('Item721Mock');
const World = artifacts.require('WorldMock');
const WorldStorage = artifacts.require('WorldStorage');
const Metaverse = artifacts.require('MetaverseMock');
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
        this.newWorld = await World.new(this.Metaverse.address, this.newWorldStorage.address,this.newTokenName, this.tokenVersion);
        await this.newWorldStorage.updateWorld(this.newWorld.address);

        this.chainId = await this.world.getChainId();

        this.item = await Item721.new(itemName, itemSymbol, itemVersion, "", this.world.address);
        this.cash = await Cash20.new(cashName, cashSymbol, cashVersion, this.world.address);

        // register world
        await this.Metaverse.registerWorld(this.world.address, "", "", "", "");

    });

    shouldBehaveLikeWorld(...accounts);
    shouldBehaveLikeWorldOperator(...accounts);
    shouldBehaveLikeWorldTrust(...accounts);
    shouldBehaveLikeWorldAsset(...accounts);
});