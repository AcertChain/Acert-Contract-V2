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
    ZERO_ADDRESS
} = constants;

const Metaverse = artifacts.require('Metaverse');

contract('Metaverse', function (accounts) {
    beforeEach(async function () {
        this.Metaverse = await Metaverse.new();
    });

    context('测试Metaverse 功能', function () {
        describe('addWorld ', function () {
            it('zero address should return revert', async function () {
                await expectRevert(
                    this.Metaverse.addWorld(ZERO_ADDRESS,"","","",""), 'Metaverse: zero address',
                );
            });

            it('return event ', async function () {
                const [world] = accounts;
                expectRevert(
                    await this.Metaverse.addWorld(world,"1","2","3","4"),
                    'AddWorld', {
                        world,
                        name: "1",
                        icon: "2",
                        url:"3",
                        description:"4"
                    },
                );
            });

        });

        describe('removeWorld ', function () {
            it('zero address should return revert', async function () {
                await expectRevert(
                    this.Metaverse.removeWorld(ZERO_ADDRESS), 'Metaverse: zero address',
                );
            });

            it('return event ', async function () {
                const [world] = accounts;
                await this.Metaverse.addWorld(world,"","","","");
                expectRevert(
                    await this.Metaverse.removeWorld(world),
                    'removeWorld', {
                        world
                    },
                );
            });

        });

        describe('updateWorldInfo ', function () {
            it('zero address should return revert', async function () {
                await expectRevert(
                    this.Metaverse.updateWorldInfo(ZERO_ADDRESS,"","","",""), 'Metaverse: zero address',
                );
            });

            it('return event ', async function () {
                const [world] = accounts;
                await this.Metaverse.addWorld(world,"","","","");
                expectRevert(
                    await this.Metaverse.updateWorldInfo(world,"1","2","3","4"),
                    'UpdateWorld', {
                        world,
                        name: "1",
                        icon: "2",
                        url:"3",
                        description:"4"
                    },
                );
            });

        });

        describe('containsWorld, getWorlds, getWorldCount, getWorldInfo', function () {
            beforeEach(async function () {
                this.world = accounts[0];
                await this.Metaverse.addWorld(this.world,"","","","");
            });

            it('containsWorld', async function () {
                expect(await this.Metaverse.containsWorld(this.world)).to.be.equal(true);
                newWorld = accounts[1];
                await this.Metaverse.addWorld(newWorld,"","","","");
                expect(await this.Metaverse.containsWorld(newWorld)).to.be.equal(true);
                await this.Metaverse.removeWorld(newWorld);
                expect(await this.Metaverse.containsWorld(newWorld)).to.be.equal(false);

            });

            it('getWorlds', async function () {
                expect(await this.Metaverse.getWorlds()).to.have.ordered.members([this.world]);
                newWorld = accounts[1];
                await this.Metaverse.addWorld(newWorld,"","","","");
                expect(await this.Metaverse.getWorlds()).to.have.ordered.members([this.world, newWorld]);

            });
            it('getWorldCount', async function () {
                expect(await this.Metaverse.getWorldCount()).to.be.bignumber.equal(new BN(1));
                newWorld = accounts[1];
                await this.Metaverse.addWorld(newWorld,"","","","");
                expect(await this.Metaverse.getWorldCount()).to.be.bignumber.equal(new BN(2));
                await this.Metaverse.removeWorld(newWorld);
                expect(await this.Metaverse.getWorldCount()).to.be.bignumber.equal(new BN(1));
            });

            it('getWorldInfo', async function () {
                newWorld = accounts[1];
                await this.Metaverse.addWorld(newWorld,"1","2","3","4");
                expect(await this.Metaverse.getWorldInfo(newWorld)).have.ordered.members([newWorld, "1", "2", "3", "4"]);
            });

        });


    });


});