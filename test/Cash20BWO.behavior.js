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


function shouldBehaveLikeCash20BWO(errorPrefix, initialSupply, initialHolder, initialHolderId,
  recipient, recipientId, anotherAccount, anotherAccountId, BWOKey, receiptKey) {

  describe('total supply', function () {
    it('returns the total amount of tokens', async function () {
      expect(await this.token.totalSupply()).to.be.bignumber.equal(initialSupply.mul(new BN(2)));
    });
  });

  describe('balanceOfCash', function () {
    describe('when the requested account has no tokens', function () {
      it('returns zero', async function () {
        expect(await this.token.balanceOfCash(anotherAccountId)).to.be.bignumber.equal('0');
      });
    });

    describe('when the requested account has some tokens', function () {
      it('returns the total amount of tokens', async function () {
        expect(await this.token.balanceOfCash(initialHolderId)).to.be.bignumber.equal(initialSupply);
      });
    });
  });

  describe('transferCashBWO', function () {
    shouldBehaveLikeCash20TransferBWO(errorPrefix, initialHolder, initialHolderId, recipientId, initialSupply, BWOKey,
      function (spender, from, to, value, nonce, key) {
        const signature = signTransferData(this.chainId, this.token.address, this.tokenName, key, this.tokenVersion,
          spender, from, to, value, deadline, nonce);
        return this.token.transferCashBWO(spender, from, to, value, deadline, signature, {
          from: this.BWO
        });
      },
    );
  });

  describe('transferCashBWO test', function () {
    const spender = recipientId;
    const spenderAddr = recipient;

    describe('when the token owner is not the zero id', function () {
      const tokenOwner = initialHolderId;
      const tokenOwnerAddr = initialHolder;

      describe('when the recipientId is not the zero id', function () {
        const to = anotherAccountId;

        describe('when the spender has enough allowance', function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(initialHolderId);

            const signature = signApproveData(this.chainId, this.token.address, this.tokenName, BWOKey, this.tokenVersion,
              initialHolderId, spenderAddr, initialSupply, deadline, nonce);
            await this.token.approveCashBWO(initialHolderId, spenderAddr, initialSupply, deadline, signature, {
              from: this.BWO
            });
          });

          describe('when the token owner has enough balance', function () {
            const amount = initialSupply;

            it('transfers the requested amount', async function () {
              const nonce = await this.token.getNonce(spender);
              const signature = signTransferData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion,
                spenderAddr, tokenOwner, to, amount, deadline, nonce);

              await this.token.transferCashBWO(spenderAddr, tokenOwner, to, amount, deadline, signature, {
                from: this.BWO
              });

              expect(await this.token.balanceOfCash(tokenOwner)).to.be.bignumber.equal('0');

              expect(await this.token.balanceOfCash(to)).to.be.bignumber.equal(amount);
            });

            it('decreases the spender allowance', async function () {
              const nonce = await this.token.getNonce(spender);

              const signature = signTransferData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion,
                spenderAddr, tokenOwner, to, amount, deadline, nonce);

              await this.token.transferCashBWO(spenderAddr, tokenOwner, to, amount, deadline, signature, {
                from: this.BWO
              });

              expect(await this.token.allowanceCash(tokenOwner, spenderAddr)).to.be.bignumber.equal('0');
            });

            it('emits a transfer by id event', async function () {
              const nonce = await this.token.getNonce(spender);


              const signature = signTransferData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion,
                spenderAddr, tokenOwner, to, amount, deadline, nonce);
              expectEvent(
                await this.token.transferCashBWO(spenderAddr, tokenOwner, to, amount, deadline, signature, {
                  from: this.BWO
                }),
                'TransferCashBWO', {
                  from: tokenOwner,
                  to: to,
                  value: amount
                },
              );
            });

            it('emits an approval by id event', async function () {
              const nonce = await this.token.getNonce(spender);

              const signature = signTransferData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion,
                spenderAddr, tokenOwner, to, amount, deadline, nonce);

              expectEvent(
                await this.token.transferCashBWO(spenderAddr, tokenOwner, to, amount, deadline, signature, {
                  from: this.BWO
                }),
                'ApprovalCashBWO', {
                  owner: tokenOwner,
                  spender: web3.utils.toChecksumAddress(spenderAddr),
                  value: await this.token.allowanceCash(tokenOwner, spenderAddr)
                },
              );
            });
          });

          describe('when the token owner does not have enough balance', function () {
            const amount = initialSupply;
            beforeEach('reducing balance', async function () {
              const nonce = await this.token.getNonce(tokenOwner);

              const signature = signTransferData(this.chainId, this.token.address, this.tokenName, BWOKey, this.tokenVersion,
                tokenOwnerAddr, tokenOwner, to, 1, deadline, nonce);
              await this.token.transferCashBWO(tokenOwnerAddr, tokenOwner, to, 1, deadline, signature, {
                from: this.BWO
              });
            });

            it('reverts', async function () {
              const nonce = await this.token.getNonce(spender);

              const signature = signTransferData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion,
                spenderAddr, tokenOwner, to, amount, deadline, nonce);

              await expectRevert(
                this.token.transferCashBWO(spenderAddr, tokenOwner, to, amount, deadline, signature, {
                  from: this.BWO
                }),
                `${errorPrefix}: transfer amount exceeds balance`,
              );
            });
          });
        });

        describe('when the spender does not have enough allowance', function () {
          const allowance = initialSupply.subn(1);

          beforeEach(async function () {
            const nonce = await this.token.getNonce(tokenOwner);

            const signature = signApproveData(this.chainId, this.token.address, this.tokenName, BWOKey, this.tokenVersion,
              tokenOwner, spenderAddr, allowance, deadline, nonce);

            await this.token.approveCashBWO(tokenOwner, spenderAddr, allowance, deadline, signature, {
              from: this.BWO
            });
          });

          describe('when the token owner has enough balance', function () {
            const amount = initialSupply;

            it('reverts', async function () {
              const nonce = await this.token.getNonce(spender);

              const signature = signTransferData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion,
                spenderAddr, tokenOwner, to, amount, deadline, nonce);

              await expectRevert(
                this.token.transferCashBWO(spenderAddr, tokenOwner, to, amount, deadline, signature, {
                  from: this.BWO
                }),
                `${errorPrefix}: insufficient allowance`,
              );
            });
          });

          describe('when the token owner does not have enough balance', function () {
            const amount = allowance;

            beforeEach('reducing balance', async function () {
              const nonce = await this.token.getNonce(tokenOwner);

              const signature = signTransferData(this.chainId, this.token.address, this.tokenName, BWOKey, this.tokenVersion,
                tokenOwnerAddr, tokenOwner, to, 2, deadline, nonce);

              await this.token.transferCashBWO(tokenOwnerAddr, tokenOwner, to, 2, deadline, signature, {
                from: this.BWO
              });
            });

            it('reverts', async function () {

              const nonce = await this.token.getNonce(spender);

              const signature = signTransferData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion,
                spenderAddr, tokenOwner, to, amount, deadline, nonce);

              await expectRevert(
                this.token.transferCashBWO(spenderAddr, tokenOwner, to, amount, deadline, signature, {
                  from: this.BWO
                }),
                `${errorPrefix}: transfer amount exceeds balance`,
              );
            });
          });
        });

        describe('when the spender has unlimited allowance', function () {
          beforeEach(async function () {

            const nonce = await this.token.getNonce(initialHolderId);

            const signature = signApproveData(this.chainId, this.token.address, this.tokenName, BWOKey, this.tokenVersion,
              initialHolderId, spenderAddr, MAX_UINT256, deadline, nonce);

            await this.token.approveCashBWO(initialHolderId, spenderAddr, MAX_UINT256, deadline, signature, {
              from: this.BWO
            });
          });

          it('does not decrease the spender allowance', async function () {

            const nonce = await this.token.getNonce(spender);

            const signature = signTransferData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion,
              spenderAddr, tokenOwner, to, 1, deadline, nonce);

            await this.token.transferCashBWO(spenderAddr, tokenOwner, to, 1, deadline, signature, {
              from: this.BWO
            });

            expect(await this.token.allowanceCash(tokenOwner, spenderAddr)).to.be.bignumber.equal(MAX_UINT256);
          });

          it('does not emit an approval by id event', async function () {

            const nonce = await this.token.getNonce(spender);

            const signature = signTransferData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion,
              spenderAddr, tokenOwner, to, 1, deadline, nonce);

            expectEvent.notEmitted(
              await this.token.transferCashBWO(spenderAddr, tokenOwner, to, 1, deadline, signature, {
                from: this.BWO
              }),
              'ApprovalCashBWO',
            );
          });
        });
      });

      describe('when the recipientId is the zero Id', function () {
        const amount = initialSupply;
        const to = 0;

        beforeEach(async function () {

          const nonce = await this.token.getNonce(tokenOwner);
          const signature = signApproveData(this.chainId, this.token.address, this.tokenName, BWOKey, this.tokenVersion,
            tokenOwner, spenderAddr, amount, deadline, nonce);

          await this.token.approveCashBWO(tokenOwner, spenderAddr, amount, deadline, signature, {
            from: this.BWO
          });
        });

        it('reverts', async function () {

          const nonce = await this.token.getNonce(spender);

          const signature = signTransferData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion,
            spenderAddr, tokenOwner, to, amount, deadline, nonce);

          await expectRevert(this.token.transferCashBWO(spenderAddr,
            tokenOwner, to, amount, deadline, signature, {
              from: this.BWO
            }), `${errorPrefix}: transfer to the zero Id`, );
        });
      });
    });

    describe('when the token owner is the zero id', function () {
      const amount = 0;
      const tokenOwner = 0;
      const to = recipientId;

      it('reverts', async function () {

        const nonce = await this.token.getNonce(spender);

        const signature = signTransferData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion,
          spenderAddr, tokenOwner, to, amount, deadline, nonce);

        await expectRevert(
          this.token.transferCashBWO(spenderAddr, tokenOwner, to, amount, deadline, signature, {
            from: this.BWO
          }),
          'Cash: from is the zero id',
        );
      });
    });
  });

  describe('approveCashBWO', function () {
    shouldBehaveLikeCash20ApproveBWO(errorPrefix, initialHolderId, recipient, recipientId, initialSupply, BWOKey,
      function (owner, spenderAddr, amount, nonce, key) {

        const signature = signApproveData(this.chainId, this.token.address, this.tokenName, key, this.tokenVersion,
          owner, spenderAddr, amount, deadline, nonce)

        return this.token.approveCashBWO(owner, spenderAddr, amount, deadline, signature, {
          from: this.BWO
        });
      },
    );
  });
}

function shouldBehaveLikeCash20TransferBWO(errorPrefix, spender, from, to, balance, key, transfer) {
  describe('when the recipientId is not the zero id', function () {
    describe('when the sender does not have enough balance', function () {
      const amount = balance.addn(1);

      it('reverts', async function () {
        const nonce = await this.token.getNonce(from);
        await expectRevert(transfer.call(this, spender, from, to, amount, nonce, key),
          `${errorPrefix}: transfer amount exceeds balance`,
        );
      });
    });

    describe('when the sender transfers all balance', function () {
      const amount = balance;

      it('transfers the requested amount', async function () {
        const nonce = await this.token.getNonce(from);

        await transfer.call(this, spender, from, to, amount, nonce, key);

        expect(await this.token.balanceOfCash(from)).to.be.bignumber.equal('0');

        expect(await this.token.balanceOfCash(to)).to.be.bignumber.equal(amount);
      });

      it('emits a transfer by id event', async function () {
        const nonce = await this.token.getNonce(from);
        expectEvent(
          await transfer.call(this, spender, from, to, amount, nonce, key),
          'TransferCashBWO', {
            from,
            to,
            value: amount
          },
        );
      });
    });

    describe('when the sender transfers zero tokens', function () {
      const amount = new BN('0');

      it('transfers the requested amount', async function () {
        const nonce = await this.token.getNonce(from);

        await transfer.call(this, spender, from, to, amount, nonce, key);

        expect(await this.token.balanceOfCash(from)).to.be.bignumber.equal(balance);

        expect(await this.token.balanceOfCash(to)).to.be.bignumber.equal('0');
      });

      it('emits a transfer by id event', async function () {
        const nonce = await this.token.getNonce(from);

        expectEvent(
          await transfer.call(this, spender, from, to, amount, nonce, key),
          'TransferCashBWO', {
            from,
            to,
            value: amount
          },
        );
      });
    });
  });

  describe('when the recipientId is the zero Id', function () {
    it('reverts', async function () {
      const nonce = await this.token.getNonce(from);
      await expectRevert(transfer.call(this, spender, from, 0, balance, nonce, key),
        `${errorPrefix}: transfer to the zero Id`,
      );
    });
  });
}

function shouldBehaveLikeCash20ApproveBWO(errorPrefix, owner, spenderAddr, spender, supply, key, approve) {
  describe('when the spender is not the zero Id', function () {
    describe('when the sender has enough balance', function () {
      const amount = supply;

      it('emits an approval by id event', async function () {
        const nonce = await this.token.getNonce(owner);
        expectEvent(
          await approve.call(this, owner, spenderAddr, amount, nonce, key),
          'ApprovalCashBWO', {
            owner: owner,
            spender: web3.utils.toChecksumAddress(spenderAddr),
            value: amount
          },
        );
      });

      describe('when there was no approved amount before', function () {
        it('approves the requested amount', async function () {
          const nonce = await this.token.getNonce(owner);
          await approve.call(this, owner, spenderAddr, amount, nonce, key);

          expect(await this.token.allowanceCash(owner, spenderAddr)).to.be.bignumber.equal(amount);
        });
      });

      describe('when the spender had an approved amount', function () {
        beforeEach(async function () {
          const nonce = await this.token.getNonce(owner);

          await approve.call(this, owner, spenderAddr, new BN(1), nonce, key);
        });

        it('approves the requested amount and replaces the previous one', async function () {
          const nonce = await this.token.getNonce(owner);

          await approve.call(this, owner, spenderAddr, amount, nonce, key);

          expect(await this.token.allowanceCash(owner, spenderAddr)).to.be.bignumber.equal(amount);
        });
      });
    });

    describe('when the sender does not have enough balance', function () {
      const amount = supply.addn(1);

      it('emits an approval by Id event', async function () {
        const nonce = await this.token.getNonce(owner);

        expectEvent(
          await approve.call(this, owner, spenderAddr, amount, nonce, key),
          'ApprovalCashBWO', {
            owner: owner,
            spender: web3.utils.toChecksumAddress(spenderAddr),
            value: amount
          },
        );
      });

      describe('when there was no approved amount before', function () {
        it('approves the requested amount', async function () {
          const nonce = await this.token.getNonce(owner);

          await approve.call(this, owner, spenderAddr, amount, nonce, key);

          expect(await this.token.allowanceCash(owner, spenderAddr)).to.be.bignumber.equal(amount);
        });
      });

      describe('when the spender had an approved amount', function () {
        beforeEach(async function () {
          const nonce = await this.token.getNonce(owner);
          await approve.call(this, owner, spenderAddr, new BN(1), nonce, key);
        });

        it('approves the requested amount and replaces the previous one', async function () {
          const nonce = await this.token.getNonce(owner);
          await approve.call(this, owner, spenderAddr, amount, nonce, key);

          expect(await this.token.allowanceCash(owner, spenderAddr)).to.be.bignumber.equal(amount);
        });
      });
    });
  });

  describe('when the spender is the zero address', function () {
    it('reverts', async function () {
      const nonce = await this.token.getNonce(owner);
      await expectRevert(approve.call(this, owner, ZERO_ADDRESS, supply, nonce, key),
        `${errorPrefix}: approve to the zero address`,
      );
    });
  });
}

function signApproveData(chainId, verifyingContract, name, key, version,
  from, to, value, deadline, nonce) {
  const data = {
    types: {
      EIP712Domain,
      BWO: [{
          name: 'from',
          type: 'uint256'
        },
        {
          name: 'to',
          type: 'address'
        },
        {
          name: 'value',
          type: 'uint256'
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
      value,
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
  spender, from, to, value, deadline, nonce) {
  const data = {
    types: {
      EIP712Domain,
      BWO: [{
          name: 'spender',
          type: 'address'
        },
        {
          name: 'from',
          type: 'uint256'
        },
        {
          name: 'to',
          type: 'uint256'
        },
        {
          name: 'value',
          type: 'uint256'
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
      spender,
      from,
      to,
      value,
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
  shouldBehaveLikeCash20BWO,
  shouldBehaveLikeCash20TransferBWO,
  shouldBehaveLikeCash20ApproveBWO,
};