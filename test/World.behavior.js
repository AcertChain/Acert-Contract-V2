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
                    const avatarMaxId = new BN(await this.avatar.totalSupply());
                    expect(await this.world.getTotalAccount()).to.be.bignumber.equal(avatarMaxId.add(new BN(1)));
                });
            });

            context('getAvatarMaxId', function () {
                it('与avatar 发行量的地址相等', async function () {
                    const avatarMaxId = new BN(await this.avatar.totalSupply());
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
                    }), 'W10');
                });
                it('更新为owner', async function () {
                    expectEvent(await this.world.changeOwner(owner), 'ChangeOwner', {
                        owner: owner
                    });
                    expect(await this.world.getOwner()).to.equal(owner);
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
                it('W01', async function () {
                    await expectRevert(this.world.addOperator(ZERO_ADDRESS), 'W01');
                });
            });

            context('add address', function () {
                it('add operator event', async function () {
                    expectEvent(await this.world.addOperator(operator), 'AddOperator', {
                        _operator: operator
                    });
                });
            });
        });

        describe('removeOperator', function () {
            context('remove address', function () {
                it('remove operator event', async function () {
                    await this.world.addOperator(operator);
                    expectEvent(await this.world.removeOperator(operator), 'RemoveOperator', {
                        _operator: operator
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
                    expect(await this.world.isBWO(await this.world.getOwner())).to.equal(true);
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
                    await expectRevert(this.world.addContract(ZERO_ADDRESS), 'W01');
                });
                it('event AddSafeContract', async function () {
                    expectEvent(await this.world.addContract(contract), 'AddSafeContract', {
                        _contract: contract
                    });
                });
            });
        });

        describe('removeContract', function () {
            context('remove contract address', function () {
                it('event RemoveSafeContract', async function () {
                    await this.world.addContract(contract);
                    expectEvent(await this.world.removeContract(contract), 'RemoveSafeContract', {
                        _contract: contract
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
                    await this.world.changeAccountByUser(accountId, account, true, {
                        from: account
                    });
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
                    await this.world.changeAccountByUser(accountId, account, true, {
                        from: account
                    });
                    expect(await this.world.isTrust(contract, accountId)).to.equal(true);
                });
                it('conrtact is safe contract and user not trust world not trust contract ', async function () {
                    await this.world.getOrCreateAccountId(account);
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));

                    await this.world.addContract(contract);
                    await this.world.changeAccountByUser(accountId, account, true, {
                        from: account
                    });
                    await this.world.changeAccountByUser(accountId, account, false, {
                        from: account
                    });
                    expect(await this.world.isTrust(contract, accountId)).to.equal(false);
                });
                it('conrtact is safe contract and user not trust world  trust contract ', async function () {
                    await this.world.getOrCreateAccountId(account);
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));

                    await this.world.addContract(contract);
                    await this.world.changeAccountByUser(accountId, account, true, {
                        from: account
                    });
                    await this.world.changeAccountByUser(accountId, account, false, {
                        from: account
                    });
                    expectEvent(await this.world.accountTrustContract(accountId, contract, {
                        from: account
                    }), 'TrustContract', {
                        _id: accountId,
                        _contract: contract
                    });
                    expect(await this.world.isTrust(contract, accountId)).to.equal(true);
                    expectEvent(await this.world.accountUntrustContract(accountId, contract, {
                        from: account
                    }), 'UntrustContract', {
                        _id: accountId,
                        _contract: contract
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
                        _id: new BN(await this.world.getAccountIdByAddress(account)),
                        _address: account
                    });
                });
            });
        });
        describe('getAccountIdByAddress', function () {
            context('get account id by address', function () {
                it('equal 101', async function () {
                    await this.world.getOrCreateAccountId(account)
                    const avatarMaxId = new BN(await this.avatar.totalSupply());
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
                    const avatarMaxId = new BN(await this.avatar.totalSupply());
                    expect(await this.world.getAddressById(avatarMaxId.add(new BN(1)))).to.equal(ZERO_ADDRESS);
                });
                it('account id is exist', async function () {
                    await this.world.getOrCreateAccountId(account)
                    const avatarMaxId = new BN(await this.avatar.totalSupply());
                    expect(await this.world.getAddressById(avatarMaxId.add(new BN(1)))).to.equal(account);
                });
            });
        });

        describe('createAccount', function () {
            context('create account ', function () {
                it('zero address', async function () {
                    await expectRevert(this.world.createAccount(ZERO_ADDRESS, {
                        from: account
                    }), 'W05');

                });
                it('is address exist', async function () {
                    await this.world.createAccount(account)
                    await expectRevert(this.world.createAccount(account), "W05");
                });
            });
        });
        describe('changeAccountByOperator', function () {
            context('operator change account', function () {
                it('is not operator', async function () {
                    await this.world.getOrCreateAccountId(account)
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));
                    await expectRevert(this.world.changeAccountByOperator(accountId, newAccount, true, {
                        from: operator
                    }), 'W06');

                });
                it('is operator', async function () {
                    await this.world.getOrCreateAccountId(account)
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));
                    await this.world.addOperator(operator)
                    expectEvent(await this.world.changeAccountByOperator(accountId, newAccount, true, {
                        from: operator
                    }), 'ChangeAccount', {
                        _id: accountId,
                        _executor: operator,
                        _newAddress: newAccount,
                        _isTrust: true
                    });
                });
            });

        });
        describe('changeAccountByUser', function () {
            context('ueser change account', function () {
                it('is not user', async function () {
                    await this.world.getOrCreateAccountId(account)
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));

                    await expectRevert(this.world.changeAccountByUser(accountId, newAccount, true, {
                        from: newAccount
                    }), 'W09');
                });

                it('is user', async function () {
                    await this.world.getOrCreateAccountId(account)
                    const accountId = new BN(await this.world.getAccountIdByAddress(account));
                    expectEvent(await this.world.changeAccountByUser(accountId, newAccount, true, {
                        from: account
                    }), 'ChangeAccount', {
                        _id: accountId,
                        _executor: account,
                        _newAddress: newAccount,
                        _isTrust: true
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
                    await expectRevert(this.world.registerAsset(ZERO_ADDRESS, 0, "", ""), 'W02');
                });
            });

            context('addres is exist', function () {
                it('revert', async function () {
                    await this.world.registerAsset(this.cash.address, 0, "", "")
                    await expectRevert(this.world.registerAsset(this.cash.address, 0, "", ""), 'W02');
                });
            });

            context('RegisterAsset event', function () {
                it('revert', async function () {
                    expectEvent(await this.world.registerAsset(this.cash.address, 0, "test", "test image"), 'RegisterAsset', {
                        _type: new BN(0),
                        _contract: this.cash.address,
                        _name: "test",
                        _image: "test image"
                    });
                });
            });
        });

        describe('changeAsset', function () {
            context('changeAsset', function () {
                it('zero address', async function () {
                    await expectRevert(this.world.changeAsset(ZERO_ADDRESS, 0, "", ""), 'W04');
                });
                it('is not exist', async function () {
                    await expectRevert(this.world.changeAsset(this.cash.address, 0, "", ""), 'W04');
                });
                it('type is not right', async function () {
                    await this.world.registerAsset(this.cash.address, 0, "test", "test image")
                    await expectRevert(this.world.changeAsset(this.cash.address, 1, "test", "test image"), 'W04');
                });
                it('ChangeAsset event', async function () {
                    await this.world.registerAsset(this.cash.address, 0, "test", "test image")
                    expectEvent(await this.world.changeAsset(this.cash.address, 0, "test", "test image"), 'ChangeAsset', {
                        _contract: this.cash.address,
                        _name: "test",
                        _image: "test image"
                    });
                });
            });
        });
        describe('getAsset', function () {
            context('get asset ', function () {
                it('get asset', async function () {
                    await this.world.registerAsset(this.cash.address, 0, "test", "test image")
                    expect(await this.world.getAsset(this.cash.address)).to.deep.equal(['0', true, this.cash.address, "test", "test image"]);
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
                    expect(await this.cash.balanceOfId(this.avatarTokenId)).to.bignumber.equal(balance);


                    await this.cash.transferCash(this.avatarTokenId, cashAccountId, balance, {
                        from: account
                    });

                    expect(await this.cash.balanceOfId(this.avatarTokenId)).to.bignumber.equal(new BN(0));
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
                    expect(await this.item.ownerOfId(itemTokenId)).to.bignumber.equal(this.avatarTokenId);
                    await this.item.transferFromItem(this.avatarTokenId, this.avatarTokenId, itemAccountId, itemTokenId, {
                        from: account
                    });
                    expect(await this.item.ownerOfId(itemTokenId)).to.bignumber.equal(itemAccountId);
                });
            });
        });

        describe('change avatar owner', function () {
            context('change avatar owner', function () {
                it('new owner', async function () {
                    await this.world.changeAccountByUser(this.accountId, newAccount, false, {
                        from: account
                    });
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
                    await this.world.changeAccountByUser(this.accountId, newAccount, false, {
                        from: account
                    });
                    // 通知asset
                    await this.world.changeAssetAccountAddressByUser([this.cash.address], {
                        from: newAccount
                    })

                    expect(await this.world.getAccountIdByAddress(newAccount)).to.bignumber.equal(this.accountId);
                    expect(await this.cash.balanceOfId(this.avatarTokenId)).to.bignumber.equal(balance);

                    await this.cash.transferCash(this.avatarTokenId, cashAccountId, balance, {
                        from: newAccount
                    });
                    expect(await this.cash.balanceOfId(this.avatarTokenId)).to.bignumber.equal(new BN(0));
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
                    await this.world.changeAccountByUser(this.accountId, newAccount, false, {
                        from: account
                    });
                    // 通知asset
                    await this.world.changeAssetAccountAddressByUser([this.item.address], {
                        from: newAccount
                    })


                    expect(await this.world.getAccountIdByAddress(newAccount)).to.bignumber.equal(this.accountId);

                    expect(await this.item.ownerOfId(itemTokenId)).to.bignumber.equal(this.avatarTokenId);
                    await this.item.transferFromItem(this.avatarTokenId,this.avatarTokenId, itemAccountId, itemTokenId, {
                        from: newAccount
                    });
                    expect(await this.item.ownerOfId(itemTokenId)).to.bignumber.equal(itemAccountId);

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