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
        this.Metaverse = await Metaverse.new("metaverse","1.0");
    });

    context('测试Metaverse 功能', function () {
        describe('addWorld ', function () {
            it('zero address should return revert', async function () {
                await expectRevert(
                    this.Metaverse.addWorld(ZERO_ADDRESS, "", "", "", ""), 'Metaverse: zero address',
                );
            });

            it('return event ', async function () {
                const [world] = accounts;
                expectRevert(
                    await this.Metaverse.addWorld(world, "1", "2", "3", "4"),
                    'AddWorld', {
                        world,
                        name: "1",
                        icon: "2",
                        url: "3",
                        description: "4"
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
                await this.Metaverse.addWorld(world, "", "", "", "");
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
                    this.Metaverse.updateWorldInfo(ZERO_ADDRESS, "", "", "", ""), 'Metaverse: zero address',
                );
            });

            it('return event ', async function () {
                const [world] = accounts;
                await this.Metaverse.addWorld(world, "", "", "", "");
                expectRevert(
                    await this.Metaverse.updateWorldInfo(world, "1", "2", "3", "4"),
                    'UpdateWorld', {
                        world,
                        name: "1",
                        icon: "2",
                        url: "3",
                        description: "4"
                    },
                );
            });

        });

        describe('containsWorld, getWorlds, getWorldCount, getWorldInfo', function () {
            beforeEach(async function () {
                this.world = accounts[0];
                await this.Metaverse.addWorld(this.world, "", "", "", "");
            });

            it('containsWorld', async function () {
                expect(await this.Metaverse.containsWorld(this.world)).to.be.equal(true);
                newWorld = accounts[1];
                await this.Metaverse.addWorld(newWorld, "", "", "", "");
                expect(await this.Metaverse.containsWorld(newWorld)).to.be.equal(true);
                await this.Metaverse.removeWorld(newWorld);
                expect(await this.Metaverse.containsWorld(newWorld)).to.be.equal(false);

            });

            it('getWorlds', async function () {
                expect(await this.Metaverse.getWorlds()).to.have.ordered.members([this.world]);
                newWorld = accounts[1];
                await this.Metaverse.addWorld(newWorld, "", "", "", "");
                expect(await this.Metaverse.getWorlds()).to.have.ordered.members([this.world, newWorld]);

            });
            it('getWorldCount', async function () {
                expect(await this.Metaverse.getWorldCount()).to.be.bignumber.equal(new BN(1));
                newWorld = accounts[1];
                await this.Metaverse.addWorld(newWorld, "", "", "", "");
                expect(await this.Metaverse.getWorldCount()).to.be.bignumber.equal(new BN(2));
                await this.Metaverse.removeWorld(newWorld);
                expect(await this.Metaverse.getWorldCount()).to.be.bignumber.equal(new BN(1));
            });

            it('getWorldInfo', async function () {
                newWorld = accounts[1];
                await this.Metaverse.addWorld(newWorld, "1", "2", "3", "4");
                expect(await this.Metaverse.getWorldInfo(newWorld)).have.ordered.members([newWorld, "1", "2", "3", "4"]);
            });
        });
    });
 });


 function shouldBehaveLikeWorldAccount(account, newAccount, operator) {
    context('World Account', function () {
        describe('getOrCreateAccountId', function () {
            context('create account ', function () {
                it('carete account event ', async function () {
                    expectEvent(await this.Metaverse.getOrCreateAccountId(account), 'CreateAccount', {
                        id: new BN(await this.Metaverse.getAccountIdByAddress(account)),
                        account: account
                    });
                });
            });
        });
        describe('getAccountIdByAddress', function () {
            context('get account id by address', function () {
                it('equal 101', async function () {
                    await this.Metaverse.getOrCreateAccountId(account)
                    const avatarMaxId = new BN(await this.avatar.maxAvatar());
                    expect(await this.Metaverse.getAccountIdByAddress(account)).to.bignumber.equal(avatarMaxId.add(new BN(1)));
                });
            });
        });
        describe('getAddressById', function () {
            context('get avatar id', function () {

                it('avatar id is not exist', async function () {
                    await expectRevert(this.Metaverse.getAddressById(new BN(1)), 'Item: owner query for nonexistent token');
                });

                it('avatar id is exist', async function () {
                    await this.Metaverse.getOrCreateAccountId(account)
                    await this.avatar.mint(account, new BN(1));
                    expect(await this.Metaverse.getAddressById(new BN(1))).to.equal(account);
                });
            });

            context('get account id', function () {
                it('account id is not exist', async function () {
                    const avatarMaxId = new BN(await this.avatar.maxAvatar());
                    expect(await this.Metaverse.getAddressById(avatarMaxId.add(new BN(1)))).to.equal(ZERO_ADDRESS);
                });
                it('account id is exist', async function () {
                    await this.Metaverse.getOrCreateAccountId(account)
                    const avatarMaxId = new BN(await this.avatar.maxAvatar());
                    expect(await this.Metaverse.getAddressById(avatarMaxId.add(new BN(1)))).to.equal(account);
                });
            });
        });

        describe('createAccount', function () {
            context('create account ', function () {
                it('zero address', async function () {
                    await expectRevert(this.Metaverse.createAccount(ZERO_ADDRESS, {
                        from: account
                    }), 'World: zero address');

                });
                it('is address exist', async function () {
                    await this.Metaverse.createAccount(account)
                    await expectRevert(this.Metaverse.createAccount(account), "World: address is exist");
                });
            });
        });

        describe('changeAccount', function () {
            context('ueser change account', function () {
                it('is not contract owner', async function () {
                    await this.Metaverse.getOrCreateAccountId(account)
                    const accountId = new BN(await this.Metaverse.getAccountIdByAddress(account));

                    await expectRevert(this.Metaverse.changeAccount(accountId, newAccount, true, {
                        from: newAccount
                    }), 'only owner');
                });

                it('is owner', async function () {
                    await this.Metaverse.getOrCreateAccountId(account)
                    const accountId = new BN(await this.Metaverse.getAccountIdByAddress(account));
                    expectEvent(await this.Metaverse.changeAccount(accountId, newAccount, true), 'UpdateAccount', {
                        id: accountId,
                        newAddress: newAccount,
                        isTrust: true
                    });
                });
            });
        });
    });
}