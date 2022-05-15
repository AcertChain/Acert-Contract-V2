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


function shouldBehaveLikeCash20(errorPrefix, initialSupply, initialHolder, initialHolderId, recipient, recipientId, anotherAccount, anotherAccountId) {
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

  describe('transferCash', function () {
    shouldBehaveLikeCash20Transfer(errorPrefix, initialHolder, initialHolderId, recipientId, initialSupply,
      function (fromaddr, from, to, value) {
        return this.token.transferCash(from, to, value, {
          from: fromaddr
        });
      },
    );
  });

  describe('transfer from by id', function () {
    const spender = recipientId;
    const spenderAddr = recipient;

    describe('when the token owner is not the zero id', function () {
      const tokenOwner = initialHolderId;
      const tokenOwnerAddr = initialHolder;

      describe('when the recipientId is not the zero id', function () {
        const to = anotherAccountId;

        describe('when the spender has enough allowance', function () {
          beforeEach(async function () {
            await this.token.approveId(initialHolderId, spender, initialSupply, {
              from: initialHolder
            });
          });

          describe('when the token owner has enough balance', function () {
            const amount = initialSupply;

            it('transfers the requested amount', async function () {
              await this.token.transferFromCash(tokenOwner, to, amount, {
                from: spenderAddr
              });

              expect(await this.token.balanceOfId(tokenOwner)).to.be.bignumber.equal('0');

              expect(await this.token.balanceOfId(to)).to.be.bignumber.equal(amount);
            });

            it('decreases the spender allowance', async function () {
              await this.token.transferFromCash(tokenOwner, to, amount, {
                from: spenderAddr
              });

              expect(await this.token.allowanceId(tokenOwner, spender)).to.be.bignumber.equal('0');
            });

            it('emits a transfer by id event', async function () {
              expectEvent(
                await this.token.transferFromCash(tokenOwner, to, amount, {
                  from: spenderAddr
                }),
                'TransferId', {
                  from: tokenOwner,
                  to: to,
                  value: amount
                },
              );
            });

            it('emits an approval by id event', async function () {
              expectEvent(
                await this.token.transferFromCash(tokenOwner, to, amount, {
                  from: spenderAddr
                }),
                'ApprovalId', {
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
              await this.token.transferCash(tokenOwner, to, 1, {
                from: tokenOwnerAddr
              });
            });

            it('reverts', async function () {
              await expectRevert(
                this.token.transferFromCash(tokenOwner, to, amount, {
                  from: spenderAddr
                }),
                `${errorPrefix}: transfer amount exceeds balance`,
              );
            });
          });
        });

        describe('when the spender does not have enough allowance', function () {
          const allowance = initialSupply.subn(1);

          beforeEach(async function () {
            await this.token.approveId(tokenOwner, spender, allowance, {
              from: tokenOwnerAddr
            });
          });

          describe('when the token owner has enough balance', function () {
            const amount = initialSupply;

            it('reverts', async function () {
              await expectRevert(
                this.token.transferFromCash(tokenOwner, to, amount, {
                  from: spenderAddr
                }),
                `${errorPrefix}: insufficient allowance`,
              );
            });
          });

          describe('when the token owner does not have enough balance', function () {
            const amount = allowance;

            beforeEach('reducing balance', async function () {
              await this.token.transferCash(tokenOwner, to, 2, {
                from: tokenOwnerAddr
              });
            });

            it('reverts', async function () {
              await expectRevert(
                this.token.transferFromCash(tokenOwner, to, amount, {
                  from: spenderAddr
                }),
                `${errorPrefix}: transfer amount exceeds balance`,
              );
            });
          });
        });

        describe('when the spender has unlimited allowance', function () {
          beforeEach(async function () {
            await this.token.approveId(initialHolderId, spender, MAX_UINT256, {
              from: initialHolder
            });
          });

          it('does not decrease the spender allowance', async function () {
            await this.token.transferFromCash(tokenOwner, to, 1, {
              from: spenderAddr
            });

            expect(await this.token.allowanceId(tokenOwner, spender)).to.be.bignumber.equal(MAX_UINT256);
          });

          it('does not emit an approval by id event', async function () {
            expectEvent.notEmitted(
              await this.token.transferFromCash(tokenOwner, to, 1, {
                from: spenderAddr
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
          await this.token.approveId(tokenOwner, spender, amount, {
            from: tokenOwnerAddr
          });
        });

        it('reverts', async function () {
          await expectRevert(this.token.transferFromCash(
            tokenOwner, to, amount, {
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
        await expectRevert(
          this.token.transferFromCash(tokenOwner, to, amount, {
            from: spenderAddr
          }),
          'Cash: approve from the zero Id',
        );
      });
    });
  });

  describe('approveId', function () {
    shouldBehaveLikeCash20Approve(errorPrefix, initialHolder, initialHolderId, recipientId, initialSupply,
      function (ownerAddr, owner, spender, amount) {
        return this.token.approveId(owner, spender, amount, {
          from: ownerAddr
        });
      },
    );
  });
}

function shouldBehaveLikeCash20Transfer(errorPrefix, fromAddr, from, to, balance, transfer) {
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
          'TransferId', {
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
          'TransferId', {
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

function shouldBehaveLikeCash20Approve(errorPrefix, ownerAddr, owner, spender, supply, approve) {
  describe('when the spender is not the zero Id', function () {
    describe('when the sender has enough balance', function () {
      const amount = supply;

      it('emits an approval by id event', async function () {
        expectEvent(
          await approve.call(this, ownerAddr, owner, spender, amount),
          'ApprovalId', {
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
          'ApprovalId', {
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

module.exports = {
  shouldBehaveLikeCash20,
  shouldBehaveLikeCash20Transfer,
  shouldBehaveLikeCash20Approve,
};