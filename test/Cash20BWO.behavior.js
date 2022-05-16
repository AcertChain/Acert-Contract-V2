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


function shouldBehaveLikeCash20BWO(errorPrefix, initialSupply, initialHolder, initialHolderId, recipient, recipientId, anotherAccount, anotherAccountId, BWOKey,receiptKey) {

  describe('total supply', function () {
    it('returns the total amount of tokens', async function () {
      expect(await this.token.totalSupply()).to.be.bignumber.equal(initialSupply.mul(new BN(2)));
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
    shouldBehaveLikeCash20TransferBWO(errorPrefix, initialHolderId, recipientId, initialSupply, BWOKey,
      function (from, to, value, nonce, key) {
        
        const signature = signData(this.chainId, this.token.address, this.tokenName, key, this.tokenVersion, from, to, value, deadline, nonce);
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
            const nonce = await this.token.getNonce(initialHolderId);
            
            const signature = signData(this.chainId, this.token.address, this.tokenName, BWOKey, this.tokenVersion, initialHolderId, spender, initialSupply, deadline, nonce);
            await this.token.approveBWO(initialHolderId, spender, initialSupply, deadline, signature, {
              from: this.BWO
            });
          });

          describe('when the token owner has enough balance', function () {
            const amount = initialSupply;

            it('transfers the requested amount', async function () {
              const nonce = await this.token.getNonce(spender);
              
              const signature = signFromData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion, spender, tokenOwner, to, amount, deadline, nonce);
              await this.token.transferFromBWO(spender, tokenOwner, to, amount, deadline, signature, {
                from: this.BWO
              });

              expect(await this.token.balanceOfId(tokenOwner)).to.be.bignumber.equal('0');

              expect(await this.token.balanceOfId(to)).to.be.bignumber.equal(amount);
            });

            it('decreases the spender allowance', async function () {
              const nonce = await this.token.getNonce(spender);

              
              const signature = signFromData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion, spender, tokenOwner, to, amount, deadline, nonce);
              await this.token.transferFromBWO(spender, tokenOwner, to, amount, deadline, signature, {
                from: this.BWO
              });

              expect(await this.token.allowanceId(tokenOwner, spender)).to.be.bignumber.equal('0');
            });

            it('emits a transfer by id event', async function () {
              const nonce = await this.token.getNonce(spender);

              
              const signature = signFromData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion, spender, tokenOwner, to, amount, deadline, nonce);
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
              const nonce = await this.token.getNonce(spender);

              
              const signature = signFromData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion, spender, tokenOwner, to, amount, deadline, nonce);

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
              const nonce = await this.token.getNonce(tokenOwner);

              
              const signature = signData(this.chainId, this.token.address, this.tokenName, BWOKey, this.tokenVersion, tokenOwner, to, 1, deadline, nonce);
              await this.token.transferBWO(tokenOwner, to, 1, deadline, signature, {
                from: this.BWO
              });
            });

            it('reverts', async function () {
              const nonce = await this.token.getNonce(spender);

              
              const signature = signFromData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion, spender, tokenOwner, to, amount, deadline, nonce);

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
            const nonce = await this.token.getNonce(tokenOwner);

            
            const signature = signData(this.chainId, this.token.address, this.tokenName, BWOKey, this.tokenVersion, tokenOwner, spender, allowance, deadline, nonce);
            await this.token.approveBWO(tokenOwner, spender, allowance, deadline, signature, {
              from: this.BWO
            });
          });

          describe('when the token owner has enough balance', function () {
            const amount = initialSupply;
            
            it('reverts', async function () {
              const nonce = await this.token.getNonce(spender);
              const signature = signFromData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion, spender, tokenOwner, to, amount, deadline, nonce);

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

            beforeEach('reducing balance', async function () {
              const nonce = await this.token.getNonce(tokenOwner);
              
              const signature = signData(this.chainId, this.token.address, this.tokenName, BWOKey, this.tokenVersion, tokenOwner, to, 2, deadline, nonce);

              await this.token.transferBWO(tokenOwner, to, 2, deadline, signature, {
                from: this.BWO
              });
            });

            it('reverts', async function () {
              
              const nonce = await this.token.getNonce(spender);
              const signature = signFromData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion, spender, tokenOwner, to, amount, deadline, nonce);
              await expectRevert(
                this.token.transferFromBWO(spender, tokenOwner, to, amount, deadline, signature, {
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
            const signature = signData(this.chainId, this.token.address, this.tokenName, BWOKey, this.tokenVersion, initialHolderId, spender, MAX_UINT256, deadline, nonce);

            await this.token.approveBWO(initialHolderId, spender, MAX_UINT256, deadline, signature, {
              from: this.BWO
            });
          });

          it('does not decrease the spender allowance', async function () {
            
            const nonce = await this.token.getNonce(spender);

            const signature = signFromData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion, spender, tokenOwner, to, 1, deadline, nonce);

            await this.token.transferFromBWO(spender, tokenOwner, to, 1, deadline, signature, {
              from: this.BWO
            });

            expect(await this.token.allowanceId(tokenOwner, spender)).to.be.bignumber.equal(MAX_UINT256);
          });

          it('does not emit an approval by id event', async function () {
            
            const nonce = await this.token.getNonce(spender);

            const signature = signFromData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion, spender, tokenOwner, to, 1, deadline, nonce);

            expectEvent.notEmitted(
              await this.token.transferFromBWO(spender, tokenOwner, to, 1, deadline, signature, {
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
          
          const nonce = await this.token.getNonce(tokenOwner);
          const signature = signData(this.chainId, this.token.address, this.tokenName, BWOKey, this.tokenVersion, tokenOwner, spender, amount, deadline, nonce);
          await this.token.approveBWO(tokenOwner, spender, amount, deadline, signature, {
            from: this.BWO
          });
        });

        it('reverts', async function () {
          
          const nonce = await this.token.getNonce(spender);
          const signature = signFromData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion, spender, tokenOwner, to, amount, deadline, nonce);

          await expectRevert(this.token.transferFromBWO(spender,
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
        const signature = signFromData(this.chainId, this.token.address, this.tokenName, receiptKey, this.tokenVersion, spender, tokenOwner, to, amount, deadline, nonce);
        await expectRevert(
          this.token.transferFromBWO(spender, tokenOwner, to, amount, deadline, signature, {
            from: this.BWO
          }),
          'Cash: approve from the zero Id',
        );
      });
    });
  });

  describe('approveBWO', function () {
    shouldBehaveLikeCash20ApproveBWO(errorPrefix, initialHolderId, recipientId, initialSupply, BWOKey,
      function (owner, spender, amount, nonce, key) {
        
        const signature = signData(this.chainId, this.token.address, this.tokenName, key, this.tokenVersion, owner, spender, amount, deadline, nonce)
        return this.token.approveBWO(owner, spender, amount, deadline, signature, {
          from: this.BWO
        });
      },
    );
  });
}

function shouldBehaveLikeCash20TransferBWO(errorPrefix, from, to, balance, key, transfer) {
  describe('when the recipientId is not the zero id', function () {
    describe('when the sender does not have enough balance', function () {
      const amount = balance.addn(1);

      it('reverts', async function () {
        const nonce = await this.token.getNonce(from);
        await expectRevert(transfer.call(this, from, to, amount, nonce, key),
          `${errorPrefix}: transfer amount exceeds balance`,
        );
      });
    });

    describe('when the sender transfers all balance', function () {
      const amount = balance;

      it('transfers the requested amount', async function () {
        const nonce = await this.token.getNonce(from);

        await transfer.call(this, from, to, amount, nonce, key);

        expect(await this.token.balanceOfId(from)).to.be.bignumber.equal('0');

        expect(await this.token.balanceOfId(to)).to.be.bignumber.equal(amount);
      });

      it('emits a transfer by id event', async function () {
        const nonce = await this.token.getNonce(from);
        expectEvent(
          await transfer.call(this, from, to, amount, nonce, key),
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
        const nonce = await this.token.getNonce(from);

        await transfer.call(this, from, to, amount, nonce, key);

        expect(await this.token.balanceOfId(from)).to.be.bignumber.equal(balance);

        expect(await this.token.balanceOfId(to)).to.be.bignumber.equal('0');
      });

      it('emits a transfer by id event', async function () {
        const nonce = await this.token.getNonce(from);

        expectEvent(
          await transfer.call(this, from, to, amount, nonce, key),
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
      const nonce = await this.token.getNonce(from);
      await expectRevert(transfer.call(this, from, 0, balance, nonce, key),
        `${errorPrefix}: transfer to the zero Id`,
      );
    });
  });
}

function shouldBehaveLikeCash20ApproveBWO(errorPrefix, owner, spender, supply, key, approve) {
  describe('when the spender is not the zero Id', function () {
    describe('when the sender has enough balance', function () {
      const amount = supply;

      it('emits an approval by id event', async function () {
        const nonce = await this.token.getNonce(owner);
        expectEvent(
          await approve.call(this, owner, spender, amount, nonce, key),
          'ApprovalBWO', {
            owner: owner,
            spender: spender,
            value: amount
          },
        );
      });

      describe('when there was no approved amount before', function () {
        it('approves the requested amount', async function () {
          const nonce = await this.token.getNonce(owner);
          await approve.call(this, owner, spender, amount, nonce, key);

          expect(await this.token.allowanceId(owner, spender)).to.be.bignumber.equal(amount);
        });
      });

      describe('when the spender had an approved amount', function () {
        beforeEach(async function () {
          const nonce = await this.token.getNonce(owner);

          await approve.call(this, owner, spender, new BN(1), nonce, key);
        });

        it('approves the requested amount and replaces the previous one', async function () {
          const nonce = await this.token.getNonce(owner);

          await approve.call(this, owner, spender, amount, nonce, key);

          expect(await this.token.allowanceId(owner, spender)).to.be.bignumber.equal(amount);
        });
      });
    });

    describe('when the sender does not have enough balance', function () {
      const amount = supply.addn(1);

      it('emits an approval by Id event', async function () {
        const nonce = await this.token.getNonce(owner);

        expectEvent(
          await approve.call(this, owner, spender, amount, nonce, key),
          'ApprovalBWO', {
            owner: owner,
            spender: spender,
            value: amount
          },
        );
      });

      describe('when there was no approved amount before', function () {
        it('approves the requested amount', async function () {
          const nonce = await this.token.getNonce(owner);

          await approve.call(this, owner, spender, amount, nonce, key);

          expect(await this.token.allowanceId(owner, spender)).to.be.bignumber.equal(amount);
        });
      });

      describe('when the spender had an approved amount', function () {
        beforeEach(async function () {
          const nonce = await this.token.getNonce(owner);
          await approve.call(this, owner, spender, new BN(1), nonce, key);
        });

        it('approves the requested amount and replaces the previous one', async function () {
          const nonce = await this.token.getNonce(owner);
          await approve.call(this, owner, spender, amount, nonce, key);

          expect(await this.token.allowanceId(owner, spender)).to.be.bignumber.equal(amount);
        });
      });
    });
  });

  describe('when the spender is the zero address', function () {
    it('reverts', async function () {
      const nonce = await this.token.getNonce(owner);
      await expectRevert(approve.call(this, owner, 0, supply, nonce, key),
        `${errorPrefix}: approve to the zero Id`,
      );
    });
  });
}

function signData(chainId, verifyingContract, name, key, version, from, to, value, deadline, nonce) {
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

function signFromData(chainId, verifyingContract, name, key, version, spender, from, to, value, deadline, nonce) {
  const data = {
    types: {
      EIP712Domain,
      BWO: [{
          name: 'spender',
          type: 'uint256'
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