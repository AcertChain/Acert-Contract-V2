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


const Cash20 = artifacts.require('Cash20Mock');
const World = artifacts.require('World');

const {
  shouldBehaveLikeERC20,
  shouldBehaveLikeERC20Transfer,
  shouldBehaveLikeERC20Approve,
} = require('./ERC20.behavior');

const {
  shouldBehaveLikeCash20,
  shouldBehaveLikeCash20Transfer,
  shouldBehaveLikeCash20Approve,
} = require('./Cash20.behavior');

const {
  shouldBehaveLikeCash20BWO,
  shouldBehaveLikeCash20TransferBWO,
  shouldBehaveLikeCash20ApproveBWO,
} = require('./Cash20BWO.behavior');

contract('Cash20', function (accounts) {
  // deploy World contract
  beforeEach(async function () {});

  const [initialHolder, recipient, anotherAccount] = accounts;

  const initialHolderId = new BN(1);
  const recipientId = new BN(2);
  const anotherAccountId = new BN(3);
  const BWOfromId = new BN(4);

  const name = 'My Token';
  const symbol = 'MTKN';
  const version = '1.0.0';
  const initialSupply = new BN(100);


  beforeEach(async function () {
    this.world = await World.new();
    this.token = await Cash20.new(name, symbol, version, this.world.address);
    this.receipt = await this.token.mint(initialHolder, initialSupply);
    this.tokenName = name;
    this.tokenVersion = version;
    this.wallet = Wallet.generate();
    this.BWO = initialHolder;

    // 注册operater
    await this.world.addOperator(initialHolder);

    this.BWOInitialHolder = this.wallet.getAddressString();
    await this.token.mint(this.BWOInitialHolder, initialSupply);
    
    await this.world.getOrCreateAccountId(initialHolder);
    await this.world.getOrCreateAccountId(recipient);
    await this.world.getOrCreateAccountId(anotherAccount);
    await this.world.getOrCreateAccountId(this.BWOInitialHolder);
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
    expect(await this.token.totalSupply()).to.be.bignumber.equal(initialSupply);
  });

  it(`checkout account id`, async function () {
    expect(await this.world.getAccountIdByAddress(initialHolder)).to.be.bignumber.equal(initialHolderId);
    expect(await this.world.getAccountIdByAddress(recipient)).to.be.bignumber.equal(recipientId);
    expect(await this.world.getAccountIdByAddress(anotherAccount)).to.be.bignumber.equal(anotherAccountId);
  });

  shouldBehaveLikeERC20('Cash', initialSupply, initialHolder, recipient, anotherAccount);

  shouldBehaveLikeCash20('Cash', initialSupply, initialHolder, initialHolderId, recipient, recipientId, anotherAccount, anotherAccountId);
  
  shouldBehaveLikeCash20BWO('Cash', initialSupply, this.BWOfrom, BWOfromId, recipient, recipientId, anotherAccount, anotherAccountId);

  describe('decrease allowance', function () {
    describe('when the spender is not the zero address', function () {
      const spender = recipient;

      function shouldDecreaseApproval(amount) {
        describe('when there was no approved amount before', function () {
          it('reverts', async function () {
            await expectRevert(this.token.decreaseAllowance(
              spender, amount, {
                from: initialHolder
              }), 'Cash: decreased allowance below zero', );
          });
        });

        describe('when the spender had an approved amount', function () {
          const approvedAmount = amount;

          beforeEach(async function () {
            await this.token.approve(spender, approvedAmount, {
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

            expect(await this.token.allowance(initialHolder, spender)).to.be.bignumber.equal('1');
          });

          it('sets the allowance to zero when all allowance is removed', async function () {
            await this.token.decreaseAllowance(spender, approvedAmount, {
              from: initialHolder
            });
            expect(await this.token.allowance(initialHolder, spender)).to.be.bignumber.equal('0');
          });

          it('reverts when more than the full allowance is removed', async function () {
            await expectRevert(
              this.token.decreaseAllowance(spender, approvedAmount.addn(1), {
                from: initialHolder
              }),
              'Cash: decreased allowance below zero',
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
          }), 'Cash: decreased allowance below zero', );
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

            expect(await this.token.allowance(initialHolder, spender)).to.be.bignumber.equal(amount);
          });
        });

        describe('when the spender had an approved amount', function () {
          beforeEach(async function () {
            await this.token.approve(spender, new BN(1), {
              from: initialHolder
            });
          });

          it('increases the spender allowance adding the requested amount', async function () {
            await this.token.increaseAllowance(spender, amount, {
              from: initialHolder
            });

            expect(await this.token.allowance(initialHolder, spender)).to.be.bignumber.equal(amount.addn(1));
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

            expect(await this.token.allowance(initialHolder, spender)).to.be.bignumber.equal(amount);
          });
        });

        describe('when the spender had an approved amount', function () {
          beforeEach(async function () {
            await this.token.approve(spender, new BN(1), {
              from: initialHolder
            });
          });

          it('increases the spender allowance adding the requested amount', async function () {
            await this.token.increaseAllowance(spender, amount, {
              from: initialHolder
            });

            expect(await this.token.allowance(initialHolder, spender)).to.be.bignumber.equal(amount.addn(1));
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
          }), 'Cash: approve to the zero address',
        );
      });
    });
  });

  describe('_mint', function () {
    const amount = new BN(50);
    it('rejects a null account', async function () {
      await expectRevert(
        this.token.mint(ZERO_ADDRESS, amount), 'Cash: mint to the zero address',
      );
    });

    describe('for a non zero account', function () {
      beforeEach('minting', async function () {
        this.receipt = await this.token.mint(recipient, amount);
      });

      it('increments totalSupply', async function () {
        const expectedSupply = initialSupply.add(amount);
        expect(await this.token.totalSupply()).to.be.bignumber.equal(expectedSupply);
      });

      it('increments recipient balance', async function () {
        expect(await this.token.balanceOf(recipient)).to.be.bignumber.equal(amount);
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
      await expectRevert(this.token.burn(ZERO_ADDRESS, new BN(1)),
        'Cash: burn from the zero address');
    });

    describe('for a non zero account', function () {
      it('rejects burning more than balance', async function () {
        await expectRevert(this.token.burn(
          initialHolder, initialSupply.addn(1)), 'Cash: burn amount exceeds balance', );
      });

      const describeBurn = function (description, amount) {
        describe(description, function () {
          beforeEach('burning', async function () {
            this.receipt = await this.token.burn(initialHolder, amount);
          });

          it('decrements totalSupply', async function () {
            const expectedSupply = initialSupply.sub(amount);
            expect(await this.token.totalSupply()).to.be.bignumber.equal(expectedSupply);
          });

          it('decrements initialHolder balance', async function () {
            const expectedBalance = initialSupply.sub(amount);
            expect(await this.token.balanceOf(initialHolder)).to.be.bignumber.equal(expectedBalance);
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

  describe('_transfer', function () {
    shouldBehaveLikeERC20Transfer('Cash', initialHolder, recipient, initialSupply, function (from, to, amount) {
      return this.token.transfer(to, amount, {
        from
      });
    });

  });

  describe('_transferCash', function () {
    shouldBehaveLikeCash20Transfer('Cash', initialHolder, initialHolderId,  recipientId, initialSupply, function (from, fromId, toId, amount) {
      return this.token.transferCash(fromId, toId, amount, {
        from
      });
    });

  });

  describe('_approve', function () {
    shouldBehaveLikeERC20Approve('Cash', initialHolder, recipient, initialSupply, function (owner, spender, amount) {
      return this.token.approve(spender, amount, {
        from: owner
      });
    });
  });

  describe('_approveId', function () {
    shouldBehaveLikeCash20Approve('Cash', initialHolder, initialHolderId, recipientId, initialSupply, function (owner, ownerId, spender, amount) {
      return this.token.approveId(ownerId, spender, amount, {
        from: owner
      });
    });
  });

});