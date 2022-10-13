const {
  BN,
  constants,
  expectEvent,
  expectRevert
} = require('@openzeppelin/test-helpers');
const {
  ZERO_ADDRESS
} = require('@openzeppelin/test-helpers/src/constants');
const {
  expect
} = require('chai');
const {
  MAX_UINT256
} = constants;
const ethSigUtil = require('eth-sig-util');
const {
  web3
} = require('hardhat');


const deadline = new BN(parseInt(new Date().getTime() / 1000) + 3600);

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


function shouldBehaveLikeAsset20BWO(errorPrefix, initialSupply, initialHolder, initialHolderId,
  recipient, recipientId, anotherAccount, anotherAccountId, BWOKey, receiptKey) {

  describe('total supply', function () {
    it('returns the total amount of tokens', async function () {
      expect(await this.token.totalSupply()).to.be.bignumber.equal(initialSupply.mul(new BN(2)));
    });
  });

  describe('balanceOfCash', function () {
    describe('when the requested account has no tokens', function () {
      it('returns zero', async function () {
        expect(await this.token.methods['balanceOf(uint256)'](anotherAccountId)).to.be.bignumber.equal('0');
      });
    });

    describe('when the requested account has some tokens', function () {
      it('returns the total amount of tokens', async function () {
        expect(await this.token.methods['balanceOf(uint256)'](initialHolderId)).to.be.bignumber.equal(initialSupply);
      });
    });
  });

  describe('transferFromBWO', function () {
    shouldBehaveLikeAsset20TransferBWO(errorPrefix, initialHolder, initialHolderId, recipientId, initialSupply, BWOKey,
      function (spender, from, to, value, nonce, key) {
        const signature = signTransferData(this.chainId, this.token.address, this.tokenName, key, this.tokenVersion,
          spender, from, to, value, deadline, nonce);
        return this.token.transferFromBWO(from, to, value, spender, deadline, signature, {
          from: this.BWO
        });
      },
    );
  });

  describe('transferFromBWO test', function () {
    const spender = recipientId;
    const spenderAddr = recipient;

    describe('when the token owner is not the zero id', function () {
      const tokenOwner = initialHolderId;
      const tokenOwnerAddr = initialHolder;

      describe('when the recipientId is the zero Id', function () {
        const amount = initialSupply;
        const to = 0;

        beforeEach(async function () {

          const nonce = await this.token.getNonce(tokenOwnerAddr);;
          const signature = signApproveData(this.chainId, this.token.address, this.tokenName, BWOKey, this.tokenVersion,
            tokenOwner, spenderAddr, amount, tokenOwnerAddr, deadline, nonce);

          await this.token.approveBWO(tokenOwner, spenderAddr, amount, tokenOwnerAddr, deadline, signature, {
            from: this.BWO
          });
        });

        it('burn token', async function () {

          const nonce = await this.token.getNonce(tokenOwnerAddr);

          const signature = signTransferData(this.chainId, this.token.address, this.tokenName, BWOKey, this.tokenVersion,
            tokenOwnerAddr, tokenOwner, to, amount, deadline, nonce);

          const beforeBalance = await this.token.methods['balanceOf(uint256)'](tokenOwner)

          await this.token.transferFromBWO(tokenOwner, to, amount, tokenOwnerAddr, deadline, signature, {
            from: this.BWO
          })

          expect(await this.token.methods['balanceOf(uint256)'](tokenOwner)).to.be.bignumber.equal(beforeBalance.sub(amount));

        });
      });

      describe('when the recipientId is the not exist Id', function () {
        const amount = initialSupply;
        const to = 1000;

        it('reverts', async function () {

          const nonce = await this.token.getNonce(spenderAddr);

          const signature = signTransferData(this.chainId, this.token.address, this.tokenName, BWOKey, this.tokenVersion,
            tokenOwnerAddr, tokenOwner, to, amount, deadline, nonce);

          await expectRevert(this.token.transferFromBWO(tokenOwner, to, amount, tokenOwnerAddr, deadline, signature, {
            from: this.BWO
          }), `${errorPrefix}: to account is not exist`,);
        });
      });
    });

    describe('when the token owner is the zero id', function () {
      const amount = 0;
      const tokenOwner = 0;
      const to = recipientId;

      it('reverts', async function () {

        const nonce = await this.token.getNonce(spenderAddr);

        const signature = signTransferData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion,
          spenderAddr, tokenOwner, to, amount, deadline, nonce);

        await expectRevert(
          this.token.transferFromBWO(tokenOwner, to, amount, spenderAddr, deadline, signature, {
            from: this.BWO
          }),
          'Asset20: approve from the zero address',
        );
      });
    });
  });

  describe('approveBWO', function () {
    shouldBehaveLikeAsset20ApproveBWO(errorPrefix, initialHolderId, initialHolder, recipient, recipientId, initialSupply, BWOKey,
      function (owner, ownerAddr, spenderAddr, amount, nonce, key) {

        const signature = signApproveData(this.chainId, this.token.address, this.tokenName, key, this.tokenVersion,
          owner, spenderAddr, amount, ownerAddr, deadline, nonce)

        return this.token.approveBWO(owner, spenderAddr, amount, ownerAddr, deadline, signature, {
          from: this.BWO
        });
      },
    );
  });

}

function shouldBehaveLikeAsset20TransferBWO(errorPrefix, spender, from, to, balance, key, transfer) {
  describe('when the recipientId is not the zero id', function () {
    describe('when the sender does not have enough balance', function () {
      const amount = balance.addn(1);

      it('reverts', async function () {
        const nonce = await this.token.getNonce(spender);
        await expectRevert(transfer.call(this, spender, from, to, amount, nonce, key),
          `${errorPrefix}: transfer amount exceeds balance`,
        );
      });
    });

    describe('when the sender transfers all balance', function () {
      const amount = balance;

      it('transfers the requested amount', async function () {
        const nonce = await this.token.getNonce(spender);

        await transfer.call(this, spender, from, to, amount, nonce, key);

        expect(await this.token.methods['balanceOf(uint256)'](from)).to.be.bignumber.equal('0');

        expect(await this.token.methods['balanceOf(uint256)'](to)).to.be.bignumber.equal(amount);
      });

      it('emits a transfer by id event', async function () {
        const nonce = await this.token.getNonce(spender);
        expectEvent(
          await transfer.call(this, spender, from, to, amount, nonce, key),
          'AssetTransfer', {
          from,
          to,
          value: amount,
          isBWO: true,
          sender: web3.utils.toChecksumAddress(spender),
          nonce: nonce,
        },
        );
      });
    });

    describe('when the sender transfers zero tokens', function () {
      const amount = new BN('0');

      it('transfers the requested amount', async function () {
        const nonce = await this.token.getNonce(spender);

        await transfer.call(this, spender, from, to, amount, nonce, key);

        expect(await this.token.methods['balanceOf(uint256)'](from)).to.be.bignumber.equal(balance);

        expect(await this.token.methods['balanceOf(uint256)'](to)).to.be.bignumber.equal('0');
      });

      it('emits a transfer by id event', async function () {
        const nonce = await this.token.getNonce(spender);

        expectEvent(
          await transfer.call(this, spender, from, to, amount, nonce, key),
          'AssetTransfer', {
          from,
          to,
          value: amount,
          isBWO: true,
          sender: web3.utils.toChecksumAddress(spender),
          nonce: nonce,
        },
        );
      });
    });

    // describe('when the sender is Freeze', function () {
    //   it('reverts', async function () {
    //     await this.Metaverse.freezeAccount(from, {
    //       from: spender
    //     });

    //     const nonce = await this.token.getNonce(spender);

    //     await expectRevert(transfer.call(this, spender, from, to, balance, nonce, key),
    //       `${errorPrefix}: transfer from is frozen`,
    //     );
    //   });
    // });

  });

  describe('when the recipientId is the zero Id', function () {
    it('burn token', async function () {
      const nonce = await this.token.getNonce(spender);
      const beforeBalance = await this.token.methods['balanceOf(uint256)'](from)

      await transfer.call(this, spender, from, 0, balance, nonce, key)

      expect(await this.token.methods['balanceOf(uint256)'](from)).to.be.bignumber.equal(beforeBalance.sub(balance));

    });
  });
}

function shouldBehaveLikeAsset20ApproveBWO(errorPrefix, owner, ownerAddr, spenderAddr, spender, supply, key, approve) {
  describe('when the spender is not the zero Id', function () {
    describe('when the sender has enough balance', function () {
      const amount = supply;

      it('emits an approval by id event', async function () {
        const nonce = await this.token.getNonce(ownerAddr);
        expectEvent(
          await approve.call(this, owner, ownerAddr, spenderAddr, amount, nonce, key),
          'AssetApproval', {
          owner: owner,
          spender: web3.utils.toChecksumAddress(spenderAddr),
          value: amount,
          isBWO: true,
          sender: web3.utils.toChecksumAddress(ownerAddr),
          nonce: nonce,
        },
        );
      });

      describe('when there was no approved amount before', function () {
        it('approves the requested amount', async function () {
          const nonce = await this.token.getNonce(ownerAddr);
          await approve.call(this, owner, ownerAddr, spenderAddr, amount, nonce, key);

          expect(await this.token.methods['allowance(uint256,address)'](owner, spenderAddr)).to.be.bignumber.equal(amount);
        });
      });

      describe('when the spender had an approved amount', function () {
        beforeEach(async function () {
          const nonce = await this.token.getNonce(ownerAddr);

          await approve.call(this, owner, ownerAddr, spenderAddr, new BN(1), nonce, key);
        });

        it('approves the requested amount and replaces the previous one', async function () {
          const nonce = await this.token.getNonce(ownerAddr);

          await approve.call(this, owner, ownerAddr, spenderAddr, amount, nonce, key);

          expect(await this.token.methods['allowance(uint256,address)'](owner, spenderAddr)).to.be.bignumber.equal(amount);
        });
      });
    });

    describe('when the sender does not have enough balance', function () {
      const amount = supply.addn(1);

      it('emits an approval by Id event', async function () {
        const nonce = await this.token.getNonce(ownerAddr);

        expectEvent(
          await approve.call(this, owner, ownerAddr, spenderAddr, amount, nonce, key),
          'AssetApproval', {
          owner: owner,
          spender: web3.utils.toChecksumAddress(spenderAddr),
          value: amount,
          isBWO: true,
          sender: web3.utils.toChecksumAddress(ownerAddr),
          nonce: nonce,
        },
        );
      });

      describe('when there was no approved amount before', function () {
        it('approves the requested amount', async function () {
          const nonce = await this.token.getNonce(ownerAddr);

          await approve.call(this, owner, ownerAddr, spenderAddr, amount, nonce, key);

          expect(await this.token.methods['allowance(uint256,address)'](owner, spenderAddr)).to.be.bignumber.equal(amount);
        });
      });

      describe('when the spender had an approved amount', function () {
        beforeEach(async function () {
          const nonce = await this.token.getNonce(ownerAddr);
          await approve.call(this, owner, ownerAddr, spenderAddr, new BN(1), nonce, key);
        });

        it('approves the requested amount and replaces the previous one', async function () {
          const nonce = await this.token.getNonce(ownerAddr);
          await approve.call(this, owner, ownerAddr, spenderAddr, amount, nonce, key);

          expect(await this.token.methods['allowance(uint256,address)'](owner, spenderAddr)).to.be.bignumber.equal(amount);
        });
      });
    });

    // describe('when the owner is frozen', function () {
    //   it('reverts', async function () {
    //     await this.Metaverse.freezeAccount(owner, {
    //       from: ownerAddr
    //     });
    //     const nonce = await this.token.getNonce(ownerAddr);
    //     await expectRevert(approve.call(this, owner, ownerAddr, spenderAddr, amount, nonce, key),
    //       `${errorPrefix}: approve owner is frozen`,
    //     );

    //   });
    // })
  });

  describe('when the spender is the zero address', function () {
    it('reverts', async function () {
      const nonce = await this.token.getNonce(ownerAddr);
      await expectRevert(approve.call(this, owner, ownerAddr, ZERO_ADDRESS, supply, nonce, key),
        `${errorPrefix}: approve to the zero address`,
      );
    });
  });
}

function signApproveData(chainId, verifyingContract, name, key, version,
  ownerId, spender, amount, sender, deadline, nonce) {
  const data = {
    types: {
      EIP712Domain,
      BWO: [{
        name: 'ownerId',
        type: 'uint256'
      },
      {
        name: 'spender',
        type: 'address'
      },
      {
        name: 'amount',
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
      ownerId,
      spender,
      amount,
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

function signTransferData(chainId, verifyingContract, name, key, version,
  sender, from, to, amount, deadline, nonce) {
  const data = {
    types: {
      EIP712Domain,
      BWO: [{
        name: 'from',
        type: 'uint256'
      },
      {
        name: 'to',
        type: 'uint256'
      },
      {
        name: 'amount',
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
      from,
      to,
      amount,
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
  shouldBehaveLikeAsset20BWO,
  shouldBehaveLikeAsset20TransferBWO,
  shouldBehaveLikeAsset20ApproveBWO,
};