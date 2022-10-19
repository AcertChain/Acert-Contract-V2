const {
    BN,
    constants,
    expectEvent,
    expectRevert
} = require('@openzeppelin/test-helpers');

const {
    expect
} = require('chai');

const Wallet = require('ethereumjs-wallet').default;
const ethSigUtil = require('eth-sig-util');
const {
    web3, ethers
} = require('hardhat');


//const deadline = new BN(parseInt(new Date().getTime() / 1000) + 36000);
const deadline = new BN(0);

const EIP712Domain = [{
    name: 'name',
    type: 'string'
},
{
    name: 'version',
    type: 'string'
},
{
    name: 'chainId',
    type: 'uint256'
},
{
    name: 'verifyingContract',
    type: 'address'
},
];

const {
    ZERO_ADDRESS
} = constants;

const World = artifacts.require('MonsterGalaxy');
const WorldStorage = artifacts.require('WorldStorage');
const Metaverse = artifacts.require('MogaMetaverse');
const MetaverseStorage = artifacts.require('MetaverseStorage');


contract('Metaverse', function (accounts) {
    beforeEach(async function () {
        this.tokenName = "metaverse";
        this.tokenVersion = "1.0";
        this.MetaverseStorage = await MetaverseStorage.new();
        this.Metaverse = await Metaverse.new(this.tokenName, this.tokenVersion, 0, this.MetaverseStorage.address);
        this.chainId = await this.Metaverse.getChainId();
        await this.MetaverseStorage.updateMetaverse(this.Metaverse.address);

        this.WorldStorage = await WorldStorage.new();
        this.world = await World.new(this.Metaverse.address, this.WorldStorage.address, "world", "1.0");
        await this.WorldStorage.updateWorld(this.world.address);

    });

    context('测试Metaverse 功能', function () {
        describe('registerWorld ', function () {
            it('zero address should return revert', async function () {
                await expectRevert(
                    this.Metaverse.registerWorld(ZERO_ADDRESS), 'Metaverse: address is zero',
                );
            });

            it('return event ', async function () {
                expectEvent(
                    await this.Metaverse.registerWorld(this.world.address),
                    'RegisterWorld', {
                    world: this.world.address,
                    name: "world"
                },
                );
            });

        });

        describe('disableWorld ', function () {
            it('zero address should return revert', async function () {
                await expectRevert(
                    this.Metaverse.disableWorld(ZERO_ADDRESS), 'Metaverse: address is zero',
                );
            });
        });

        describe('setAdmin', function () {
            it('zero address should return revert', async function () {
                await expectRevert(
                    this.Metaverse.setAdmin(ZERO_ADDRESS), 'Metaverse: address is zero',
                );
            });

            it('return event ', async function () {
                const [admin] = accounts;
                expectEvent(
                    await this.Metaverse.setAdmin(admin),
                    'SetAdmin', {
                    admin
                },
                );
            });
        });

        describe('addOperator', function () {
            it('zero address should return revert', async function () {
                await expectRevert(
                    this.Metaverse.addOperator(ZERO_ADDRESS), 'Metaverse: address is zero',
                );
            });

            it('return event ', async function () {
                const [operator] = accounts;
                expectEvent(
                    await this.Metaverse.addOperator(operator),
                    'AddOperator', {
                    operator
                },
                );
            });
        });

        describe('removeOperator', function () {
            it('return event ', async function () {
                const [operator] = accounts;
                await this.Metaverse.addOperator(operator);
                expectEvent(
                    await this.Metaverse.removeOperator(operator),
                    'RemoveOperator', {
                    operator
                },
                );
            });
        });

        describe('isOperator,isBWO', function () {
            it('check', async function () {
                const [operator] = accounts;
                expect(await this.Metaverse.isOperator(operator)).to.be.equal(false);
                expect(await this.Metaverse.checkBWO(operator)).to.be.equal(false);
                await this.Metaverse.addOperator(operator)
                expect(await this.Metaverse.isOperator(operator)).to.be.equal(true);
                expect(await this.Metaverse.checkBWO(operator)).to.be.equal(true);
            });

        });

        describe('containsWorld, getWorlds, getWorldCount, getWorldInfo', function () {
            beforeEach(async function () {
                await this.Metaverse.registerWorld(this.world.address);
            });

            it('containsWorld', async function () {
                expect(await this.Metaverse.containsWorld(this.world.address)).to.be.equal(true);
            });

            it('getWorlds', async function () {
                expect(await this.Metaverse.getWorlds()).to.have.ordered.members([this.world.address]);

            });
            it('getWorldCount', async function () {
                expect(await this.Metaverse.getWorldCount()).to.be.bignumber.equal(new BN(1));
            });

            it('getWorldInfo', async function () {
                expect(await this.Metaverse.getWorldInfo(this.world.address)).have.ordered.members([this.world.address, "world", true]);
            });
        });
    });

    context('Account', function () {
        describe('getOrCreateAccountId', function () {
            context('create account ', function () {
                it('carete account event ', async function () {
                    const [account] = accounts;
                    expectEvent(await this.Metaverse.getOrCreateAccountId(account), 'CreateAccount', {
                        accountId: new BN(await this.Metaverse.getAccountIdByAddress(account)),
                        authAddress: account,
                        isTrustAdmin: false
                    });
                });
            });
        });
        describe('getIdByAddress', function () {
            context('get account id by address', function () {
                it('equal 101', async function () {
                    const [account] = accounts;
                    await this.Metaverse.getOrCreateAccountId(account)
                    expect(await this.Metaverse.getAccountIdByAddress(account)).to.bignumber.equal(new BN(1));
                });
            });
        });
        describe('getAddressByAccountId', function () {
            context('get account id', function () {
                it('account id is not exist', async function () {
                    expect(await this.Metaverse.getAddressByAccountId(new BN(1))).to.equal(ZERO_ADDRESS);
                });
                it('account id is exist', async function () {
                    const [account] = accounts;
                    await this.Metaverse.getOrCreateAccountId(account)
                    expect(await this.Metaverse.getAddressByAccountId(new BN(1))).to.equal(account);
                });
            });
        });

        describe('createAccount', function () {
            context('create account ', function () {
                it('zero address', async function () {
                    const [account] = accounts;
                    await expectRevert(this.Metaverse.createAccount(ZERO_ADDRESS, {
                        from: account
                    }), 'Metaverse: address is zero');

                });
                it('is address exist', async function () {
                    const [account] = accounts;
                    await this.Metaverse.createAccount(account, true)
                    await expectRevert(this.Metaverse.createAccount(account, true), "Metaverse: new address has been used");
                });
            });
        });

        describe('createAccount with start id', function () {
            context('create account ', function () {
                it('id expect 11', async function () {
                    this.newMetaverseStorage = await MetaverseStorage.new();
                    this.newMetaverse = await Metaverse.new(this.tokenName, this.tokenVersion, 10, this.newMetaverseStorage.address);
                    this.newMetaverseStorage.updateMetaverse(this.newMetaverse.address)
                    const [account] = accounts;
                    await this.newMetaverse.getOrCreateAccountId(account)
                    expect(await this.newMetaverse.getAccountIdByAddress(account)).to.bignumber.equal(new BN(11));
                });
            });
        });

        describe('freezeAccount', function () {
            it('return event', async function () {
                const [account] = accounts;
                await this.Metaverse.getOrCreateAccountId(account);
                const accountId = new BN(await this.Metaverse.getAccountIdByAddress(account));

                expectEvent(await this.Metaverse.freezeAccount(accountId, {
                    from: account
                }), 'FreezeAccount', {
                    accountId: accountId,
                    isBWO: false
                });

                expect(await this.Metaverse.isFreeze(accountId)).to.be.equal(true);
            });

            it('is BWO', async function () {
                const accountW = Wallet.generate();
                const account = accountW.getChecksumAddressString();
                await this.Metaverse.getOrCreateAccountId(account)
                const accountId = new BN(await this.Metaverse.getAccountIdByAddress(account));
                const [operator] = accounts;
                await this.Metaverse.addOperator(operator)

                const nonce = await this.Metaverse.getNonce(account);
                const signature = signFreezeAccountData(this.chainId, this.Metaverse.address, this.tokenName,
                    accountW.getPrivateKey(), this.tokenVersion, accountId, account, nonce, deadline);

                expectEvent(await this.Metaverse.freezeAccountBWO(accountId, account, deadline, signature, {
                    from: operator
                }), 'FreezeAccount', {
                    accountId: accountId,
                    isBWO: true
                });

                expect(await this.Metaverse.isFreeze(accountId)).to.be.equal(true);

            });
        });

        describe('unfreezeAccount', function () {
            it('return event', async function () {

                const [account, admin, newAccount] = accounts;
                await this.Metaverse.setAdmin(admin);

                await this.Metaverse.getOrCreateAccountId(account);
                const accountId = new BN(await this.Metaverse.getAccountIdByAddress(account));
                expect(await this.Metaverse.isFreeze(accountId)).to.be.equal(false);

                await this.Metaverse.freezeAccount(accountId, {
                    from: account
                });
                expect(await this.Metaverse.isFreeze(accountId)).to.be.equal(true);

                expectEvent(await this.Metaverse.unfreezeAccount(accountId, newAccount, {
                    from: admin
                }), 'UnFreezeAccount', {
                    accountId: accountId
                });

                expect(await this.Metaverse.isFreeze(accountId)).to.be.equal(false);

            });

        });

        describe('addAuthAddress and removeAuthAddress', function () {
            it('add and remove', async function () {

                const [owner, authAccount] = accounts;

                await this.Metaverse.getOrCreateAccountId(owner);

                const ownerId = await this.Metaverse.getAccountIdByAddress(owner);

                this.domain = {
                    name: "metaverse",
                    version: "1.0",
                    chainId: this.chainId.toString(),
                    verifyingContract: this.Metaverse.address
                };

                this.signAuthTypes = {
                    AddAuth: [
                        {
                            name: 'id',
                            type: 'uint256'
                        },
                        {
                            name: 'addr',
                            type: 'address'
                        },
                        {
                            name: 'sender',
                            type: 'address'
                        },
                        {
                            name: 'nonce',
                            type: 'uint256'
                        },
                        {
                            name: 'deadline',
                            type: 'uint256'
                        },
                    ],
                };

                const value = { id: ownerId.toString(), addr: authAccount, sender: owner, nonce: '0', deadline: deadline.toString() };

                this.authAccountSinger = await ethers.getSigner(authAccount)

                const signature = await this.authAccountSinger._signTypedData(this.domain, this.signAuthTypes, value)

                await this.Metaverse.addAuthAddress(ownerId, authAccount, deadline, signature, {
                    from: owner
                });

                expect(await this.Metaverse.getAccountIdByAddress(authAccount)).to.be.bignumber.equal(ownerId);

                await this.Metaverse.removeAuthAddress(ownerId, owner, { from: authAccount });

                expect(await this.Metaverse.getAddressByAccountId(ownerId)).to.be.equal(authAccount);
            });
        });
    });
});

function signFreezeAccountData(chainId, verifyingContract, name, key, version,
    id, sender, nonce, deadline) {
    const data = {
        types: {
            EIP712Domain,
            BWO: [{
                name: 'id',
                type: 'uint256'
            },
            {
                name: 'sender',
                type: 'address'
            },
            {
                name: 'nonce',
                type: 'uint256'
            },
            {
                name: 'deadline',
                type: 'uint256'
            },
            ],
        },
        domain: {
            name,
            version,
            chainId,
            verifyingContract
        },
        primaryType: 'BWO',
        message: {
            id,
            sender,
            nonce,
            deadline
        },
    };

    const signature = ethSigUtil.signTypedMessage(key, {
        data
    });

    return signature;
}

