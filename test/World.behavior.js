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
                    const avatarMaxId = new BN(await this.avatar.maxAvatar());
                    expect(await this.world.getTotalAccount()).to.be.bignumber.equal(avatarMaxId.add(new BN(1)));
                });
            });

            context('getAvatarMaxId', function () {
                it('与avatar 发行量的地址相等', async function () {
                    const avatarMaxId = new BN(await this.avatar.maxAvatar());
                    expect(await this.world.getAvatarMaxId()).to.be.bignumber.equal(avatarMaxId);
                });
            });

            context('getAvatar', function () {
                it('与avatar 合约的地址相等', async function () {
                    expect(await this.world.getAvatar()).to.equal(this.avatar.address);
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
                    await this.world.changeAccount(accountId, account, true);
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

                    await this.world.addContract(contract);
                    await this.world.changeAccount(accountId, account, true);
                    expect(await this.world.isTrust(contract, accountId)).to.equal(true);
                });
                it('conrtact is safe contract and user not trust world not trust contract ', async function () {
                    await this.world.getOrCreateAccountId(account);
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));

                    await this.world.addContract(contract);
                    await this.world.changeAccount(accountId, account, true);
                    await this.world.changeAccount(accountId, account, false);
                    expect(await this.world.isTrust(contract, accountId)).to.equal(false);
                });
                it('conrtact is safe contract and user not trust world  trust contract ', async function () {
                    await this.world.getOrCreateAccountId(account);
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));

                    await this.world.addContract(contract);
                    await this.world.changeAccount(accountId, account, true);
                    await this.world.changeAccount(accountId, account, false);
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

function shouldBehaveLikeWorldAccount(account, newAccount, operator) {
    context('World Account', function () {
        describe('getOrCreateAccountId', function () {
            context('create account ', function () {
                it('carete account event ', async function () {
                    expectEvent(await this.world.getOrCreateAccountId(account), 'CreateAccount', {
                        id: new BN(await this.world.getAccountIdByAddress(account)),
                        account: account
                    });
                });
            });
        });
        describe('getAccountIdByAddress', function () {
            context('get account id by address', function () {
                it('equal 101', async function () {
                    await this.world.getOrCreateAccountId(account)
                    const avatarMaxId = new BN(await this.avatar.maxAvatar());
                    expect(await this.world.getAccountIdByAddress(account)).to.bignumber.equal(avatarMaxId.add(new BN(1)));
                });
            });
        });
        describe('getAddressById', function () {
            context('get avatar id', function () {

                it('avatar id is not exist', async function () {
                    await expectRevert(this.world.getAddressById(new BN(1)), 'I08');
                });

                it('avatar id is exist', async function () {
                    await this.world.getOrCreateAccountId(account)
                    await this.avatar.mint(account, new BN(1));
                    expect(await this.world.getAddressById(new BN(1))).to.equal(account);
                });
            });

            context('get account id', function () {
                it('account id is not exist', async function () {
                    const avatarMaxId = new BN(await this.avatar.maxAvatar());
                    expect(await this.world.getAddressById(avatarMaxId.add(new BN(1)))).to.equal(ZERO_ADDRESS);
                });
                it('account id is exist', async function () {
                    await this.world.getOrCreateAccountId(account)
                    const avatarMaxId = new BN(await this.avatar.maxAvatar());
                    expect(await this.world.getAddressById(avatarMaxId.add(new BN(1)))).to.equal(account);
                });
            });
        });

        describe('createAccount', function () {
            context('create account ', function () {
                it('zero address', async function () {
                    await expectRevert(this.world.createAccount(ZERO_ADDRESS, {
                        from: account
                    }), 'World: zero address');

                });
                it('is address exist', async function () {
                    await this.world.createAccount(account)
                    await expectRevert(this.world.createAccount(account), "World: address is exist");
                });
            });
        });

        describe('changeAccount', function () {
            context('ueser change account', function () {
                it('is not contract owner', async function () {
                    await this.world.getOrCreateAccountId(account)
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));

                    await expectRevert(this.world.changeAccount(accountId, newAccount, true, {
                        from: newAccount
                    }), 'only owner');
                });

                it('is owner', async function () {
                    await this.world.getOrCreateAccountId(account)
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));
                    expectEvent(await this.world.changeAccount(accountId, newAccount, true), 'UpdateAccount', {
                        id: accountId,
                        newAddress: newAccount,
                        isTrust: true
                    });
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

function shouldBehaveLikeWorldAvatar(account, newAccount, cashAccount, itemAccount) {
    context('World avatar', function () {
        beforeEach(async function () {
            await this.world.getOrCreateAccountId(account)
            this.accountId = new BN(await this.world.getAccountIdByAddress(account));
            this.avatarTokenId = new BN(10);
            await this.avatar.mint(account, this.avatarTokenId);
        });


        describe('transfer cash', function () {
            context('transfer by avatar token id', function () {
                it('balance equal', async function () {
                    const balance = new BN(1234);
                    await this.cash.mint(cashAccount, balance);
                    const cashAccountId = new BN(await this.world.getAccountIdByAddress(cashAccount));

                    await this.cash.transferCash(cashAccountId, this.avatarTokenId, balance, {
                        from: cashAccount
                    });
                    expect(await this.cash.balanceOfCash(this.avatarTokenId)).to.bignumber.equal(balance);


                    await this.cash.transferCash(this.avatarTokenId, cashAccountId, balance, {
                        from: account
                    });

                    expect(await this.cash.balanceOfCash(this.avatarTokenId)).to.bignumber.equal(new BN(0));
                    expect(await this.cash.balanceOf(cashAccount)).to.bignumber.equal(balance);
                });
            });
        });

        describe('transfer item', function () {
            context('transfer by avatar token id', function () {
                it('owner equal', async function () {
                    const itemTokenId = new BN(100)
                    await this.item.mint(itemAccount, itemTokenId);
                    const itemAccountId = new BN(await this.world.getAccountIdByAddress(itemAccount));
                    await this.item.transferFromItem(itemAccountId, itemAccountId, this.avatarTokenId, itemTokenId, {
                        from: itemAccount
                    });
                    expect(await this.item.ownerOfItem(itemTokenId)).to.bignumber.equal(this.avatarTokenId);
                    await this.item.transferFromItem(this.avatarTokenId, this.avatarTokenId, itemAccountId, itemTokenId, {
                        from: account
                    });
                    expect(await this.item.ownerOfItem(itemTokenId)).to.bignumber.equal(itemAccountId);
                });
            });
        });

        describe('change avatar owner', function () {
            context('change avatar owner', function () {
                it('new owner', async function () {
                    await this.world.changeAccount(this.accountId, newAccount, false);
                    expect(await this.world.getAccountIdByAddress(newAccount)).to.bignumber.equal(this.accountId);
                });
                it('can transfer cash', async function () {
                    const balance = new BN(1234)

                    await this.cash.mint(cashAccount, balance);
                    const cashAccountId = new BN(await this.world.getAccountIdByAddress(cashAccount));

                    await this.cash.transferCash(cashAccountId, this.avatarTokenId, balance, {
                        from: cashAccount
                    });


                    // 修改账户
                    await this.world.changeAccount(this.accountId, newAccount, false);

                    expect(await this.world.getAccountIdByAddress(newAccount)).to.bignumber.equal(this.accountId);
                    expect(await this.cash.balanceOfCash(this.avatarTokenId)).to.bignumber.equal(balance);

                    await this.cash.transferCash(this.avatarTokenId, cashAccountId, balance, {
                        from: newAccount
                    });
                    expect(await this.cash.balanceOfCash(this.avatarTokenId)).to.bignumber.equal(new BN(0));
                    expect(await this.cash.balanceOf(cashAccount)).to.bignumber.equal(balance);

                });

                it('can transfer Item', async function () {
                    const itemTokenId = new BN(100)

                    await this.item.mint(itemAccount, itemTokenId);
                    const itemAccountId = new BN(await this.world.getAccountIdByAddress(itemAccount));
                    await this.item.transferFromItem(itemAccountId, itemAccountId, this.avatarTokenId, itemTokenId, {
                        from: itemAccount
                    });

                    // 修改账户
                    await this.world.changeAccount(this.accountId, newAccount, false);

                    expect(await this.world.getAccountIdByAddress(newAccount)).to.bignumber.equal(this.accountId);

                    expect(await this.item.ownerOfItem(itemTokenId)).to.bignumber.equal(this.avatarTokenId);
                    await this.item.transferFromItem(this.avatarTokenId, this.avatarTokenId, itemAccountId, itemTokenId, {
                        from: newAccount
                    });
                    expect(await this.item.ownerOfItem(itemTokenId)).to.bignumber.equal(itemAccountId);

                });
            });
        });
    });
}


module.exports = {
    shouldBehaveLikeWorld,
    shouldBehaveLikeWorldOperator,
    shouldBehaveLikeWorldTrust,
    shouldBehaveLikeWorldAccount,
    shouldBehaveLikeWorldAsset,
    shouldBehaveLikeWorldAvatar,
};