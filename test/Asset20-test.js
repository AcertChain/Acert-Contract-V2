const {
  BN,
  constants,
  expectEvent,
  expectRevert
} = require('@openzeppelin/test-helpers');
const {
  expect
} = require("chai");
const {
  artifacts,
  ethers
} = require("hardhat");
const {
  ZERO_ADDRESS
} = constants;
const Wallet = require('ethereumjs-wallet').default;


const Asset20 = artifacts.require('MogaToken');
const Asset20Storage = artifacts.require('Asset20Storage');
const World = artifacts.require('MonsterGalaxy');
const WorldStorage = artifacts.require('WorldStorage');
const Metaverse = artifacts.require('MogaMetaverse');
const MetaverseStorage = artifacts.require('MetaverseStorage');

const {
  shouldBehaveLikeERC20,
  shouldBehaveLikeERC20Transfer,
  shouldBehaveLikeERC20Approve,
} = require('./ERC20.behavior');

const {
  shouldBehaveLikeAsset20,
  shouldBehaveLikeAsset20Transfer,
  shouldBehaveLikeAsset20Approve,
} = require('./Asset20.behavior');

const {
  shouldBehaveLikeAsset20BWO,
} = require('./Asset20BWO.behavior');

const {
  shouldBehaveLikeAsset20ProxyBWO,
} = require('./Asset20BWO.proxy');

contract('Asset20', function (accounts) {
  // deploy World contract
  beforeEach(async function () { });

  const [initialHolder, recipient, anotherAccount, authAccount] = accounts;


  const initialHolderId = new BN(1);
  const recipientId = new BN(2);
  const anotherAccountId = new BN(3);
  const BWOfromId = new BN(4);
  const BWOToId = new BN(5);

  const name = 'My Token';
  const symbol = 'MTKN';
  const version = '1.0.0';
  const initialSupply = new BN(100);


  const wallet = Wallet.generate();
  const BWOInitialHolder = wallet.getAddressString();
  const BWOkey = wallet.getPrivateKey();

  const receiptWallet = Wallet.generate();
  const BWOReceipt = receiptWallet.getAddressString();
  const BWOReceiptkey = receiptWallet.getPrivateKey();

  beforeEach(async function () {
    this.MetaverseStorage = await MetaverseStorage.new();
    this.Metaverse = await Metaverse.new("metaverse", "1.0", 0, this.MetaverseStorage.address);
    await this.MetaverseStorage.updateMetaverse(this.Metaverse.address);

    this.WorldStorage = await WorldStorage.new();
    this.world = await World.new(this.Metaverse.address, this.WorldStorage.address, "world", "1.0");
    await this.WorldStorage.updateWorld(this.world.address);

    this.tokenStorage = await Asset20Storage.new();
    this.token = await Asset20.new(name, symbol, version, this.world.address, this.tokenStorage.address);
    await this.tokenStorage.updateAsset(this.token.address);

    // register world
    await this.Metaverse.registerWorld(this.world.address, "");

    // register token
    await this.world.registerAsset(this.token.address);

    this.receipt = await this.token.methods['mint(address,uint256)'](initialHolder, initialSupply);
    this.tokenName = name;
    this.tokenVersion = version;
    this.BWO = initialHolder;
    this.chainId = await this.token.getChainId();

    // 注册operater
    await this.Metaverse.addOperator(initialHolder);
    await this.Metaverse.getOrCreateAccountId(initialHolder);
    await this.Metaverse.getOrCreateAccountId(recipient);
    await this.Metaverse.getOrCreateAccountId(anotherAccount);

    await this.token.mint(BWOInitialHolder, initialSupply);
    await this.Metaverse.getOrCreateAccountId(BWOInitialHolder);
    await this.Metaverse.getOrCreateAccountId(BWOReceipt);
  });



  it('has a name', async function () {
    expect(await this.token.name()).to.equal(name);
  });

  it('has a symbol', async function () {
    expect(await this.token.symbol()).to.equal(symbol);
  });

  it('has 18 decimals', async function () {
    expect(await this.token.decimals()).to.be.bignumber.equal('18');
  });

  it('has a world', async function () {
    expect(await this.token.worldAddress()).equal(this.world.address);
  });

  it('has a total supply', async function () {
    expect(await this.token.totalSupply()).to.be.bignumber.equal(initialSupply.mul(new BN(2)));
  });

  it(`checkout account id`, async function () {
    expect(await this.Metaverse.getAccountIdByAddress(initialHolder)).to.be.bignumber.equal(initialHolderId);
    expect(await this.Metaverse.getAccountIdByAddress(recipient)).to.be.bignumber.equal(recipientId);
    expect(await this.Metaverse.getAccountIdByAddress(anotherAccount)).to.be.bignumber.equal(anotherAccountId);
    expect(await this.Metaverse.getAccountIdByAddress(BWOInitialHolder)).to.be.bignumber.equal(BWOfromId);
    expect(await this.Metaverse.getAccountIdByAddress(BWOReceipt)).to.be.bignumber.equal(BWOToId);
  });


  shouldBehaveLikeERC20('Asset20', initialSupply, initialHolder, recipient, anotherAccount);

  shouldBehaveLikeAsset20('Asset20', initialSupply, initialHolder, initialHolderId, recipient, recipientId, anotherAccount, anotherAccountId);

  shouldBehaveLikeAsset20BWO('Asset20', initialSupply, BWOInitialHolder, BWOfromId, BWOReceipt, BWOToId, anotherAccount, anotherAccountId, BWOkey, BWOReceiptkey);


  shouldBehaveLikeAsset20ProxyBWO('Asset20', initialSupply, initialHolder, initialHolderId, BWOReceipt, BWOToId, authAccount, BWOkey, BWOReceiptkey);

  describe('decrease allowance', function () {
    describe('when the spender is not the zero address', function () {
      const spender = recipient;

      function shouldDecreaseApproval(amount) {
        describe('when there was no approved amount before', function () {
          it('reverts', async function () {
            await expectRevert(this.token.decreaseAllowance(
              spender, amount, {
              from: initialHolder
            }), 'Asset20: decreased allowance below zero');
          });
        });

        describe('when the spender had an approved amount', function () {
          const approvedAmount = amount;

          beforeEach(async function () {
            await this.token.methods['approve(address,uint256)'](spender, approvedAmount, {
              from: initialHolder
            });
          });

          it('emits an approval event', async function () {
            expectEvent(
              await this.token.decreaseAllowance(spender, approvedAmount, {
                from: initialHolder
              }),
              'Approval', {
              owner: initialHolder,
              spender: spender,
              value: new BN(0)
            },
            );
          });

          it('decreases the spender allowance subtracting the requested amount', async function () {
            await this.token.decreaseAllowance(spender, approvedAmount.subn(1), {
              from: initialHolder
            });

            expect(await this.token.methods['allowance(address,address)'](initialHolder, spender)).to.be.bignumber.equal('1');
          });

          it('sets the allowance to zero when all allowance is removed', async function () {
            await this.token.decreaseAllowance(spender, approvedAmount, {
              from: initialHolder
            });
            expect(await this.token.methods['allowance(address,address)'](initialHolder, spender)).to.be.bignumber.equal('0');
          });

          it('reverts when more than the full allowance is removed', async function () {
            await expectRevert(
              this.token.decreaseAllowance(spender, approvedAmount.addn(1), {
                from: initialHolder
              }),
              'Asset20: decreased allowance below zero',
            );
          });
        });
      }

      describe('when the sender has enough balance', function () {
        const amount = initialSupply;

        shouldDecreaseApproval(amount);
      });

      describe('when the sender does not have enough balance', function () {
        const amount = initialSupply.addn(1);

        shouldDecreaseApproval(amount);
      });
    });

    describe('when the spender is the zero address', function () {
      const amount = initialSupply;
      const spender = ZERO_ADDRESS;

      it('reverts', async function () {
        await expectRevert(this.token.decreaseAllowance(
          spender, amount, {
          from: initialHolder
        }), 'Asset20: decreased allowance below zero');
      });
    });
  });

  describe('increase allowance', function () {
    const amount = initialSupply;

    describe('when the spender is not the zero address', function () {
      const spender = recipient;

      describe('when the sender has enough balance', function () {
        it('emits an approval event', async function () {
          expectEvent(
            await this.token.increaseAllowance(spender, amount, {
              from: initialHolder
            }),
            'Approval', {
            owner: initialHolder,
            spender: spender,
            value: amount
          },
          );
        });

        describe('when there was no approved amount before', function () {
          it('approves the requested amount', async function () {
            await this.token.increaseAllowance(spender, amount, {
              from: initialHolder
            });

            expect(await this.token.methods['allowance(address,address)'](initialHolder, spender)).to.be.bignumber.equal(amount);
          });
        });

        describe('when the spender had an approved amount', function () {
          beforeEach(async function () {
            await this.token.methods['approve(address,uint256)'](spender, new BN(1), {
              from: initialHolder
            });
          });

          it('increases the spender allowance adding the requested amount', async function () {
            await this.token.increaseAllowance(spender, amount, {
              from: initialHolder
            });

            expect(await this.token.methods['allowance(address,address)'](initialHolder, spender)).to.be.bignumber.equal(amount.addn(1));
          });
        });
      });

      describe('when the sender does not have enough balance', function () {
        const amount = initialSupply.addn(1);

        it('emits an approval event', async function () {
          expectEvent(
            await this.token.increaseAllowance(spender, amount, {
              from: initialHolder
            }),
            'Approval', {
            owner: initialHolder,
            spender: spender,
            value: amount
          },
          );
        });

        describe('when there was no approved amount before', function () {
          it('approves the requested amount', async function () {
            await this.token.increaseAllowance(spender, amount, {
              from: initialHolder
            });

            expect(await this.token.methods['allowance(address,address)'](initialHolder, spender)).to.be.bignumber.equal(amount);
          });
        });

        describe('when the spender had an approved amount', function () {
          beforeEach(async function () {
            await this.token.methods['approve(address,uint256)'](spender, new BN(1), {
              from: initialHolder
            });
          });

          it('increases the spender allowance adding the requested amount', async function () {
            await this.token.increaseAllowance(spender, amount, {
              from: initialHolder
            });

            expect(await this.token.methods['allowance(address,address)'](initialHolder, spender)).to.be.bignumber.equal(amount.addn(1));
          });
        });
      });
    });

    describe('when the spender is the zero address', function () {
      const spender = ZERO_ADDRESS;

      it('reverts', async function () {
        await expectRevert(
          this.token.increaseAllowance(spender, amount, {
            from: initialHolder
          }), 'Asset20: approve to the zero address',
        );
      });
    });
  });

  describe('_mint', function () {
    const amount = new BN(50);
    it('rejects a null account', async function () {
      await expectRevert(
        this.token.methods['mint(address,uint256)'](ZERO_ADDRESS, amount), 'Asset20: mint to the zero address',
      );
    });

    describe('for a non zero account', function () {
      beforeEach('minting', async function () {
        this.receipt = await this.token.methods['mint(address,uint256)'](recipient, amount);
      });

      it('increments totalSupply', async function () {
        tSupply = initialSupply.mul(new BN(2))
        const expectedSupply = tSupply.add(amount);
        expect(await this.token.totalSupply()).to.be.bignumber.equal(expectedSupply);
      });

      it('increments recipient balance', async function () {
        expect(await this.token.methods['balanceOf(address)'](recipient)).to.be.bignumber.equal(amount);
      });

      it('emits Transfer event', async function () {
        const event = expectEvent(
          this.receipt,
          'Transfer', {
          from: ZERO_ADDRESS,
          to: recipient
        },
        );

        expect(event.args.value).to.be.bignumber.equal(amount);
      });
    });
  });

  describe('_burn', function () {
    it('rejects a null account', async function () {
      await expectRevert(this.token.methods['burn(address,uint256)'](ZERO_ADDRESS, new BN(1)),
        'Asset20: burn from the zero address');
    });

    describe('for a non zero account', function () {
      it('rejects burning more than balance', async function () {
        await expectRevert(this.token.methods['burn(address,uint256)'](
          initialHolder, initialSupply.addn(1)), 'Asset20: burn amount exceeds balance');
      });

      const describeBurn = function (description, amount) {
        describe(description, function () {
          beforeEach('burning', async function () {
            this.receipt = await this.token.methods['burn(address,uint256)'](initialHolder, amount);
          });

          it('decrements totalSupply', async function () {
            tSupply = initialSupply.mul(new BN(2))
            const expectedSupply = tSupply.sub(amount);
            expect(await this.token.totalSupply()).to.be.bignumber.equal(expectedSupply);
          });

          it('decrements initialHolder balance', async function () {
            const expectedBalance = initialSupply.sub(amount);
            expect(await this.token.methods['balanceOf(address)'](initialHolder)).to.be.bignumber.equal(expectedBalance);
          });

          it('emits Transfer event', async function () {
            const event = expectEvent(
              this.receipt,
              'Transfer', {
              from: initialHolder,
              to: ZERO_ADDRESS
            },
            );

            expect(event.args.value).to.be.bignumber.equal(amount);
          });
        });
      };

      describeBurn('for entire balance', initialSupply);
      describeBurn('for less amount than balance', initialSupply.subn(1));
    });
  });

  describe('_mintCash', function () {
    const amount = new BN(50);
    it('rejects a null account', async function () {
      await expectRevert(
        this.token.methods['mint(uint256,uint256)'](0, amount), 'Asset20: mint to the zero Id',
      );
    });

    describe('for a non zero account', function () {
      beforeEach('minting', async function () {
        this.receipt = await this.token.methods['mint(uint256,uint256)'](recipientId, amount);
      });

      it('increments totalSupply', async function () {
        tSupply = initialSupply.mul(new BN(2))
        const expectedSupply = tSupply.add(amount);
        expect(await this.token.totalSupply()).to.be.bignumber.equal(expectedSupply);
      });

      it('increments recipient balance', async function () {
        expect(await this.token.methods['balanceOf(address)'](recipient)).to.be.bignumber.equal(amount);
      });

      it('emits Transfer event', async function () {
        const event = expectEvent(
          this.receipt,
          'AssetTransfer', {
          from: new BN(0),
          to: recipientId
        },
        );

        expect(event.args.value).to.be.bignumber.equal(amount);
      });
    });
  });

  describe('_burn', function () {
    it('rejects a null account', async function () {
      await expectRevert(this.token.methods['burn(uint256,uint256)'](0, new BN(1)),
        'Asset20: burn from the zero Id');
    });

    describe('for a non zero account', function () {
      it('rejects burning more than balance', async function () {
        await expectRevert(this.token.methods['burn(uint256,uint256)'](
          initialHolderId, initialSupply.addn(1)), 'Asset20: burn amount exceeds balance');
      });

      const describeBurn = function (description, amount) {
        describe(description, function () {
          beforeEach('burning', async function () {
            this.receipt = await this.token.methods['burn(uint256,uint256)'](initialHolderId, amount);
          });

          it('decrements totalSupply', async function () {
            tSupply = initialSupply.mul(new BN(2))
            const expectedSupply = tSupply.sub(amount);
            expect(await this.token.totalSupply()).to.be.bignumber.equal(expectedSupply);
          });

          it('decrements initialHolder balance', async function () {
            const expectedBalance = initialSupply.sub(amount);
            expect(await this.token.methods['balanceOf(address)'](initialHolder)).to.be.bignumber.equal(expectedBalance);
          });

          it('emits Transfer event', async function () {
            const event = expectEvent(
              this.receipt,
              'AssetTransfer', {
              from: initialHolderId,
              to: new BN(0)
            },
            );

            expect(event.args.value).to.be.bignumber.equal(amount);
          });
        });
      };

      describeBurn('for entire balance', initialSupply);
      describeBurn('for less amount than balance', initialSupply.subn(1));
    });
  });

  describe('_transfer', function () {
    shouldBehaveLikeERC20Transfer('Asset20', initialHolder, recipient, initialSupply, function (from, to, amount) {
      return this.token.transfer(to, amount, {
        from
      });
    });

  });

  describe('_transferAsset', function () {
    shouldBehaveLikeAsset20Transfer('Asset20', initialHolder, initialHolderId, recipientId, initialSupply, function (from, fromId, toId, amount) {
      return this.token.methods['transferFrom(uint256,uint256,uint256)'](fromId, toId, amount, {
        from
      });
    });

  });

  describe('_approve', function () {
    shouldBehaveLikeERC20Approve('Asset20', initialHolder, recipient, initialSupply, function (owner, spender, amount) {
      return this.token.methods['approve(address,uint256)'](spender, amount, {
        from: owner
      });
    });
  });

  describe('_approveAsset', function () {
    shouldBehaveLikeAsset20Approve('Asset20', initialHolder, initialHolderId, recipient, recipientId, initialSupply, function (owner, ownerId, spender, amount) {
      return this.token.methods['approve(uint256,address,uint256)'](ownerId, spender, amount, {
        from: owner
      });
    });
  });

});