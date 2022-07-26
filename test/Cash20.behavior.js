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


function shouldBehaveLikeCash20(errorPrefix, initialSupply, initialHolder, initialHolderId, recipient, recipientId, anotherAccount, anotherAccountId) {
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
            await this.token.approveCash(initialHolderId, spenderAddr, initialSupply, {
              from: initialHolder
            });
          });

          describe('when the token owner has enough balance', function () {
            const amount = initialSupply;

            it('transfers the requested amount', async function () {
              await this.token.transferCash(tokenOwner, to, amount, {
                from: spenderAddr
              });

              expect(await this.token.balanceOfCash(tokenOwner)).to.be.bignumber.equal('0');

              expect(await this.token.balanceOfCash(to)).to.be.bignumber.equal(amount);
            });

            it('decreases the spender allowance', async function () {
              await this.token.transferCash(tokenOwner, to, amount, {
                from: spenderAddr
              });

              expect(await this.token.allowanceCash(tokenOwner, spenderAddr)).to.be.bignumber.equal('0');
            });

            it('emits a transfer by id event', async function () {
              expectEvent(
                await this.token.transferCash(tokenOwner, to, amount, {
                  from: spenderAddr
                }),
                'TransferCash', {
                from: tokenOwner,
                to: to,
                value: amount
              },
              );
            });

            it('emits an approval by id event', async function () {
              expectEvent(
                await this.token.transferCash(tokenOwner, to, amount, {
                  from: spenderAddr
                }),
                'ApprovalCash', {
                owner: tokenOwner,
                spender: spenderAddr,
                value: await this.token.allowanceCash(tokenOwner, spenderAddr)
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
                this.token.transferCash(tokenOwner, to, amount, {
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
            await this.token.approveCash(tokenOwner, spenderAddr, allowance, {
              from: tokenOwnerAddr
            });
          });

          describe('when the token owner has enough balance', function () {
            const amount = initialSupply;

            it('reverts', async function () {
              await expectRevert(
                this.token.transferCash(tokenOwner, to, amount, {
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
                this.token.transferCash(tokenOwner, to, amount, {
                  from: spenderAddr
                }),
                `${errorPrefix}: transfer amount exceeds balance`,
              );
            });
          });
        });

        describe('when the spender has unlimited allowance', function () {
          beforeEach(async function () {
            await this.token.approveCash(initialHolderId, spenderAddr, MAX_UINT256, {
              from: initialHolder
            });
          });

          it('does not decrease the spender allowance', async function () {
            await this.token.transferCash(tokenOwner, to, 1, {
              from: spenderAddr
            });

            expect(await this.token.allowanceCash(tokenOwner, spenderAddr)).to.be.bignumber.equal(MAX_UINT256);
          });

          it('does not emit an approval by id event', async function () {
            expectEvent.notEmitted(
              await this.token.transferCash(tokenOwner, to, 1, {
                from: spenderAddr
              }),
              'ApprovalCash',
            );
          });
        });
      });

      describe('when the recipientId is the zero Id', function () {
        const amount = initialSupply;
        const to = 0;

        beforeEach(async function () {
          await this.token.approveCash(tokenOwner, spenderAddr, amount, {
            from: tokenOwnerAddr
          });
        });

        it('reverts', async function () {
          await expectRevert(this.token.transferCash(tokenOwner, to, amount, {
            from: spenderAddr
          }), `${errorPrefix}: transfer to the zero Id`);
        });
      });

      describe('when the recipientId is the not exist Id', function () {
        const amount = initialSupply;
        const to = 1000;

        beforeEach(async function () {
          await this.token.approveCash(tokenOwner, spenderAddr, amount, {
            from: tokenOwnerAddr
          });
        });

        it('reverts', async function () {
          await expectRevert(this.token.transferCash(tokenOwner, to, amount, {
            from: spenderAddr
          }), `${errorPrefix}: to account is not exist`);
        });
      });
    });

    describe('when the token owner is the zero id', function () {
      const amount = 0;
      const tokenOwner = 0;
      const to = recipientId;

      it('reverts', async function () {
        await expectRevert(
          this.token.transferCash(tokenOwner, to, amount, {
            from: spenderAddr
          }),
          'Cash: from is the zero Id',
        );
      });
    });
  });

  describe('isTrust safe conract and trust world', function () {

    beforeEach('set safe contract and trust world', async function () {
      await this.world.addSafeContract(recipient, "");
      await this.world.trustWorld({
        from: initialHolder
      });
    });

    shouldBehaveLikeCash20IsTrust(initialSupply, initialHolder, initialHolderId, recipient, anotherAccount, anotherAccountId);

  });

  describe('isTrust trust contract', function () {

    beforeEach('set safe contract and trust world', async function () {
      await this.world.addSafeContract(recipient, "");
      await this.world.trustContract(recipient, {
        from: initialHolder
      });
    });
    shouldBehaveLikeCash20IsTrust(initialSupply, initialHolder, initialHolderId, recipient, anotherAccount, anotherAccountId);
  });

  describe('approveCash', function () {
    shouldBehaveLikeCash20Approve(errorPrefix, initialHolder, initialHolderId, recipient, recipientId, initialSupply,
      function (ownerAddr, owner, spender, amount) {
        return this.token.approveCash(owner, spender, amount, {
          from: ownerAddr
        });
      },
    );
  });
}

function shouldBehaveLikeCash20IsTrust(initialSupply, initialHolder, initialHolderId, spenderAddr, anotherAccount, anotherAccountId) {
  const tokenOwner = initialHolderId;
  const tokenOwnerAddr = initialHolder;

  const amount = initialSupply;
  const to = anotherAccountId;
  const toAddr = anotherAccount;

  describe('allowance ', function () {
    it('decreases the spender allowance', async function () {
      await this.token.transferCash(tokenOwner, to, amount, {
        from: spenderAddr
      });
      expect(await this.token.allowanceCash(tokenOwner, spenderAddr)).to.be.bignumber.equal(MAX_UINT256);
    });
  });

  describe('allowanceCash ', function () {
    it('decreases the spender allowance', async function () {
      await this.token.transferCash(tokenOwner, to, amount, {
        from: spenderAddr
      });

      expect(await this.token.allowanceCash(tokenOwner, spenderAddr)).to.be.bignumber.equal(MAX_UINT256);
    });

  });

  describe('transferFrom ', function () {
    it('transfers the requested amount', async function () {
      await this.token.transferFrom(tokenOwnerAddr, toAddr, amount, {
        from: spenderAddr
      });

      expect(await this.token.balanceOfCash(tokenOwner)).to.be.bignumber.equal('0');
      expect(await this.token.balanceOfCash(to)).to.be.bignumber.equal(amount);
    });
  });

  describe('transferCash ', function () {
    it('transfers the requested amount', async function () {
      await this.token.transferCash(tokenOwner, to, amount, {
        from: spenderAddr
      });

      expect(await this.token.balanceOfCash(tokenOwner)).to.be.bignumber.equal('0');
      expect(await this.token.balanceOfCash(to)).to.be.bignumber.equal(amount);
    });
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

        expect(await this.token.balanceOfCash(from)).to.be.bignumber.equal('0');

        expect(await this.token.balanceOfCash(to)).to.be.bignumber.equal(amount);
      });

      it('emits a transfer by id event', async function () {
        expectEvent(
          await transfer.call(this, fromAddr, from, to, amount),
          'TransferCash', {
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

        expect(await this.token.balanceOfCash(from)).to.be.bignumber.equal(balance);

        expect(await this.token.balanceOfCash(to)).to.be.bignumber.equal('0');
      });

      it('emits a transfer by id event', async function () {
        expectEvent(
          await transfer.call(this, fromAddr, from, to, amount),
          'TransferCash', {
          from,
          to,
          value: amount
        },
        );
      });
    });

    describe('when the sender is Freeze', function () {
      it('reverts', async function () {
        await this.Metaverse.freezeAccount(from, {
          from: fromAddr
        });
        await expectRevert(transfer.call(this, fromAddr, from, to, balance),
          `${errorPrefix}: transfer from is frozen`,
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

function shouldBehaveLikeCash20Approve(errorPrefix, ownerAddr, owner, spenderAddr, spender, supply, approve) {
  describe('when the spender is not the zero Id', function () {
    describe('when the sender has enough balance', function () {
      const amount = supply;

      it('emits an approval by id event', async function () {
        expectEvent(
          await approve.call(this, ownerAddr, owner, spenderAddr, amount),
          'ApprovalCash', {
          owner: owner,
          spender: spenderAddr,
          value: amount
        },
        );
      });

      describe('when there was no approved amount before', function () {
        it('approves the requested amount', async function () {
          await approve.call(this, ownerAddr, owner, spenderAddr, amount);

          expect(await this.token.allowanceCash(owner, spenderAddr)).to.be.bignumber.equal(amount);
        });
      });

      describe('when the spender had an approved amount', function () {
        beforeEach(async function () {
          await approve.call(this, ownerAddr, owner, spenderAddr, new BN(1));
        });

        it('approves the requested amount and replaces the previous one', async function () {
          await approve.call(this, ownerAddr, owner, spenderAddr, amount);

          expect(await this.token.allowanceCash(owner, spenderAddr)).to.be.bignumber.equal(amount);
        });
      });
    });

    describe('when the sender does not have enough balance', function () {
      const amount = supply.addn(1);

      it('emits an approval by Id event', async function () {
        expectEvent(
          await approve.call(this, ownerAddr, owner, spenderAddr, amount),
          'ApprovalCash', {
          owner: owner,
          spender: spenderAddr,
          value: amount
        },
        );
      });

      describe('when there was no approved amount before', function () {
        it('approves the requested amount', async function () {
          await approve.call(this, ownerAddr, owner, spenderAddr, amount);

          expect(await this.token.allowanceCash(owner, spenderAddr)).to.be.bignumber.equal(amount);
        });
      });

      describe('when the spender had an approved amount', function () {
        beforeEach(async function () {
          await approve.call(this, ownerAddr, owner, spenderAddr, new BN(1));
        });

        it('approves the requested amount and replaces the previous one', async function () {
          await approve.call(this, ownerAddr, owner, spenderAddr, amount);

          expect(await this.token.allowanceCash(owner, spenderAddr)).to.be.bignumber.equal(amount);
        });
      });
    });

    describe('when the owner is frozen', function () {
      it('reverts', async function () {
        await this.Metaverse.freezeAccount(owner, {
          from: ownerAddr
        })
        await expectRevert(approve.call(this, ownerAddr, owner, spenderAddr, supply),
          `${errorPrefix}: approve owner is frozen`,
        );
      });
    })
  });

  describe('when the spender is the zero address', function () {
    it('reverts', async function () {
      await expectRevert(approve.call(this, ownerAddr, owner, ZERO_ADDRESS, supply),
        `${errorPrefix}: approve to the zero address`,
      );
    });
  });
}

module.exports = {
  shouldBehaveLikeCash20,
  shouldBehaveLikeCash20Transfer,
  shouldBehaveLikeCash20Approve,
};