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
    ZERO_ADDRESS
} = constants;

const ownerId = new BN(1);

const deadline = new BN(parseInt(new Date().getTime() / 1000) + 36000);

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

function shouldBehaveLikeWorld(owner) {
    context('World', function () {
        beforeEach(async function () { });
        describe('基础view查询接口', function () {
            context('getTotalAccount', function () {
                it('应该等于avatarMaxId+1', async function () {
                    await this.Metaverse.getOrCreateAccountId(owner);
                    expect(await this.Metaverse.getTotalAccount()).to.be.bignumber.equal(new BN(1));
                });
            });

        });

        describe('Owner', function () {
            context('change owner', function () {
                it('未更新前world 拥有者', async function () {
                    await expectRevert(this.world.changeOwner(owner, {
                        from: owner
                    }), 'only owner');
                });
                it('更新为owner', async function () {
                    expectEvent(await this.world.changeOwner(owner), 'ChangeOwner', {
                        owner: owner
                    });
                    expect(await this.world.owner()).to.equal(owner);
                });
            });
        });
    });

}

function shouldBehaveLikeWorldOperator(operator, owner) {
    context('World Operator', function () {
        beforeEach(async function () { });
        describe('addOperator', function () {
            context('add zero address', function () {
                it('World: zero address', async function () {
                    await expectRevert(this.world.addOperator(ZERO_ADDRESS), 'World: zero address');
                });
            });

            context('add address', function () {
                it('add operator event', async function () {
                    expectEvent(await this.world.addOperator(operator), 'AddOperator', {
                        operator: operator
                    });
                });
            });
        });

        describe('removeOperator', function () {
            context('remove address', function () {
                it('remove operator event', async function () {
                    await this.world.addOperator(operator);
                    expectEvent(await this.world.removeOperator(operator), 'RemoveOperator', {
                        operator: operator
                    });
                    expect(await this.world.isOperator(operator)).to.equal(false);
                });
            });
        });

        describe('isOperator', function () {
            context('query address is operator', function () {
                it('true', async function () {
                    await this.world.addOperator(operator);
                    expect(await this.world.isOperator(operator)).to.equal(true);
                });
            });
        });

        describe('checkBWO', function () {
            context('query address is BWO', function () {
                it('is operator', async function () {
                    await this.world.addOperator(operator);
                    expect(await this.world.checkBWO(operator)).to.equal(true);
                });
                it('is world', async function () {
                    expect(await this.world.checkBWO(await this.world.owner())).to.equal(true);
                });
                it('is not owner', async function () {
                    expect(await this.world.checkBWO(owner)).to.equal(false);
                });
            });
        });
    });
}

function shouldBehaveLikeWorldTrust(contract, account, operator) {
    context('Trust', function () {
        beforeEach(async function () { });
        describe('addContract', function () {
            context('add zero address', function () {
                it('revert', async function () {
                    await expectRevert(this.world.addSafeContract(ZERO_ADDRESS, ""), 'World: zero address');
                });
                it('event AddSafeContract', async function () {
                    expectEvent(await this.world.addSafeContract(contract, "test"), 'AddSafeContract', {
                        safeContract: contract,
                        name: "test"
                    });
                });
            });
        });

        describe('removeContract', function () {
            context('remove contract address', function () {
                it('event RemoveSafeContract', async function () {
                    await this.world.addSafeContract(contract, "");
                    expectEvent(await this.world.removeSafeContract(contract), 'RemoveSafeContract', {
                        safeContract: contract
                    });
                });
            });
        });

        describe('isSafeContract', function () {
            context('contract is safe', function () {
                it('is safe ', async function () {
                    await this.world.addSafeContract(contract, "");
                    expect(await this.world.isSafeContract(contract)).to.equal(true);
                });
                it('is safe by zero address', async function () {
                    expect(await this.world.isSafeContract(ZERO_ADDRESS)).to.equal(false);
                });
            });
        });


        describe('isTrustWorld', function () {
            context('is trust World', function () {
                it('account is not trust World', async function () {
                    await this.Metaverse.getOrCreateAccountId(account);

                    const accountId = new BN(await this.Metaverse.getAccountIdByAddress(account));

                    expect(await this.world.isTrustWorld(accountId)).to.equal(false);
                });

                it('account is trust World', async function () {
                    await this.Metaverse.getOrCreateAccountId(account);
                    const accountId = new BN(await this.Metaverse.getAccountIdByAddress(account));
                    await this.world.trustWorld(accountId, true, {
                        from: account
                    });
                    expect(await this.world.isTrustWorld(accountId)).to.equal(true);
                    await this.world.trustWorld(accountId, false, {
                        from: account
                    });
                    expect(await this.world.isTrustWorld(accountId)).to.equal(false);
                });

                it('account is trust World BWO', async function () {
                    const accountW = Wallet.generate();
                    const account = accountW.getChecksumAddressString();
                    await this.Metaverse.getOrCreateAccountId(account)
                    const accountId = new BN(await this.Metaverse.getAccountIdByAddress(account));
                    await this.world.addOperator(operator)

                    await this.Metaverse.getOrCreateAccountId(operator)

                    const operatorId = new BN(await this.Metaverse.getAccountIdByAddress(operator));


                    const nonce = await this.world.getNonce(account);
                    const signature = signTrustWorldData(this.chainId, this.world.address, this.tokenName,
                        accountW.getPrivateKey(), this.tokenVersion, accountId, true, account, nonce, deadline);
                    await this.world.trustWorldBWO(accountId, true, account, deadline, signature, {
                        from: operator
                    });
                    expect(await this.world.isTrustWorld(accountId)).to.equal(true);

                    const nonce1 = await this.world.getNonce(account);
                    const signature1 = signTrustWorldData(this.chainId, this.world.address, this.tokenName,
                        accountW.getPrivateKey(), this.tokenVersion, accountId, false, account, nonce1, deadline);
                    await this.world.trustWorldBWO(accountId, false, account, deadline, signature1, {
                        from: operator
                    });
                    expect(await this.world.isTrustWorld(accountId)).to.equal(false);
                });

            });
        });


        describe('isTrust', function () {
            context('is Trust', function () {
                it('conrtact is not safe contract ', async function () {
                    await this.Metaverse.getOrCreateAccountId(account);
                    const accountId = new BN(await this.Metaverse.getAccountIdByAddress(account));
                    expect(await this.world.isTrust(contract, accountId)).to.equal(false);
                });
                it('conrtact is safe contract and user not trust world', async function () {
                    await this.Metaverse.getOrCreateAccountId(account);
                    const accountId = new BN(await this.Metaverse.getAccountIdByAddress(account));

                    await this.world.addSafeContract(contract, "");
                    expect(await this.world.isTrust(contract, accountId)).to.equal(false);
                });
                it('conrtact is safe contract and user trust world', async function () {
                    await this.Metaverse.getOrCreateAccountId(account);
                    const accountId = new BN(await this.Metaverse.getAccountIdByAddress(account));
                    await this.world.trustWorld(accountId, true, {
                        from: account
                    });
                    await this.world.addSafeContract(contract, "");
                    expect(await this.world.isTrust(contract, accountId)).to.equal(true);
                });
                it('conrtact is safe contract and user not trust world not trust contract ', async function () {
                    await this.Metaverse.getOrCreateAccountId(account);
                    const accountId = new BN(await this.Metaverse.getAccountIdByAddress(account));

                    await this.world.addSafeContract(contract, "");
                    expect(await this.world.isTrust(contract, accountId)).to.equal(false);
                });
                it('conrtact is safe contract and user not trust world  trust contract ', async function () {
                    await this.Metaverse.getOrCreateAccountId(account);
                    const accountId = new BN(await this.Metaverse.getAccountIdByAddress(account));

                    await this.world.addSafeContract(contract, "");
                    expectEvent(await this.world.trustContract(accountId, contract, true, {
                        from: account
                    }), 'TrustContract', {
                        accountId: accountId,
                        safeContract: contract,
                        isTrustContract: true,
                        isBWO: false,
                        sender: account
                    });
                    expect(await this.world.isTrust(contract, accountId)).to.equal(true);
                    expectEvent(await this.world.trustContract(accountId, contract, false, {
                        from: account
                    }), 'TrustContract', {
                        accountId: accountId,
                        safeContract: contract,
                        isTrustContract: false,
                        isBWO: false,
                        sender: account
                    });
                    expect(await this.world.isTrust(contract, accountId)).to.equal(false);
                });

                it('conrtact is safe contract and user not trust world  trust contract  BWO', async function () {
                    const accountW = Wallet.generate();
                    const account = accountW.getChecksumAddressString();
                    await this.Metaverse.getOrCreateAccountId(account)
                    const accountId = new BN(await this.Metaverse.getAccountIdByAddress(account));
                    await this.world.addOperator(operator)

                    const nonce = await this.world.getNonce(account);
                    const signature = signContractData(this.chainId, this.world.address, this.tokenName,
                        accountW.getPrivateKey(), this.tokenVersion, accountId, contract, true, account, nonce, deadline);


                    await this.world.addSafeContract(contract, "");
                    expectEvent(await this.world.trustContractBWO(accountId, contract, true, account, deadline, signature, {
                        from: operator
                    }), 'TrustContract', {
                        accountId: accountId,
                        safeContract: contract,
                        isTrustContract: true,
                        isBWO: true,
                        sender: account,
                        nonce: nonce,
                    });
                    expect(await this.world.isTrust(contract, accountId)).to.equal(true);

                    const nonce1 = await this.world.getNonce(account);
                    const signature1 = signContractData(this.chainId, this.world.address, this.tokenName,
                        accountW.getPrivateKey(), this.tokenVersion, accountId, contract, false, account, nonce1, deadline);


                    expectEvent(await this.world.trustContractBWO(accountId, contract,false, account, deadline, signature1, {
                        from: operator
                    }), 'TrustContract', {
                        accountId: accountId,
                        safeContract: contract,
                        isTrustContract: false,
                        isBWO: true,
                        sender: account,
                        nonce: nonce1,
                    });
                    expect(await this.world.isTrust(contract, accountId)).to.equal(false);
                });
            });
        });
    });
}

function shouldBehaveLikeWorldAsset() {
    context('World Asset', function () {
        beforeEach(async function () { });
        describe('registerAsset', function () {
            context('zero addres', function () {
                it('revert', async function () {
                    await expectRevert(this.world.registerAsset(ZERO_ADDRESS), 'World: zero address');
                });
            });

            context('addres is exist', function () {
                it('revert', async function () {
                    await this.world.registerAsset(this.asset20.address)
                    await expectRevert(this.world.registerAsset(this.asset20.address), 'World: asset is exist');
                });
            });

            context('RegisterAsset event', function () {
                it('revert', async function () {
                    expectEvent(await this.world.registerAsset(this.asset20.address), 'RegisterAsset', {
                        asset: this.asset20.address,
                    });
                });
            });
        });

        describe('disableAsset', function () {
            it('call disable asset', async function () {
                await this.world.registerAsset(this.asset20.address)
                expectEvent(await this.world.disableAsset(this.asset20.address), "DisableAsset", {
                    asset: this.asset20.address
                });
                expect(await this.world.getAsset(this.asset20.address)).to.deep.equal([true, false, this.asset20.address, '0']);
            });

            it('disable asset', async function () {
                await this.world.registerAsset(this.asset20.address)
                await this.world.disableAsset(this.asset20.address);
                await expectRevert(this.asset20.methods['allowance(uint256,address)'](1, ZERO_ADDRESS), 'World: asset is not exist or disabled');
            });


        });
        describe('getAsset', function () {
            context('get asset ', function () {
                it('get asset', async function () {
                    await this.world.registerAsset(this.asset20.address)
                    expect(await this.world.getAsset(this.asset20.address)).to.deep.equal([true, true, this.asset20.address, '0']);
                });
            });
        });

        describe('update world', function () {
            context('item update world ', function () {
                it('update', async function () {
                    await this.world.registerAsset(this.asset721.address)

                    await this.asset721.updateWorld(this.newWorld.address)

                    expect(await this.asset721.worldAddress()).to.equal(this.newWorld.address);

                });
            });

            context('cash update world ', function () {
                it('update', async function () {

                    await this.world.registerAsset(this.asset20.address)

                    await this.asset20.updateWorld(this.newWorld.address)

                    expect(await this.asset20.worldAddress()).to.equal(this.newWorld.address);

                });
            });
        });
    });
}


function signTrustWorldData(chainId, verifyingContract, name, key, version,
    id, flag, sender, nonce, deadline) {
    const data = {
        types: {
            EIP712Domain,
            BWO: [{ name: 'id', type: 'uint256' },
            { name: "flag", type: "bool" },
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
            flag,
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

function signUnData(chainId, verifyingContract, name, key, version, id,
    sender, nonce, deadline) {
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
function signContractData(chainId, verifyingContract, name, key, version,
    id, contract, flag, sender, nonce, deadline) {
    const data = {
        types: {
            EIP712Domain,
            BWO: [{
                name: 'id',
                type: 'uint256'
            },
            {
                name: 'contract',
                type: 'address'
            },
            {
                name: 'flag',
                type: 'bool'
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
            contract,
            flag,
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

module.exports = {
    shouldBehaveLikeWorld,
    shouldBehaveLikeWorldOperator,
    shouldBehaveLikeWorldTrust,
    shouldBehaveLikeWorldAsset,
};