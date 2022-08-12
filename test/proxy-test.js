const {
    BN,
    constants,
    expectEvent,
    expectRevert
} = require('@openzeppelin/test-helpers');

const {
    expect
} = require('chai');

const Cash20 = artifacts.require('Cash20Mock');
const Item721 = artifacts.require('Item721Mock');
const World = artifacts.require('WorldMock');
const WorldStroage = artifacts.require('WorldStroage');
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
        this.Metaverse = await Metaverse.new("metaverse", "1.0", 0);
        this.tokenName = "world";
        this.tokenVersion = "1.0";
        this.world = await World.new(this.Metaverse.address, this.tokenName, this.tokenVersion);
        this.newTokenName = "newWorld";
        this.newWorld = await World.new(this.Metaverse.address, this.newTokenName, this.tokenVersion);
        this.chainId = await this.world.getChainId();

        this.item = await Item721.new(itemName, itemSymbol, itemVersion, "", this.world.address);
        this.cash = await Cash20.new(cashName, cashSymbol, cashVersion, this.world.address);

        // register world
        await this.Metaverse.registerWorld(this.world.address, "", "", "", "");

    });

});