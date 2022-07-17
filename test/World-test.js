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
const World = artifacts.require('World');
const Metaverse = artifacts.require('Metaverse');

contract('World', function (accounts) {
    const itemName = 'Non Fungible Token';
    const itemSymbol = 'NFT';
    const itemVersion = '1.0.0';

    const cashName = 'My Token';
    const cashSymbol = 'MTKN';
    const cashVersion = '1.0.0';

    beforeEach(async function () {
        this.tokenName = "world";
        this.tokenVersion = "1.0";
        this.Metaverse = await Metaverse.new("metaverse", "1.0", 0);
        this.world = await World.new(this.Metaverse.address, this.tokenName, this.tokenVersion);
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