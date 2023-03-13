const {
  BN,
  constants,
  expectEvent,
  expectRevert,
} = require('@openzeppelin/test-helpers');

const { expect } = require('chai');

const Wallet = require('ethereumjs-wallet').default;
const ethSigUtil = require('eth-sig-util');
const { web3, ethers } = require('hardhat');

//const deadline = new BN(parseInt(new Date().getTime() / 1000) + 36000);
const deadline = new BN(0);

const EIP712Domain = [
  {
    name: 'name',
    type: 'string',
  },
  {
    name: 'version',
    type: 'string',
  },
  {
    name: 'chainId',
    type: 'uint256',
  },
  {
    name: 'verifyingContract',
    type: 'address',
  },
];

const { ZERO_ADDRESS } = constants;

const Acert = artifacts.require('Acert');

const Metaverse = artifacts.require('Metaverse');
const MetaverseCore = artifacts.require('MetaverseCore');
const MetaverseStorage = artifacts.require('MetaverseStorage');

const World = artifacts.require('World');
const WorldCore = artifacts.require('WorldCore');
const WorldStorage = artifacts.require('WorldStorage');

const version = '1.0.0';
const remark = 'remark';

contract('Metaverse', function (accounts) {
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

    this.chainId = await this.MetaverseCore.getChainId();
  });

  context('测试Metaverse 功能', function () {
    describe('registerWorld ', function () {
      it('zero address should return revert', async function () {
        await expectRevert(
          this.MetaverseCore.registerWorld(ZERO_ADDRESS),
          'Metaverse: address is zero',
        );
      });

      it('registerWorld ', async function () {
        await this.MetaverseCore.registerWorld(this.World.address);

        const worlds = await this.MetaverseCore.getWorlds();
        expect(worlds.length).to.be.equal(1);
        expect(worlds[0]).to.be.equal(this.World.address);
      });
    });

    describe('disableWorld ', function () {
      it('zero address should return revert', async function () {
        await expectRevert(
          this.MetaverseCore.disableWorld(ZERO_ADDRESS),
          'Metaverse: world is not exist',
        );
      });
    });

    describe('setAdmin', function () {
      it('zero address should return revert', async function () {
        await expectRevert(
          this.MetaverseCore.setAdmin(ZERO_ADDRESS),
          'Metaverse: address is zero',
        );
      });

      it('SetAdmin', async function () {
        const [admin] = accounts;
        await this.MetaverseCore.setAdmin(admin);

        expect(await this.MetaverseCore.getAdmin()).to.be.equal(admin);
      });
    });

    describe('addOperator', function () {
      it('zero address should return revert', async function () {
        await expectRevert(
          this.MetaverseCore.addOperator(ZERO_ADDRESS),
          'Metaverse: address is zero',
        );
      });

      it('addOperator', async function () {
        const [operator] = accounts;
        await this.MetaverseCore.addOperator(operator);

        expect(await this.MetaverseCore.checkBWO(operator)).to.be.equal(true);
      });
    });

    describe('removeOperator', function () {
      it('return event ', async function () {
        const [, operator] = accounts;
        await this.MetaverseCore.addOperator(operator);

        expect(await this.MetaverseCore.checkBWO(operator)).to.be.equal(true);

        await this.MetaverseCore.removeOperator(operator);

        expect(await this.MetaverseCore.checkBWO(operator)).to.be.equal(false);
      });
    });

    describe('isBWO', function () {
      it('check', async function () {
        const [, operator] = accounts;
        expect(await this.MetaverseCore.checkBWO(operator)).to.be.equal(false);
        await this.MetaverseCore.addOperator(operator);
        expect(await this.MetaverseCore.checkBWO(operator)).to.be.equal(true);
      });
    });

    describe('containsWorld, getWorlds, getWorldCount, getWorldInfo', function () {
      beforeEach(async function () {
        await this.MetaverseCore.registerWorld(this.World.address);
      });

      it('getWorlds', async function () {
        expect(await this.Metaverse.getWorlds()).to.have.ordered.members([
          this.World.address,
        ]);
      });
    });
  });

  context('Account', function () {
    describe('getOrCreateAccountId', function () {
      context('create account ', function () {
        it('carete account event ', async function () {
          const [account] = accounts;
          expectEvent(
            await this.Metaverse.createAccount(account, false),
            'CreateAccount',
            {
              accountId: new BN(
                await this.Metaverse.getAccountIdByAddress(account),
              ),
              authAddress: account,
              isTrustAdmin: false,
            },
          );
        });
        it('BWO', async function () {
          // 这个是用户的私钥
          const accountW = Wallet.generate();
          // 这个是用户的地址
          const account = accountW.getChecksumAddressString();
          // Metaverse合约 的操作者
          const [operator] = accounts;
          await this.MetaverseCore.addOperator(operator);

          // 1.获取用户的nonce，从Metaverse合约中获取
          const nonce = await this.Metaverse.getNonce(account);
          // 2.生成签名数据结构体
          const data = {
            types: {
              EIP712Domain,
              createAccountBWO: [
                {
                  name: '_address',
                  type: 'address',
                },
                {
                  name: '_isTrustAdmin',
                  type: 'bool',
                },
                {
                  name: 'sender',
                  type: 'address',
                },
                {
                  name: 'nonce',
                  type: 'uint256',
                },
                {
                  name: 'deadline',
                  type: 'uint256',
                },
              ],
            },
            domain: {
              name: 'metaverse',
              version: version,
              chainId: this.chainId,
              verifyingContract: this.MetaverseCore.address,
            },
            primaryType: 'createAccountBWO',
            message: {
              _address: account, // 这个是用户的地址
              _isTrustAdmin: true, // 是否信任管理员admin
              sender: account, // 这个是用户的地址
              nonce, // 这个是用户的nonce
              deadline, // 这个是deadline
            },
          };
          // 3.生成签名,用户的私钥签名上面数据
          const signature = ethSigUtil.signTypedMessage(
            accountW.getPrivateKey(),
            {
              data,
            },
          );
          // 4.调用Metaverse合约的createAccountBWO方法
          await this.Metaverse.createAccountBWO(
            account,
            true,
            account,
            deadline,
            signature,
            {
              from: operator,
            },
          );
          // 5.验证是否创建成功
          const accountId = await this.Metaverse.getAccountIdByAddress(account);
          // 6.验证是否是信任管理员
          expect(
            await this.Metaverse.accountIsTrustAdmin(accountId),
          ).to.be.equal(true);
        });
      });
    });
    describe('getIdByAddress', function () {
      context('get account id by address', function () {
        it('equal 101', async function () {
          const [account] = accounts;
          await this.Metaverse.createAccount(account, false);
          expect(
            await this.Metaverse.getAccountIdByAddress(account),
          ).to.bignumber.equal(new BN(1));
        });
      });
    });
    describe('getAddressByAccountId', function () {
      context('get account id', function () {
        it('account id is not exist', async function () {
          expect(
            await this.Metaverse.getAddressByAccountId(new BN(1)),
          ).to.equal(ZERO_ADDRESS);
        });
        it('account id is exist', async function () {
          const [account] = accounts;
          await this.Metaverse.createAccount(account, false);
          expect(
            await this.Metaverse.getAddressByAccountId(new BN(1)),
          ).to.equal(account);
        });
      });
    });

    describe('createAccount', function () {
      context('create account ', function () {
        it('zero address', async function () {
          const [account] = accounts;
          await expectRevert(
            this.Metaverse.createAccount(ZERO_ADDRESS, false, {
              from: account,
            }),
            'Metaverse: address is zero',
          );
        });
        it('is address exist', async function () {
          const [account] = accounts;
          await this.Metaverse.createAccount(account, true, { from: account });
          await expectRevert(
            this.Metaverse.createAccount(account, true, { from: account }),
            'Metaverse: new address has been used',
          );
        });
      });
    });

    describe('createAccount with start id', function () {
      context('create account ', function () {
        it('id expect 11', async function () {
          this.newMetaverse = await Metaverse.new();
          this.newMetaverseStorage = await MetaverseStorage.new();
          this.newMetaverseCore = await MetaverseCore.new(
            'metaverse',
            version,
            10,
            this.newMetaverseStorage.address,
          );
          await this.newMetaverseStorage.updateMetaverse(
            this.newMetaverseCore.address,
          );
          await this.newMetaverseCore.updateShell(this.newMetaverse.address);
          await this.newMetaverse.updateCore(this.newMetaverseCore.address);

          const [account] = accounts;
          await this.newMetaverse.createAccount(account, false);
          expect(
            await this.newMetaverse.getAccountIdByAddress(account),
          ).to.bignumber.equal(new BN(11));
        });
      });
    });

    describe('freezeAccount', function () {
      it('return event', async function () {
        const [account] = accounts;
        await this.Metaverse.createAccount(account, false);
        const accountId = new BN(
          await this.Metaverse.getAccountIdByAddress(account),
        );

        await this.Metaverse.freezeAccount(accountId, {
          from: account,
        });

        expect(await this.Metaverse.accountIsFreeze(accountId)).to.be.equal(
          true,
        );
      });

      it('is BWO', async function () {
        const accountW = Wallet.generate();
        const account = accountW.getChecksumAddressString();
        await this.Metaverse.createAccount(account, false);
        const accountId = new BN(
          await this.Metaverse.getAccountIdByAddress(account),
        );
        const [operator] = accounts;
        await this.MetaverseCore.addOperator(operator);

        const nonce = await this.Metaverse.getNonce(account);
        const signature = signFreezeAccountData(
          this.chainId,
          this.MetaverseCore.address,
          'metaverse',
          accountW.getPrivateKey(),
          version,
          accountId,
          account,
          nonce,
          deadline,
        );

        await this.Metaverse.freezeAccountBWO(
          accountId,
          account,
          deadline,
          signature,
          {
            from: operator,
          },
        );

        expect(await this.Metaverse.accountIsFreeze(accountId)).to.be.equal(
          true,
        );
      });
    });

    describe('unfreezeAccount', function () {
      it('return event', async function () {
        const [account, admin, newAccount] = accounts;
        await this.MetaverseCore.setAdmin(admin);

        await this.Metaverse.createAccount(account, false);
        const accountId = new BN(
          await this.Metaverse.getAccountIdByAddress(account),
        );
        expect(await this.Metaverse.accountIsFreeze(accountId)).to.be.equal(
          false,
        );

        await this.Metaverse.freezeAccount(accountId, {
          from: account,
        });
        expect(await this.Metaverse.accountIsFreeze(accountId)).to.be.equal(
          true,
        );

        await this.MetaverseCore.unfreezeAccount(accountId, newAccount, {
          from: admin,
        });

        expect(await this.Metaverse.accountIsFreeze(accountId)).to.be.equal(
          false,
        );
      });
    });

    describe('addAuthAddress and removeAuthAddress', function () {
      it('add and remove', async function () {
        const [owner, authAccount] = accounts;

        await this.Metaverse.createAccount(owner, false);

        const ownerId = await this.Metaverse.getAccountIdByAddress(owner);

        this.domain = {
          name: 'metaverse',
          version: '1.0.0',
          chainId: this.chainId.toString(),
          verifyingContract: this.MetaverseCore.address,
        };

        this.signAuthTypes = {
          AddAuth: [
            {
              name: 'id',
              type: 'uint256',
            },
            {
              name: 'addr',
              type: 'address',
            },
            {
              name: 'nonce',
              type: 'uint256',
            },
            {
              name: 'deadline',
              type: 'uint256',
            },
          ],
        };

        const value = {
          id: ownerId.toString(),
          addr: authAccount,
          nonce: '0',
          deadline: deadline.toString(),
        };

        this.authAccountSinger = await ethers.getSigner(authAccount);

        const signature = await this.authAccountSinger._signTypedData(
          this.domain,
          this.signAuthTypes,
          value,
        );

        await this.Metaverse.addAuthAddress(
          ownerId,
          authAccount,
          deadline,
          signature,
          {
            from: owner,
          },
        );

        expect(
          await this.Metaverse.getAccountIdByAddress(authAccount),
        ).to.be.bignumber.equal(ownerId);

        await this.Metaverse.removeAuthAddress(ownerId, owner, {
          from: authAccount,
        });

        expect(await this.Metaverse.getAddressByAccountId(ownerId)).to.be.equal(
          authAccount,
        );
      });

      it('add by admin and remove', async function () {
        const [admin,owner, authAccount] = accounts;

        await this.MetaverseCore.setAdmin(admin);

        await this.Metaverse.createAccount(owner, false);

        const ownerId = await this.Metaverse.getAccountIdByAddress(owner);

        this.domain = {
          name: 'metaverse',
          version: '1.0.0',
          chainId: this.chainId.toString(),
          verifyingContract: this.MetaverseCore.address,
        };

        this.signAuthTypes = {
          AddAuth: [
            {
              name: 'id',
              type: 'uint256',
            },
            {
              name: 'addr',
              type: 'address',
            },
            {
              name: 'nonce',
              type: 'uint256',
            },
            {
              name: 'deadline',
              type: 'uint256',
            },
          ],
        };

        const value = {
          id: ownerId.toString(),
          addr: authAccount,
          nonce: '0',
          deadline: deadline.toString(),
        };

        this.authAccountSinger = await ethers.getSigner(authAccount);

        const signature = await this.authAccountSinger._signTypedData(
          this.domain,
          this.signAuthTypes,
          value,
        );

        await this.MetaverseCore.addAccountAuthAddress(
          ownerId,
          authAccount,
          deadline,
          signature,
          {
            from: admin,
          },
        );

        expect(
          await this.Metaverse.getAccountIdByAddress(authAccount),
        ).to.be.bignumber.equal(ownerId);

        await this.Metaverse.removeAuthAddress(ownerId, owner, {
          from: authAccount,
        });

        expect(await this.Metaverse.getAddressByAccountId(ownerId)).to.be.equal(
          authAccount,
        );
      });
    });
  });
});

function signFreezeAccountData(
  chainId,
  verifyingContract,
  name,
  key,
  version,
  id,
  sender,
  nonce,
  deadline,
) {
  const data = {
    types: {
      EIP712Domain,
      freezeAccountBWO: [
        {
          name: 'id',
          type: 'uint256',
        },
        {
          name: 'sender',
          type: 'address',
        },
        {
          name: 'nonce',
          type: 'uint256',
        },
        {
          name: 'deadline',
          type: 'uint256',
        },
      ],
    },
    domain: {
      name,
      version,
      chainId,
      verifyingContract,
    },
    primaryType: 'freezeAccountBWO',
    message: {
      id,
      sender,
      nonce,
      deadline,
    },
  };

  const signature = ethSigUtil.signTypedMessage(key, {
    data,
  });

  return signature;
}
