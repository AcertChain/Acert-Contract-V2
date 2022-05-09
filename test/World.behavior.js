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
                    expectRevert(this.world.changeOwner(owner, {
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

function shouldBehaveLikeWorldTrust(contract) {
    // context('World', function () {
    //     beforeEach(async function () {

    //     }); 
    //     describe('constructor', function () {
    //         context('', function () {
    //             it('', async function () {});
    //         });
    //     });
    // });
}

function shouldBehaveLikeWorldAccount() {
}

function shouldBehaveLikeWorldAsset() {}

function shouldBehaveLikeWorldAvatar() {}


module.exports = {
    shouldBehaveLikeWorld,
    shouldBehaveLikeWorldOperator,
    shouldBehaveLikeWorldTrust,
    shouldBehaveLikeWorldAccount,
    shouldBehaveLikeWorldAsset,
    shouldBehaveLikeWorldAvatar,
};