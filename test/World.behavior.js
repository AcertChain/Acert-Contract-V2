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

const ownerId = new BN(1);

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

function shouldBehaveLikeWorldTrust(contract, account) {
    context('Trust', function () {
        beforeEach(async function () {});
        describe('addContract', function () {
            context('add zero address', function () {
                it('W01', async function () {
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
                    await this.world.trustWorld(accountId, {from: account});
                    expect(await this.world.isTrustWorld(accountId)).to.equal(true);
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
                    await this.world.trustWorld(accountId, {from: account});
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
                    await expectRevert(this.world.registerAsset(ZERO_ADDRESS, 0, ""), 'World: zero address');
                });
            });

            context('addres is exist', function () {
                it('revert', async function () {
                    await this.world.registerAsset(this.cash.address, 0, "")
                    await expectRevert(this.world.registerAsset(this.cash.address, 0, ""), 'World: asset is exist');
                });
            });

            context('RegisterAsset event', function () {
                it('revert', async function () {
                    expectEvent(await this.world.registerAsset(this.cash.address, 0, "test image"), 'RegisterAsset', {
                        operation: new BN(0),
                        asset: this.cash.address,
                        name: "MTKN",
                        image: "test image"
                    });
                });
            });
        });

        describe('updateAsset', function () {
            context('updateAsset', function () {
                it('zero address', async function () {
                    await expectRevert(this.world.updateAsset(ZERO_ADDRESS, 0, ""), 'World: asset is not exist');
                });
                it('is not exist', async function () {
                    await expectRevert(this.world.updateAsset(this.cash.address, 0, ""), 'World: asset is not exist');
                });
                it('type is not right', async function () {
                    await this.world.registerAsset(this.cash.address, 0, "test image")
                    await expectRevert(this.world.updateAsset(this.cash.address, 1, "test image"), 'World: asset type is not match');
                });
                it('ChangeAsset event', async function () {
                    await this.world.registerAsset(this.cash.address, 0, "test image")
                    expectEvent(await this.world.updateAsset(this.cash.address, 0, "test image"), 'UpdateAsset', {
                        asset: this.cash.address,
                        image: "test image"
                    });
                });
            });
        });
        describe('getAsset', function () {
            context('get asset ', function () {
                it('get asset', async function () {
                    await this.world.registerAsset(this.cash.address, 0, "test image")
                    expect(await this.world.getAsset(this.cash.address)).to.deep.equal(['0', true, this.cash.address, "MTKN", "test image"]);
                });
            });
        });

    });
}

module.exports = {
    shouldBehaveLikeWorld,
    shouldBehaveLikeWorldOperator,
    shouldBehaveLikeWorldTrust,
    shouldBehaveLikeWorldAsset,
};