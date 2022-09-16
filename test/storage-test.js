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
        this.World = await World.new(this.Metaverse.address, this.WorldStorage.address, this.tokenName, this.tokenVersion);
        await this.WorldStorage.updateWorld(this.World.address);

        this.chainId = await this.World.getChainId();

        this.item = await Item721.new(itemName, itemSymbol, itemVersion, "", this.World.address);
        this.cash = await Cash20.new(cashName, cashSymbol, cashVersion, this.World.address);
    });

    context('测试MetaverseStore 功能', function () {
        describe('测试MetaverseStore ', function () {
            beforeEach(async function () {
                await this.Metaverse.registerWorld(this.World.address, "1", "2", "3", "4");

                this.newMetaverse = await Metaverse.new("newmetaverse", "1.0", 0, this.MetaverseStorage.address);

                await this.MetaverseStorage.updateMetaverse(this.newMetaverse.address);

            });

            it('containsWorld', async function () {
                expect(await this.newMetaverse.containsWorld(this.World.address)).to.be.equal(true);
            });

            it('getWorlds', async function () {
                expect(await this.newMetaverse.getWorlds()).to.have.ordered.members([this.World.address]);

            });
            it('getWorldCount', async function () {
                expect(await this.newMetaverse.getWorldCount()).to.be.bignumber.equal(new BN(1));
            });

            it('getWorldInfo', async function () {
                expect(await this.newMetaverse.getWorldInfo(this.World.address)).have.ordered.members([this.World.address, "1", "2", "3", "4", true]);
            });

        });
    });

    context('测试WorldStore 功能', function () {
        describe('测试WorldStore ', function () {

            beforeEach(async function () {
                // register asset
                await this.World.registerAsset(this.item.address, "");
                await this.World.registerAsset(this.cash.address, "");


                this.newWorld = await World.new(this.Metaverse.address, this.WorldStorage.address, this.tokenName, this.tokenVersion);

                await this.WorldStorage.updateWorld(this.World.address);


            });

            it('get asset', async function () {
                expect(await this.newWorld.getAsset(this.cash.address)).to.deep.equal([true, true, this.cash.address, "MTKN", "", '0']);
                expect(await this.newWorld.getAsset(this.item.address)).to.deep.equal([true, true, this.item.address, "NFT", "", '1']);

            });
        });
    });

});