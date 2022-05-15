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
  MAX_UINT256
} = constants;


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

function shouldBehaveLikeCash20BWO(errorPrefix, initialSupply, initialHolder, initialHolderId, recipient, recipientId, anotherAccount, anotherAccountId) {
  describe('total supply', function () {
    it('returns the total amount of tokens', async function () {
      expect(await this.token.totalSupply()).to.be.bignumber.equal(initialSupply);
    });
  });

  describe('balanceOfId', function () {
    describe('when the requested account has no tokens', function () {
      it('returns zero', async function () {
        expect(await this.token.balanceOfId(anotherAccountId)).to.be.bignumber.equal('0');
      });
    });

    describe('when the requested account has some tokens', function () {
      it('returns the total amount of tokens', async function () {
        expect(await this.token.balanceOfId(initialHolderId)).to.be.bignumber.equal(initialSupply);
      });
    });
  });

  describe('transferBWO', function () {
    shouldBehaveLikeCash20TransferBWO(errorPrefix, initialHolder, initialHolderId, recipientId, initialSupply,
      function (fromAddr, from, to, value) {
        const deadline = new BN(10);
        const signature = signData(from, to, value, deadline);
        return this.token.transferBWO(from, to, value, deadline, signature, {
          from: this.BWO
        });
      },
    );
  });

  describe('transferFromBWO ', function () {
    const spender = recipientId;
    const spenderAddr = recipient;

    describe('when the token owner is not the zero id', function () {
      const tokenOwner = initialHolderId;
      const tokenOwnerAddr = initialHolder;

      describe('when the recipientId is not the zero id', function () {
        const to = anotherAccountId;

        describe('when the spender has enough allowance', function () {
          beforeEach(async function () {

            const deadline = new BN(10);
            const signature = signData(initialHolderId, spender, initialSupply, deadline);
            await this.token.approveBWO(initialHolderId, spender, initialSupply, deadline, signature, {
              from: this.BWO
            });
          });

          describe('when the token owner has enough balance', function () {
            const amount = initialSupply;

            it('transfers the requested amount', async function () {
              const deadline = new BN(10);
              const signature = signFromData(spender, tokenOwner, to, amount, deadline);
              await this.token.transferFromBWO(spender, tokenOwner, to, amount, deadline, signature, {
                from: this.BWO
              });

              expect(await this.token.balanceOfId(tokenOwner)).to.be.bignumber.equal('0');

              expect(await this.token.balanceOfId(to)).to.be.bignumber.equal(amount);
            });

            it('decreases the spender allowance', async function () {
              const deadline = new BN(10);
              const signature = signFromData(spender, tokenOwner, to, amount, deadline);
              await this.token.transferFromBWO(spender, tokenOwner, to, amount, deadline, signature, {
                from: this.BWO
              });

              expect(await this.token.allowanceId(tokenOwner, spender)).to.be.bignumber.equal('0');
            });

            it('emits a transfer by id event', async function () {
              const deadline = new BN(10);
              const signature = signFromData(spender, tokenOwner, to, amount, deadline);
              expectEvent(
                await this.token.transferFromBWO(spender, tokenOwner, to, amount, deadline, signature, {
                  from: this.BWO
                }),
                'TransferBWO', {
                  from: tokenOwner,
                  to: to,
                  value: amount
                },
              );
            });

            it('emits an approval by id event', async function () {
              const deadline = new BN(10);
              const signature = signFromData(spender, tokenOwner, to, amount, deadline);

              expectEvent(
                await this.token.transferFromBWO(spender, tokenOwner, to, amount, deadline, signature, {
                  from: this.BWO
                }),
                'ApprovalBWO', {
                  owner: tokenOwner,
                  spender: spender,
                  value: await this.token.allowanceId(tokenOwner, spender)
                },
              );
            });
          });

          describe('when the token owner does not have enough balance', function () {
            const amount = initialSupply;
            beforeEach('reducing balance', async function () {
              const deadline = new BN(10);
              const signature = signFromData(tokenOwner, tokenOwner, to, 1, deadline);
              await this.token.transferBWO(tokenOwner, tokenOwner, to, 1, deadline, signature, {
                from: this.BWO
              });
            });

            it('reverts', async function () {
              const deadline = new BN(10);
              const signature = signFromData(spender, tokenOwner, to, amount, deadline);

              await expectRevert(
                this.token.transferFromBWO(spender, tokenOwner, to, amount, deadline, signature, {
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
            const deadline = new BN(10);
            const signature = signData(tokenOwner, spender, allowance, deadline);
            await this.token.approveBWO(tokenOwner, spender, allowance, deadline, signature, {
              from: this.BWO
            });
          });

          describe('when the token owner has enough balance', function () {
            const amount = initialSupply;
            const deadline = new BN(10);
            const signature = signFromData(spender, tokenOwner, to, amount, deadline);
            it('reverts', async function () {
              await expectRevert(
                this.token.transferFromBWO(spender, tokenOwner, to, amount, deadline, signature, {
                  from: this.BWO
                }),
                `${errorPrefix}: insufficient allowance`,
              );
            });
          });

          describe('when the token owner does not have enough balance', function () {
            const amount = allowance;
            const deadline = new BN(10);
            const signature = signFromData(tokenOwner, tokenOwner, to, 2, deadline);

            beforeEach('reducing balance', async function () {
              await this.token.transferFromBWO(tokenOwner, to, 2, deadline, signature, {
                from: this.BWO
              });
            });

            it('reverts', async function () {
              const deadline = new BN(10);
              const signature = signFromData(spender, tokenOwner, to, amount, deadline);
              await expectRevert(
                this.token.transferFromBWO(spender, tokenOwner, to, amount, new BN(0), signature, {
                  from: this.BWO
                }),
                `${errorPrefix}: transfer amount exceeds balance`,
              );
            });
          });
        });

        describe('when the spender has unlimited allowance', function () {
          beforeEach(async function () {
            const deadline = new BN(10);
            const signature = signData(initialHolderId, spender, MAX_UINT256, deadline);

            await this.token.approveBWO(initialHolderId, spender, MAX_UINT256, deadline, signature, {
              from: this.BWO
            });
          });

          it('does not decrease the spender allowance', async function () {
            const deadline = new BN(10);
            const signature = signFromData(spender, tokenOwner, to, 1, deadline);

            await this.token.transferFromBWO(tokenOwner, to, 1, deadline, signature, {
              from: this.BWO
            });

            expect(await this.token.allowanceId(tokenOwner, spender)).to.be.bignumber.equal(MAX_UINT256);
          });

          it('does not emit an approval by id event', async function () {
            const deadline = new BN(10);
            const signature = signFromData(spender, tokenOwner, to, 1, deadline);

            expectEvent.notEmitted(
              await this.token.transferFromBWO(tokenOwner, to, 1, deadline, signature, {
                from: this.BWO
              }),
              'ApprovalId',
            );
          });
        });
      });

      describe('when the recipientId is the zero Id', function () {
        const amount = initialSupply;
        const to = 0;

        beforeEach(async function () {
          const deadline = new BN(10);
          const signature = signData(tokenOwner, spender, amount, deadline);

          await this.token.approveId(tokenOwner, spender, amount, deadline, signature, {
            from: this.BWO
          });
        });

        it('reverts', async function () {

          const deadline = new BN(10);
          const signature = signFromData(spender, tokenOwner, to, amount, deadline);

          await expectRevert(this.token.transferFromBWO(
            tokenOwner, to, amount, deadline, signature, {
              from: spenderAddr
            }), `${errorPrefix}: transfer to the zero id`, );
        });
      });
    });

    describe('when the token owner is the zero id', function () {
      const amount = 0;
      const tokenOwner = 0;
      const to = recipientId;

      it('reverts', async function () {
        const deadline = new BN(10);
        const signature = signFromData(spender, tokenOwner, to, amount, deadline);
        await expectRevert(


          this.token.transferFromBWO(tokenOwner, to, amount, deadline, signature, {
            from: spenderAddr
          }),
          'Cash: approve from the zero Id',
        );
      });
    });
  });

  describe('approveBWO', function () {
    shouldBehaveLikeCash20ApproveBWO(errorPrefix, initialHolder, initialHolderId, recipientId, initialSupply,
      function (ownerAddr, owner, spender, amount) {

        const deadline = new BN(10);
        const signature = signData(owner, spender, amount, deadline)
        return this.token.approveBWO(owner, spender, amount, deadline, signature, {
          from: this.BWO
        });
      },
    );
  });
}

function shouldBehaveLikeCash20TransferBWO(errorPrefix, fromAddr, from, to, balance, transfer) {
  describe('when the recipientId is not the zero id', function () {
    describe('when the sender does not have enough balance', function () {
      const amount = balance.addn(1);

      it('reverts', async function () {
        await expectRevert(transfer.call(this, fromAddr, from, to, amount),
          `${errorPrefix}: transfer amount exceeds balance`,
        );
      });
    });

    describe('when the sender transfers all balance', function () {
      const amount = balance;

      it('transfers the requested amount', async function () {
        await transfer.call(this, fromAddr, from, to, amount);

        expect(await this.token.balanceOfId(from)).to.be.bignumber.equal('0');

        expect(await this.token.balanceOfId(to)).to.be.bignumber.equal(amount);
      });

      it('emits a transfer by id event', async function () {
        expectEvent(
          await transfer.call(this, fromAddr, from, to, amount),
          'TransferBWO', {
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
        await transfer.call(this, fromAddr, from, to, amount);

        expect(await this.token.balanceOfId(from)).to.be.bignumber.equal(balance);

        expect(await this.token.balanceOfId(to)).to.be.bignumber.equal('0');
      });

      it('emits a transfer by id event', async function () {
        expectEvent(
          await transfer.call(this, fromAddr, from, to, amount),
          'TransferBWO', {
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
      await expectRevert(transfer.call(this, fromAddr, from, 0, balance),
        `${errorPrefix}: transfer to the zero Id`,
      );
    });
  });
}

function shouldBehaveLikeCash20ApproveBWO(errorPrefix, ownerAddr, owner, spender, supply, approve) {
  describe('when the spender is not the zero Id', function () {
    describe('when the sender has enough balance', function () {
      const amount = supply;

      it('emits an approval by id event', async function () {
        expectEvent(
          await approve.call(this, ownerAddr, owner, spender, amount),
          'ApprovalBWO', {
            owner: owner,
            spender: spender,
            value: amount
          },
        );
      });

      describe('when there was no approved amount before', function () {
        it('approves the requested amount', async function () {
          await approve.call(this, ownerAddr, owner, spender, amount);

          expect(await this.token.allowanceId(owner, spender)).to.be.bignumber.equal(amount);
        });
      });

      describe('when the spender had an approved amount', function () {
        beforeEach(async function () {
          await approve.call(this, ownerAddr, owner, spender, new BN(1));
        });

        it('approves the requested amount and replaces the previous one', async function () {
          await approve.call(this, ownerAddr, owner, spender, amount);

          expect(await this.token.allowanceId(owner, spender)).to.be.bignumber.equal(amount);
        });
      });
    });

    describe('when the sender does not have enough balance', function () {
      const amount = supply.addn(1);

      it('emits an approval by Id event', async function () {
        expectEvent(
          await approve.call(this, ownerAddr, owner, spender, amount),
          'ApprovalBWO', {
            owner: owner,
            spender: spender,
            value: amount
          },
        );
      });

      describe('when there was no approved amount before', function () {
        it('approves the requested amount', async function () {
          await approve.call(this, ownerAddr, owner, spender, amount);

          expect(await this.token.allowanceId(owner, spender)).to.be.bignumber.equal(amount);
        });
      });

      describe('when the spender had an approved amount', function () {
        beforeEach(async function () {
          await approve.call(this, ownerAddr, owner, spender, new BN(1));
        });

        it('approves the requested amount and replaces the previous one', async function () {
          await approve.call(this, ownerAddr, owner, spender, amount);

          expect(await this.token.allowanceId(owner, spender)).to.be.bignumber.equal(amount);
        });
      });
    });
  });

  describe('when the spender is the zero address', function () {
    it('reverts', async function () {
      await expectRevert(approve.call(this, ownerAddr, owner, 0, supply),
        `${errorPrefix}: approve to the zero Id`,
      );
    });
  });
}

function signData(from, to, value, deadline) {
  const nonce = this.token.getNonce(from);
  const chainId = this.chainId;
  const verifyingContract = this.token.address;
  const name = this.tokenName;
  const message = {
    args: [from, to, value, nonce, deadline],
  };

  const data = {
    types: {
      EIP712Domain,
      BWO: [{
        name: 'args',
        type: 'uint256[]'
      }, ],
    },
    domain: {
      name,
      version,
      chainId,
      verifyingContract
    },
    primaryType: 'BWO',
    message,
  };

  const signature = ethSigUtil.signTypedMessage(this.wallet.getPrivateKey(), {
    data
  });

  return signature;
}

function signFromData(spender, from, to, value, deadline) {
  const nonce = this.token.getNonce(spender);
  const chainId = this.chainId;
  const verifyingContract = this.token.address;
  const name = this.tokenName;
  const message = {
    args: [spender, from, to, value, nonce, deadline],
  };

  const data = {
    types: {
      EIP712Domain,
      BWO: [{
        name: 'args',
        type: 'uint256[]'
      }, ],
    },
    domain: {
      name,
      version,
      chainId,
      verifyingContract
    },
    primaryType: 'BWO',
    message,
  };

  const signature = ethSigUtil.signTypedMessage(this.wallet.getPrivateKey(), {
    data
  });

  return signature;
}

module.exports = {
  shouldBehaveLikeCash20BWO,
  shouldBehaveLikeCash20TransferBWO,
  shouldBehaveLikeCash20ApproveBWO,
};