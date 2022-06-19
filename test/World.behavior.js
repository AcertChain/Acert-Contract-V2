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
        beforeEach(async function () {});
        describe('基础view查询接口', function () {
            context('getTotalAccount', function () {
                it('应该等于avatarMaxId+1', async function () {
                    await this.world.getOrCreateAccountId(owner);
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
        beforeEach(async function () {});
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

        describe('isBWO', function () {
            context('query address is BWO', function () {
                it('is operator', async function () {
                    await this.world.addOperator(operator);
                    expect(await this.world.isBWO(operator)).to.equal(true);
                });
                it('is world', async function () {
                    expect(await this.world.isBWO(await this.world.owner())).to.equal(true);
                });
                it('is not owner', async function () {
                    expect(await this.world.isBWO(owner)).to.equal(false);
                });
            });
        });
    });
}

function shouldBehaveLikeWorldTrust(contract, account, operator) {
    context('Trust', function () {
        beforeEach(async function () {});
        describe('addContract', function () {
            context('add zero address', function () {
                it('revert', async function () {
                    await expectRevert(this.world.addContract(ZERO_ADDRESS), 'World: zero address');
                });
                it('event AddSafeContract', async function () {
                    expectEvent(await this.world.addContract(contract), 'AddSafeContract', {
                        safeContract: contract
                    });
                });
            });
        });

        describe('removeContract', function () {
            context('remove contract address', function () {
                it('event RemoveSafeContract', async function () {
                    await this.world.addContract(contract);
                    expectEvent(await this.world.removeContract(contract), 'RemoveSafeContract', {
                        safeContract: contract
                    });
                });
            });
        });

        describe('isSafeContract', function () {
            context('contract is safe', function () {
                it('is safe ', async function () {
                    await this.world.addContract(contract);
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
                    await this.world.getOrCreateAccountId(account);
                    expect(await this.world.isTrustWorld(account)).to.equal(false);
                });

                it('account is trust World', async function () {
                    await this.world.getOrCreateAccountId(account);
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));
                    await this.world.trustWorld(accountId, {
                        from: account
                    });
                    expect(await this.world.isTrustWorld(accountId)).to.equal(true);
                    await this.world.untrustWorld(accountId, {
                        from: account
                    });
                    expect(await this.world.isTrustWorld(account)).to.equal(false);
                });

                it('account is trust World BWO', async function () {
                    const accountW = Wallet.generate();
                    const account = accountW.getChecksumAddressString();
                    await this.world.getOrCreateAccountId(account)
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));
                    await this.world.addOperator(operator)
                    const nonce = await this.world.getNonce(account);
                    const signature = signData(this.chainId, this.world.address, this.tokenName,
                        accountW.getPrivateKey(), this.tokenVersion, accountId, account, nonce, deadline);
                    await this.world.trustWorldBWO(accountId, account, deadline, signature, {
                        from: operator
                    });
                    expect(await this.world.isTrustWorld(accountId)).to.equal(true);

                    const nonce1 = await this.world.getNonce(account);
                    const signature1 = signData(this.chainId, this.world.address, this.tokenName,
                        accountW.getPrivateKey(), this.tokenVersion, accountId, account, nonce1, deadline);
                    await this.world.untrustWorldBWO(accountId, account, deadline, signature1, {
                        from: operator
                    });
                    expect(await this.world.isTrustWorld(account)).to.equal(false);
                });

            });
        });


        describe('isTrust', function () {
            context('is Trust', function () {
                it('conrtact is not safe contract ', async function () {
                    await this.world.getOrCreateAccountId(account);
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));
                    expect(await this.world.isTrust(contract, accountId)).to.equal(false);
                });
                it('conrtact is safe contract and user not trust world', async function () {
                    await this.world.getOrCreateAccountId(account);
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));

                    await this.world.addContract(contract);
                    expect(await this.world.isTrust(contract, accountId)).to.equal(false);
                });
                it('conrtact is safe contract and user trust world', async function () {
                    await this.world.getOrCreateAccountId(account);
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));
                    await this.world.trustWorld(accountId, {
                        from: account
                    });
                    await this.world.addContract(contract);
                    expect(await this.world.isTrust(contract, accountId)).to.equal(true);
                });
                it('conrtact is safe contract and user not trust world not trust contract ', async function () {
                    await this.world.getOrCreateAccountId(account);
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));

                    await this.world.addContract(contract);
                    expect(await this.world.isTrust(contract, accountId)).to.equal(false);
                });
                it('conrtact is safe contract and user not trust world  trust contract ', async function () {
                    await this.world.getOrCreateAccountId(account);
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));

                    await this.world.addContract(contract);
                    expectEvent(await this.world.trustContract(accountId, contract, {
                        from: account
                    }), 'TrustContract', {
                        id: accountId,
                        safeContract: contract
                    });
                    expect(await this.world.isTrust(contract, accountId)).to.equal(true);
                    expectEvent(await this.world.untrustContract(accountId, contract, {
                        from: account
                    }), 'UntrustContract', {
                        id: accountId,
                        safeContract: contract
                    });
                    expect(await this.world.isTrust(contract, accountId)).to.equal(false);
                });

                it('conrtact is safe contract and user not trust world  trust contract  BWO', async function () {
                    const accountW = Wallet.generate();
                    const account = accountW.getChecksumAddressString();
                    await this.world.getOrCreateAccountId(account)
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));
                    await this.world.addOperator(operator)
                    const nonce = await this.world.getNonce(account);
                    const signature = signContractData(this.chainId, this.world.address, this.tokenName,
                        accountW.getPrivateKey(), this.tokenVersion, accountId, contract, account, nonce, deadline);


                    await this.world.addContract(contract);
                    expectEvent(await this.world.trustContractBWO(accountId, contract, account, deadline, signature, {
                        from: operator
                    }), 'TrustContractBWO', {
                        id: accountId,
                        safeContract: contract,
                        sender: account,
                        nonce: nonce,
                        deadline: deadline,
                    });
                    expect(await this.world.isTrust(contract, accountId)).to.equal(true);

                    const nonce1 = await this.world.getNonce(account);
                    const signature1 = signContractData(this.chainId, this.world.address, this.tokenName,
                        accountW.getPrivateKey(), this.tokenVersion, accountId, contract, account, nonce1, deadline);


                    expectEvent(await this.world.untrustContractBWO(accountId, contract, account, deadline, signature1, {
                        from: operator
                    }), 'UntrustContractBWO', {
                        id: accountId,
                        safeContract: contract,
                        sender: account,
                        nonce: nonce1,
                        deadline: deadline,
                    });
                    expect(await this.world.isTrust(contract, accountId)).to.equal(false);
                });
            });
        });
    });
}

function shouldBehaveLikeWorldAsset() {
    context('World Asset', function () {
        beforeEach(async function () {});
        describe('registerAsset', function () {
            context('zero addres', function () {
                it('revert', async function () {
                    await expectRevert(this.world.registerAsset(ZERO_ADDRESS, ""), 'World: zero address');
                });
            });

            context('addres is exist', function () {
                it('revert', async function () {
                    await this.world.registerAsset(this.cash.address, "")
                    await expectRevert(this.world.registerAsset(this.cash.address, ""), 'World: asset is exist');
                });
            });

            context('RegisterAsset event', function () {
                it('revert', async function () {
                    expectEvent(await this.world.registerAsset(this.cash.address, "test image"), 'RegisterAsset', {
                        asset: this.cash.address,
                        name: "MTKN",
                        image: "test image",
                        protocol: new BN(0)
                    });
                });
            });
        });

        describe('updateAsset', function () {
            context('updateAsset', function () {
                it('zero address', async function () {
                    await expectRevert(this.world.updateAsset(ZERO_ADDRESS, ""), 'World: asset is not exist');
                });
                it('is not exist', async function () {
                    await expectRevert(this.world.updateAsset(this.cash.address, ""), 'World: asset is not exist');
                });
                it('ChangeAsset event', async function () {
                    await this.world.registerAsset(this.cash.address, "test image")
                    expectEvent(await this.world.updateAsset(this.cash.address, "test image"), 'UpdateAsset', {
                        asset: this.cash.address,
                        image: "test image"
                    });
                });
            });
        });
        describe('getAsset', function () {
            context('get asset ', function () {
                it('get asset', async function () {
                    await this.world.registerAsset(this.cash.address, "test image")
                    expect(await this.world.getAsset(this.cash.address)).to.deep.equal([true, this.cash.address, "MTKN", "test image", '0']);
                });
            });
        });

    });
}


function signData(chainId, verifyingContract, name, key, version,
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

function signContractData(chainId, verifyingContract, name, key, version,
    id, contract, sender, nonce, deadline) {
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