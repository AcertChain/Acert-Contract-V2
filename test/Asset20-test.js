const {
  BN,
  constants,
  expectEvent,
  expectRevert,
} = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { artifacts, ethers } = require('hardhat');
const { ZERO_ADDRESS } = constants;
const Wallet = require('ethereumjs-wallet').default;

const Acert = artifacts.require('Acert');

const Metaverse = artifacts.require('Metaverse');
const MetaverseCore = artifacts.require('MetaverseCore');
const MetaverseStorage = artifacts.require('MetaverseStorage');

const World = artifacts.require('World');
const WorldCore = artifacts.require('WorldCore');
const WorldStorage = artifacts.require('WorldStorage');

const Asset20 = artifacts.require('Asset20');
const Asset20Core = artifacts.require('Asset20Core');
const Asset20Storage = artifacts.require('Asset20Storage');

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

const { shouldBehaveLikeAsset20BWO } = require('./Asset20BWO.behavior');

const { shouldBehaveLikeAsset20ProxyBWO } = require('./Asset20BWO.proxy');

contract('Asset20', function (accounts) {
  const [initialHolder, recipient, anotherAccount, authAccount] = accounts;

  const remark = 'remark';

  const initialHolderId = new BN(1);
  const recipientId = new BN(2);
  const anotherAccountId = new BN(3);
  const BWOfromId = new BN(4);
  const BWOToId = new BN(5);

  const name = 'My Token';
  const symbol = 'MTKN';
  const version = '1.0';
  const initialSupply = new BN(100);

  const wallet = Wallet.generate();
  const BWOInitialHolder = wallet.getAddressString();
  const BWOkey = wallet.getPrivateKey();

  const receiptWallet = Wallet.generate();
  const BWOReceipt = receiptWallet.getAddressString();
  const BWOReceiptkey = receiptWallet.getPrivateKey();

  beforeEach(async function () {
    // deploy acert
    this.Acert = await Acert.new();

    // deploy metaverse
    this.Metaverse = await Metaverse.new();
    this.MetaverseStorage = await MetaverseStorage.new();
    this.MetaverseCore = await MetaverseCore.new(
      'metaverse',
      version,
      0,
      this.MetaverseStorage.address,
    );
    await this.MetaverseStorage.updateMetaverse(this.MetaverseCore.address);
    await this.MetaverseCore.updateShell(this.Metaverse.address);
    await this.Metaverse.updateCore(this.MetaverseCore.address);

    await this.Acert.setMetaverse(this.Metaverse.address, true);
    await this.Acert.remark(this.Metaverse.address, remark, '');
    await this.Acert.remark(this.MetaverseCore.address, remark, '');
    await this.Acert.remark(this.MetaverseStorage.address, remark, '');

    // deploy world
    this.WorldStorage = await WorldStorage.new();
    this.WorldCore = await WorldCore.new(
      'wold',
      version,
      this.Metaverse.address,
      this.WorldStorage.address,
    );
    this.World = await World.new();

    await this.WorldStorage.updateWorld(this.WorldCore.address);
    await this.WorldCore.updateShell(this.World.address);
    await this.World.updateCore(this.WorldCore.address);

    await this.Acert.remark(this.World.address, remark, '');
    await this.Acert.remark(this.WorldCore.address, remark, '');
    await this.Acert.remark(this.WorldStorage.address, remark, '');

    // deploy token
    this.tokenStorage = await Asset20Storage.new();
    this.tokenCore = await Asset20Core.new(
      name,
      symbol,
      version,
      this.World.address,
      this.tokenStorage.address,
    );
    this.token = await Asset20.new();

    await this.tokenStorage.updateAsset(this.tokenCore.address);
    await this.tokenCore.updateShell(this.token.address);
    await this.token.updateCore(this.tokenCore.address);

    await this.token.updateMiner(await this.token.owner(), true);

    await this.Acert.remark(this.token.address, remark, '');
    await this.Acert.remark(this.tokenCore.address, remark, '');
    await this.Acert.remark(this.tokenStorage.address, remark, '');

    // register world
    await this.MetaverseCore.registerWorld(this.World.address);

    // register token
    await this.WorldCore.registerAsset(this.token.address);

    await this.Metaverse.createAccount(initialHolder, false);

    // mint token
    this.receipt = await this.token.mint(initialHolderId, initialSupply);
    this.tokenName = name;
    this.tokenVersion = version;
    this.BWO = initialHolder;
    this.chainId = await this.token.getChainId();

    // 注册operater
    await this.WorldCore.addOperator(initialHolder);
    await this.MetaverseCore.addOperator(initialHolder);
    await this.Metaverse.createAccount(recipient, false);
    await this.Metaverse.createAccount(anotherAccount, false);
    await this.Metaverse.createAccount(BWOInitialHolder, false);

    const BWOInitialHolderId = await this.Metaverse.getAccountIdByAddress(
      BWOInitialHolder,
    );

    await this.token.mint(BWOInitialHolderId, initialSupply);
    await this.Metaverse.createAccount(BWOReceipt, false);
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
    expect(await this.token.worldAddress()).equal(this.World.address);
  });

  it('has a total supply', async function () {
    expect(await this.token.totalSupply()).to.be.bignumber.equal(
      initialSupply.mul(new BN(2)),
    );
  });

  it(`checkout account id`, async function () {
    expect(
      await this.Metaverse.getAccountIdByAddress(initialHolder),
    ).to.be.bignumber.equal(initialHolderId);
    expect(
      await this.Metaverse.getAccountIdByAddress(recipient),
    ).to.be.bignumber.equal(recipientId);
    expect(
      await this.Metaverse.getAccountIdByAddress(anotherAccount),
    ).to.be.bignumber.equal(anotherAccountId);
    expect(
      await this.Metaverse.getAccountIdByAddress(BWOInitialHolder),
    ).to.be.bignumber.equal(BWOfromId);
    expect(
      await this.Metaverse.getAccountIdByAddress(BWOReceipt),
    ).to.be.bignumber.equal(BWOToId);
  });

  shouldBehaveLikeERC20(
    'Asset20',
    initialSupply,
    initialHolder,
    recipient,
    anotherAccount,
  );

  shouldBehaveLikeAsset20(
    'Asset20',
    initialSupply,
    initialHolder,
    initialHolderId,
    recipient,
    recipientId,
    anotherAccount,
    anotherAccountId,
  );

  shouldBehaveLikeAsset20BWO(
    'Asset20',
    initialSupply,
    BWOInitialHolder,
    BWOfromId,
    BWOReceipt,
    BWOToId,
    anotherAccount,
    anotherAccountId,
    BWOkey,
    BWOReceiptkey,
  );

  shouldBehaveLikeAsset20ProxyBWO(
    'Asset20',
    initialSupply,
    initialHolder,
    initialHolderId,
    BWOReceipt,
    BWOToId,
    authAccount,
    BWOkey,
    BWOReceiptkey,
  );

  describe('_mintCash', function () {
    const amount = new BN(50);
    it('rejects a null account', async function () {
      await expectRevert(
        this.token.mint(0, amount),
        'Asset20: mint to the zero Id',
      );
    });

    describe('for a non zero account', function () {
      beforeEach('minting', async function () {
        this.receipt = await this.token.mint(recipientId, amount);
      });

      it('increments totalSupply', async function () {
        tSupply = initialSupply.mul(new BN(2));
        const expectedSupply = tSupply.add(amount);
        expect(await this.token.totalSupply()).to.be.bignumber.equal(
          expectedSupply,
        );
      });

      it('increments recipient balance', async function () {
        expect(
          await this.token.methods['balanceOf(address)'](recipient),
        ).to.be.bignumber.equal(amount);
      });

      it('emits Transfer event', async function () {
        const event = expectEvent(this.receipt, 'AssetTransfer', {
          from: new BN(0),
          to: recipientId,
        });

        expect(event.args.value).to.be.bignumber.equal(amount);
      });
    });
  });

  describe('_burn', function () {
    it('rejects a null account', async function () {
      await expectRevert(
        this.token.burn(0, new BN(1)),
        'Asset20: burn from the zero Id',
      );
    });

    describe('for a non zero account', function () {
      it('rejects burning more than balance', async function () {
        await expectRevert(
          this.token.burn(initialHolderId, initialSupply.addn(1)),
          'Asset20: burn amount exceeds balance',
        );
      });

      const describeBurn = function (description, amount) {
        describe(description, function () {
          beforeEach('burning', async function () {
            this.receipt = await this.token.burn(initialHolderId, amount);
          });

          it('decrements totalSupply', async function () {
            tSupply = initialSupply.mul(new BN(2));
            const expectedSupply = tSupply.sub(amount);
            expect(await this.token.totalSupply()).to.be.bignumber.equal(
              expectedSupply,
            );
          });

          it('decrements initialHolder balance', async function () {
            const expectedBalance = initialSupply.sub(amount);
            expect(
              await this.token.methods['balanceOf(address)'](initialHolder),
            ).to.be.bignumber.equal(expectedBalance);
          });

          it('emits Transfer event', async function () {
            const event = expectEvent(this.receipt, 'AssetTransfer', {
              from: initialHolderId,
              to: new BN(0),
            });

            expect(event.args.value).to.be.bignumber.equal(amount);
          });
        });
      };

      describeBurn('for entire balance', initialSupply);
      describeBurn('for less amount than balance', initialSupply.subn(1));
    });
  });

  describe('_transfer', function () {
    shouldBehaveLikeERC20Transfer(
      'Asset20',
      initialHolder,
      recipient,
      initialSupply,
      function (from, to, amount) {
        return this.token.transfer(to, amount, {
          from,
        });
      },
    );
  });

  describe('_transferAsset', function () {
    shouldBehaveLikeAsset20Transfer(
      'Asset20',
      initialHolder,
      initialHolderId,
      recipientId,
      initialSupply,
      function (from, fromId, toId, amount) {
        return this.token.methods['transferFrom(uint256,uint256,uint256)'](
          fromId,
          toId,
          amount,
          {
            from,
          },
        );
      },
    );
  });

  describe('_approve', function () {
    shouldBehaveLikeERC20Approve(
      'Asset20',
      initialHolder,
      recipient,
      initialSupply,
      function (owner, spender, amount) {
        return this.token.methods['approve(address,uint256)'](spender, amount, {
          from: owner,
        });
      },
    );
  });

  describe('_approveAsset', function () {
    shouldBehaveLikeAsset20Approve(
      'Asset20',
      initialHolder,
      initialHolderId,
      recipient,
      recipientId,
      initialSupply,
      function (owner, ownerId, spender, amount) {
        return this.token.methods['approve(uint256,address,uint256)'](
          ownerId,
          spender,
          amount,
          {
            from: owner,
          },
        );
      },
    );
  });
});
