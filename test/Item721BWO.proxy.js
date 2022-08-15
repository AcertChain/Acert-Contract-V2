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
  ZERO_ADDRESS
} = constants;

const Wallet = require('ethereumjs-wallet').default;
const ethSigUtil = require('eth-sig-util');
const {
  web3
} = require('hardhat');

const {
  shouldSupportInterfaces
} = require('./SupportsInterface.behavior');

const ERC721ReceiverMock = artifacts.require('ERC721ReceiverMock');

const Error = ['None', 'RevertWithMessage', 'RevertWithoutMessage', 'Panic']
  .reduce((acc, entry, idx) => Object.assign({
    [entry]: idx
  }, acc), {});

const firstTokenId = new BN('5042');
const secondTokenId = new BN('79217');
const nonExistentTokenId = new BN('13');
const fourthTokenId = new BN(4);

const ZERO = new BN(0);

const RECEIVER_MAGIC_VALUE = '0x150b7a02';


const ownerW = Wallet.generate();
const approvedW = Wallet.generate();
const anotherApprovedW = Wallet.generate();
const operatorW = Wallet.generate();
const otherW = Wallet.generate();

const owner = ownerW.getAddressString();
const approved = approvedW.getAddressString();
const anotherApproved = anotherApprovedW.getAddressString();
const operator = operatorW.getAddressString();
const other = otherW.getAddressString();

const ownerId = new BN(1);
const approvedId = new BN(2);
const anotherApprovedId = new BN(3);
const operatorId = new BN(4);
const otherId = new BN(5);

const accountW = Wallet.generate();
const accountWAddr = accountW.getAddressString()
const authAccount = accountW.getChecksumAddressString();

const deadline = new BN(parseInt(new Date().getTime() / 1000) + 36000);

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

function shouldBehaveLikeItem721ProxyBWO() {
  shouldSupportInterfaces([
    'ERC165',
    'ERC721',
  ]);

  context('with minted tokens', function () {
    beforeEach(async function () {
      // create account
      await this.world.getOrCreateAccountId(owner);
      await this.world.getOrCreateAccountId(approved);
      await this.world.getOrCreateAccountId(anotherApproved);
      await this.world.getOrCreateAccountId(operator);
      await this.world.getOrCreateAccountId(other);

      await this.token.mint(owner, firstTokenId);
      await this.token.mint(owner, secondTokenId);
      this.toWhom = other; // default to other for toWhom in context-dependent tests
      this.toWhomId = otherId;


      // add proxy

      const nonce = await this.Metaverse.getNonce(owner);
      const signature = signAddAuthProxyAddrBWO(this.chainId, this.Metaverse.address, "metaverse", 
      ownerW.getPrivateKey(), "1.0", ownerId, authAccount, owner, nonce, deadline);

      await this.Metaverse.addAuthProxyAddrBWO(ownerId, authAccount, owner, deadline, signature)

    });


    describe('transferBWO proxy', function () {
      const tokenId = firstTokenId;
      const data = '0x42';

      let logs = null;

      beforeEach(async function () {
        const nonce = await this.token.getNonce(authAccount);
        const signature = signData(this.chainId, this.token.address, this.tokenName,
          accountW.getPrivateKey(), this.tokenVersion, approved, tokenId, authAccount,
          deadline, nonce);

        await this.token.approveItemBWO(approved, tokenId, authAccount, deadline, signature, {
          from: this.operator
        });

        const nonceAll = await this.token.getNonce(authAccount);

        const signatureAll = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
          accountW.getPrivateKey(), this.tokenVersion, ownerId, operator, true, authAccount,
          deadline, nonceAll);

        await this.token.setApprovalForAllItemBWO(ownerId, operator, true, authAccount, deadline, signatureAll, {
          from: this.operator
        });
      });

      const transferWasSuccessful = function ({
        owner,
        tokenId,
        sender,
        nonce,
      }) {
        it('transfers the ownership of the given token ID to the given address', async function () {
          expect(await this.token.ownerOfItem(tokenId)).to.be.bignumber.equal(this.toWhomId);
        });

        it('emits a TransferItemBWO event', async function () {
          expectEvent.inLogs(logs, 'TransferItemBWO', {
            from: ownerId,
            to: this.toWhomId,
            tokenId: tokenId,
            sender: web3.utils.toChecksumAddress(sender),
          });
        });

        it('clears the approval for the token ID', async function () {
          expect(await this.token.getApproved(tokenId)).to.be.equal(ZERO_ADDRESS);
        });

        it('emits an Approval event', async function () {
          expectEvent.inLogs(logs, 'Approval', {
            owner: web3.utils.toChecksumAddress(owner),
            approved: ZERO_ADDRESS,
            tokenId: tokenId
          });
        });

        it('adjusts owners balances', async function () {
          expect(await this.token.balanceOfItem(ownerId)).to.be.bignumber.equal('1');
        });

        it('adjusts owners tokens by index', async function () {
          if (!this.token.tokenOfOwnerByIndex) return;

          expect(await this.token.tokenOfOwnerByIndex(this.toWhom, 0)).to.be.bignumber.equal(tokenId);

          expect(await this.token.tokenOfOwnerByIndex(owner, 0)).to.be.bignumber.not.equal(tokenId);
        });
      };

      const shouldTransferTokensByUsers = function (transferFunction, data) {
        context('when called by the owner', function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(authAccount);
            this.nonce = nonce;
            let signature;
            if (data == null) {
              signature = signTrasferData(this.chainId, this.token.address, this.tokenName,
                accountW.getPrivateKey(), this.tokenVersion, ownerId, this.toWhomId, tokenId, authAccount,
                deadline, nonce);
            } else {
              signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                accountW.getPrivateKey(), this.tokenVersion, ownerId, this.toWhomId, tokenId, authAccount,
                deadline, nonce, data);
            }

            ({
              logs
            } = await transferFunction.call(this, authAccount, ownerId, this.toWhomId, tokenId, signature, {
              from: this.operator
            }));

          });
          transferWasSuccessful({
            owner,
            tokenId,
            sender: accountWAddr,
          });
        });

        context('when sent to the owner', function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(authAccount);
            let signature;
            if (data == null) {
              signature = signTrasferData(this.chainId, this.token.address, this.tokenName,
                accountW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, tokenId, authAccount,
                deadline, nonce);
            } else {
              signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                accountW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, tokenId, authAccount,
                deadline, nonce, data);
            }
            ({
              logs
            } = await transferFunction.call(this, authAccount, ownerId, ownerId, tokenId, signature, {
              from: this.operator
            }));
          });

          it('keeps ownership of the token', async function () {
            expect(await this.token.ownerOfItem(tokenId)).to.be.bignumber.equal(ownerId);
          });

          it('clears the approval for the token ID', async function () {
            expect(await this.token.getApproved(tokenId)).to.be.equal(ZERO_ADDRESS);
          });

          it('emits only a transferCash event', async function () {
            expectEvent.inLogs(logs, 'TransferItemBWO', {
              from: ownerId,
              to: ownerId,
              tokenId: tokenId,
            });
          });

          it('keeps the owner balance', async function () {
            expect(await this.token.balanceOfItem(ownerId)).to.be.bignumber.equal('2');
          });

          it('keeps same tokens by index', async function () {
            if (!this.token.tokenOfOwnerByIndex) return;
            const tokensListed = await Promise.all(
              [0, 1].map(i => this.token.tokenOfOwnerByIndex(owner, i)),
            );
            expect(tokensListed.map(t => t.toNumber())).to.have.members(
              [firstTokenId.toNumber(), secondTokenId.toNumber()],
            );
          });
        });

        context('when the address of the previous owner is incorrect', function () {
          it('reverts', async function () {
            const nonce = await this.token.getNonce(authAccount);
            let signature;
            if (data == null) {

              signature = signTrasferData(this.chainId, this.token.address, this.tokenName,
                accountW.getPrivateKey(), this.tokenVersion, otherId, otherId, tokenId, authAccount,
                deadline, nonce);
            } else {
              signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                accountW.getPrivateKey(), this.tokenVersion, otherId, otherId, tokenId, authAccount,
                deadline, nonce, data);
            }


            await expectRevert(
              transferFunction.call(this, authAccount, otherId, otherId, tokenId, signature, {
                from: this.operator
              }),
              'Item: not owner or auth',
            );
          });
        });

        context('when the sender is not authorized for the token id', function () {
          it('reverts', async function () {
            const nonce = await this.token.getNonce(other);
            let signature;
            if (data == null) {
              signature = signTrasferData(this.chainId, this.token.address, this.tokenName,
                otherW.getPrivateKey(), this.tokenVersion, ownerId, otherId, tokenId, other,
                deadline, nonce);
            } else {
              signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                otherW.getPrivateKey(), this.tokenVersion, ownerId, otherId, tokenId, other,
                deadline, nonce, data);
            }
            await expectRevert(
              transferFunction.call(this, other, ownerId, otherId, tokenId, signature, {
                from: this.operator
              }),
              'Item: not owner',
            );
          });
        });

        context('when the given token ID does not exist', function () {
          it('reverts', async function () {
            const nonce = await this.token.getNonce(authAccount);
            let signature;
            if (data == null) {
              signature = signTrasferData(this.chainId, this.token.address, this.tokenName,
                accountW.getPrivateKey(), this.tokenVersion, ownerId, otherId, nonExistentTokenId, authAccount,
                deadline, nonce);
            } else {
              signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                accountW.getPrivateKey(), this.tokenVersion, ownerId, otherId, nonExistentTokenId, authAccount,
                deadline, nonce, data);
            }

            await expectRevert(
              transferFunction.call(this, authAccount, ownerId, otherId, nonExistentTokenId, signature, {
                from: this.operator
              }),
              'Item: owner query for nonexistent token',
            );
          });
        });

        context('when the address to transfer the token to is the zero id', function () {
          it('reverts', async function () {
            const nonce = await this.token.getNonce(authAccount);
            let signature;
            if (data == null) {
              signature = signTrasferData(this.chainId, this.token.address, this.tokenName,
                accountW.getPrivateKey(), this.tokenVersion, ownerId, ZERO, tokenId, authAccount,
                deadline, nonce);
            } else {
              signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                accountW.getPrivateKey(), this.tokenVersion, ownerId, ZERO, tokenId, authAccount,
                deadline, nonce, data);
            }

            await expectRevert(
              transferFunction.call(this, authAccount, ownerId, ZERO, tokenId, signature, {
                from: this.operator
              }),
              'Item: transfer to the zero id',
            );
          });
        });
      };

      describe('via transferFromItemBWO', function () {
        shouldTransferTokensByUsers(function (sender, fromId, toId, tokenId, signature, opts) {
          return this.token.transferFromItemBWO(fromId, toId, tokenId, sender, deadline, signature, opts);
        }, null);
      });

      describe('via safeTransferFromItemBWO', function () {
        const safeTransferFromItemBWOWithData = function (sender, fromId, toId, tokenId, signature, opts) {
          return this.token.methods['safeTransferFromItemBWO(uint256,uint256,uint256,bytes,address,uint256,bytes)'](fromId, toId, tokenId, data, sender, deadline, signature, opts);
        };

   

        const shouldTransferSafely = function (transferFun, data) {
          describe('to a user account', function () {
            shouldTransferTokensByUsers(transferFun, data);
          });

          describe('to a valid receiver contract', function () {
            beforeEach(async function () {
              this.receiver = await ERC721ReceiverMock.new(RECEIVER_MAGIC_VALUE, Error.None);
              this.toWhom = this.receiver.address;
              await this.world.getOrCreateAccountId(this.receiver.address);
              this.receiverId = new BN(await this.world.getAccountIdByAddress(this.receiver.address));
            });

            shouldTransferTokensByUsers(transferFun, data);

            it('calls onERC721Received', async function () {
              const nonce = await this.token.getNonce(authAccount);

              const signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                accountW.getPrivateKey(), this.tokenVersion, ownerId, this.receiverId, tokenId, authAccount,
                deadline, nonce, data);

              const receipt = await transferFun.call(this, authAccount, ownerId, this.receiverId, tokenId, signature, {
                from: this.operator
              });

              await expectEvent.inTransaction(receipt.tx, ERC721ReceiverMock, 'Received', {
                operator: this.operator,
                from: web3.utils.toChecksumAddress(owner),
                tokenId: tokenId,
                data: data,
              });
            });

            describe('with an invalid token id', function () {
              it('reverts', async function () {
                const nonce = await this.token.getNonce(authAccount);
                const signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                  accountW.getPrivateKey(), this.tokenVersion, ownerId, this.receiverId, nonExistentTokenId, authAccount,
                  deadline, nonce, data);

                await expectRevert(
                  transferFun.call(
                    this,
                    authAccount,
                    ownerId,
                    this.receiverId,
                    nonExistentTokenId, signature, {
                      from: this.operator
                    },
                  ),
                  'Item: owner query for nonexistent token',
                );
              });
            });
          });
        };

        describe('with data', function () {
          shouldTransferSafely(safeTransferFromItemBWOWithData, data);
        });

        describe('to a receiver contract returning unexpected value', function () {
          it('reverts', async function () {
            const invalidReceiver = await ERC721ReceiverMock.new('0x42', Error.None);
            await this.world.getOrCreateAccountId(invalidReceiver.address);
            const invalidReceiverId = new BN(await this.world.getAccountIdByAddress(invalidReceiver.address));
            const nonce = await this.token.getNonce(authAccount);
            const signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, ownerId, invalidReceiverId, tokenId, authAccount,
              deadline, nonce, '0x');

            await expectRevert(
              this.token.safeTransferFromItemBWO(ownerId, invalidReceiverId, tokenId, '0x', authAccount, deadline, signature, {
                from: this.operator
              }),
              'Item: transfer to non ERC721Receiver implementer',
            );
          });
        });

        describe('to a receiver contract that reverts with message', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.new(RECEIVER_MAGIC_VALUE, Error.RevertWithMessage);
            await this.world.getOrCreateAccountId(revertingReceiver.address);
            const revertingReceiverId = new BN(await this.world.getAccountIdByAddress(revertingReceiver.address));

            const nonce = await this.token.getNonce(authAccount);
            const signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, ownerId, revertingReceiverId, tokenId, authAccount,
              deadline, nonce, '0x');

            await expectRevert(
              this.token.safeTransferFromItemBWO(ownerId, revertingReceiverId, tokenId, '0x', authAccount, deadline, signature, {
                from: this.operator
              }),
              'ERC721ReceiverMock: reverting',
            );
          });
        });

        describe('to a receiver contract that reverts without message', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.new(RECEIVER_MAGIC_VALUE, Error.RevertWithoutMessage);
            await this.world.getOrCreateAccountId(revertingReceiver.address);
            const revertingReceiverId = new BN(await this.world.getAccountIdByAddress(revertingReceiver.address));
            const nonce = await this.token.getNonce(authAccount);
            const signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, ownerId, revertingReceiverId, tokenId, authAccount,
              deadline, nonce, '0x');

            await expectRevert(
              this.token.safeTransferFromItemBWO(ownerId, revertingReceiverId, tokenId, '0x', authAccount, deadline, signature, {
                from: this.operator
              }),
              'Item: transfer to non ERC721Receiver implementer',
            );
          });
        });

        describe('to a receiver contract that panics', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.new(RECEIVER_MAGIC_VALUE, Error.Panic);
            await this.world.getOrCreateAccountId(revertingReceiver.address);
            const revertingReceiverId = new BN(await this.world.getAccountIdByAddress(revertingReceiver.address));

            const nonce = await this.token.getNonce(authAccount);
            const signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, ownerId, revertingReceiverId, tokenId, authAccount,
              deadline, nonce, '0x');

            await expectRevert.unspecified(
              this.token.safeTransferFromItemBWO(ownerId, revertingReceiverId, tokenId, '0x', authAccount, deadline, signature, {
                from: this.operator
              }),
            );
          });
        });

        describe('to a contract that does not implement the required function', function () {
          it('reverts', async function () {
            const nonReceiver = this.token;
            await this.world.getOrCreateAccountId(nonReceiver.address);
            const nonReceiverId = new BN(await this.world.getAccountIdByAddress(nonReceiver.address));
            const nonce = await this.token.getNonce(authAccount);
            const signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, ownerId, nonReceiverId, tokenId, authAccount,
              deadline, nonce, '0x');

            await expectRevert(
              this.token.safeTransferFromItemBWO(ownerId, nonReceiverId, tokenId, '0x', authAccount, deadline, signature, {
                from: this.operator
              }),
              'Item: transfer to non ERC721Receiver implementer',
            );
          });
        });
      });
    });

 

    describe('approveId proxy', function () {
      const tokenId = firstTokenId;

      let logs = null;

      const itClearsApproval = function () {
        it('clears approval for the token', async function () {
          expect(await this.token.getApproved(tokenId)).to.be.equal(ZERO_ADDRESS);
        });
      };

      const itApproves = function (addr) {
        it('sets the approval for the target address', async function () {
          expect(await this.token.getApproved(tokenId)).to.be.equal(web3.utils.toChecksumAddress(addr));
        });
      };

      const itEmitsApprovalEvent = function (addr, sender, nonce) {
        it('emits an approval event', async function () {
          expectEvent.inLogs(logs, 'ApprovalItemBWO', {
            to: web3.utils.toChecksumAddress(addr),
            tokenId: tokenId,
            sender: web3.utils.toChecksumAddress(sender),
          });
        });
      };

      context('when clearing approval', function () {
        context('when there was no prior approval', function () {
          let nonce = null;
          beforeEach(async function () {
            nonce = await this.token.getNonce(authAccount);
            const signature = signData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, ZERO_ADDRESS, tokenId, authAccount,
              deadline, nonce);
            ({
              logs
            } = await this.token.approveItemBWO(ZERO_ADDRESS, tokenId, authAccount, deadline, signature, {
              from: this.operator
            }));
          });

          itClearsApproval();
          itEmitsApprovalEvent(ZERO_ADDRESS, accountWAddr, nonce);
        });

        context('when there was a prior approval', function () {
          let nonce = null;
          beforeEach(async function () {
            nonce = await this.token.getNonce(authAccount);
            const signature = signData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, approved, tokenId, authAccount,
              deadline, nonce);

            await this.token.approveItemBWO(approved, tokenId, authAccount, deadline, signature, {
              from: this.operator
            });

            const nonce2 = await this.token.getNonce(authAccount);
            const signature2 = signData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, ZERO_ADDRESS, tokenId, authAccount,
              deadline, nonce2);
            ({
              logs
            } = await this.token.approveItemBWO(ZERO_ADDRESS, tokenId, authAccount, deadline, signature2, {
              from: this.operator
            }));
          });

          itClearsApproval();
          itEmitsApprovalEvent(ZERO_ADDRESS, authAccount, nonce);
        });
      });

      context('when approving a non-zero id', function () {
        context('when there was no prior approval', function () {
          let nonce = null;
          beforeEach(async function () {
            nonce = await this.token.getNonce(authAccount);
            const signature = signData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, approved, tokenId, authAccount,
              deadline, nonce);
            ({
              logs
            } = await this.token.approveItemBWO(approved, tokenId, authAccount, deadline, signature, {
              from: this.operator
            }));
          });

          itApproves(approved);
          itEmitsApprovalEvent(approved, authAccount, nonce);
        });

        context('when there was a prior approval to the same id', function () {
          let nonce = null;
          beforeEach(async function () {
            nonce = await this.token.getNonce(authAccount);
            const signature = signData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, approved, tokenId, authAccount,
              deadline, nonce);

            await this.token.approveItemBWO(approved, tokenId, authAccount, deadline, signature, {
              from: this.operator
            });
            const nonce2 = await this.token.getNonce(authAccount);
            const signature2 = signData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, approved, tokenId, authAccount,
              deadline, nonce2);

            ({
              logs
            } = await this.token.approveItemBWO(approved, tokenId, authAccount, deadline, signature2, {
              from: this.operator
            }));
          });

          itApproves(approved);
          itEmitsApprovalEvent(approved, authAccount, nonce);
        });

        context('when there was a prior approval to a different id', function () {
          let nonce2 = null;
          beforeEach(async function () {
            const nonce = await this.token.getNonce(authAccount);
            const signature = signData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, anotherApproved, tokenId, authAccount,
              deadline, nonce);
            await this.token.approveItemBWO(anotherApproved, tokenId, authAccount, deadline, signature, {
              from: this.operator
            });
            nonce2 = await this.token.getNonce(authAccount);
            const signature2 = signData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, anotherApproved, tokenId, authAccount,
              deadline, nonce2);
            ({
              logs
            } = await this.token.approveItemBWO(anotherApproved, tokenId, authAccount, deadline, signature2, {
              from: this.operator
            }));
          });

          itApproves(anotherApproved);
          itEmitsApprovalEvent(anotherApproved, authAccount, nonce2);
        });
      });

      context('when the sender does not own the given token ID', function () {
        it('reverts', async function () {
          const nonce = await this.token.getNonce(authAccount);
          const signature = signData(this.chainId, this.token.address, this.tokenName,
            otherW.getPrivateKey(), this.tokenVersion, approved, tokenId, other,
            deadline, nonce);
          await expectRevert(this.token.approveItemBWO(approved, tokenId, other, deadline, signature, {
              from: this.operator
            }),
            'Item: not owner');
        });
      });


 
    });

    describe('setApprovalForAllItemBWO proxy', function () {
      context('when the operator willing to approve is not the owner', function () {
        context('when there is no operator approval set by the sender', function () {
          it('approves the operator', async function () {
            const nonce = await this.token.getNonce(authAccount);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, ownerId, operator, true, authAccount,
              deadline, nonce);
            await this.token.setApprovalForAllItemBWO(ownerId, operator, true, authAccount, deadline, signature, {
              from: this.operator
            });

            expect(await this.token.isApprovedForAllItem(ownerId, operator)).to.equal(true);
          });

          it('emits an approvalById event', async function () {
            const nonce = await this.token.getNonce(authAccount);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, ownerId, operator, true, authAccount,
              deadline, nonce);

            const {
              logs
            } = await this.token.setApprovalForAllItemBWO(ownerId, operator, true, authAccount, deadline, signature, {
              from: this.operator
            });

            expectEvent.inLogs(logs, 'ApprovalForAllItemBWO', {
              from: ownerId,
              to: web3.utils.toChecksumAddress(operator),
              approved: true,
              sender: authAccount,
              nonce: nonce,
            });
          });
        });

        context('when the operator was set as not approved', function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(authAccount);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, ownerId, operator, false, authAccount,
              deadline, nonce);

            await this.token.setApprovalForAllItemBWO(ownerId, operator, false, authAccount, deadline, signature, {
              from: this.operator
            });
          });

          it('approves the operator', async function () {
            const nonce = await this.token.getNonce(authAccount);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, ownerId, operator, true, authAccount,
              deadline, nonce);
            await this.token.setApprovalForAllItemBWO(ownerId, operator, true, authAccount, deadline, signature, {
              from: this.operator
            });

            expect(await this.token.isApprovedForAllItem(ownerId, operator)).to.equal(true);
          });

          it('emits an approvalById event', async function () {
            const nonce = await this.token.getNonce(authAccount);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, ownerId, operator, true, authAccount,
              deadline, nonce);
            const {
              logs
            } = await this.token.setApprovalForAllItemBWO(ownerId, operator, true, authAccount, deadline, signature, {
              from: this.operator
            });

            expectEvent.inLogs(logs, 'ApprovalForAllItemBWO', {
              from: ownerId,
              to: web3.utils.toChecksumAddress(operator),
              approved: true,
              sender: accountW.getChecksumAddressString(),
              nonce: nonce,
            });
          });

          it('can unset the operator approval', async function () {
            const nonce = await this.token.getNonce(authAccount);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
             accountW.getPrivateKey(), this.tokenVersion, ownerId, operator, false, authAccount,
              deadline, nonce);
            await this.token.setApprovalForAllItemBWO(ownerId, operator, false, authAccount, deadline, signature, {
              from: this.operator
            });

            expect(await this.token.isApprovedForAllItem(ownerId, operator)).to.equal(false);
          });
        });

        context('when the operator was already approved', function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(authAccount);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, ownerId, operator, true, authAccount,
              deadline, nonce);
            await this.token.setApprovalForAllItemBWO(ownerId, operator, true, authAccount, deadline, signature, {
              from: this.operator
            });
          });

          it('keeps the approval to the given address', async function () {
            const nonce = await this.token.getNonce(authAccount);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, ownerId, operator, true, authAccount,
              deadline, nonce);

            await this.token.setApprovalForAllItemBWO(ownerId, operator, true, authAccount, deadline, signature, {
              from: this.operator
            });

            expect(await this.token.isApprovedForAllItem(ownerId, operator)).to.equal(true);
          });

          it('emits an approvalById event', async function () {
            const nonce = await this.token.getNonce(authAccount);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, ownerId, operator, true, authAccount,
              deadline, nonce);
            const {
              logs
            } = await this.token.setApprovalForAllItemBWO(ownerId, operator, true, authAccount, deadline, signature, {
              from: this.operator
            });

            expectEvent.inLogs(logs, 'ApprovalForAllItemBWO', {
              from: ownerId,
              to: web3.utils.toChecksumAddress(operator),
              approved: true,
              sender: authAccount,
              nonce: nonce,
            });
          });
        });
      });

      context('when the operator is the owner', function () {
        it('reverts', async function () {
          const nonce = await this.token.getNonce(authAccount);
          const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
            accountW.getPrivateKey(), this.tokenVersion, ownerId, owner, true, authAccount,
            deadline, nonce);
          await expectRevert(this.token.setApprovalForAllItemBWO(ownerId, owner, true, authAccount, deadline, signature, {
              from: this.operator
            }),
            'Item: approve to caller');
        });
      });
    });

    describe('getApproved proxy', async function () {
      context('when token is not minted', async function () {
        it('reverts', async function () {
          await expectRevert(
            this.token.getApproved(nonExistentTokenId),
            'Item: approved query for nonexistent token',
          );
        });
      });

      context('when token has been minted ', async function () {
        it('should return the zero id', async function () {
          expect(await this.token.getApproved(firstTokenId)).to.be.equal(
            ZERO_ADDRESS,
          );
        });

        context('when account has been approved', async function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(authAccount);
            const signature = signData(this.chainId, this.token.address, this.tokenName,
              accountW.getPrivateKey(), this.tokenVersion, approved, firstTokenId, authAccount,
              deadline, nonce);

            await this.token.approveItemBWO(approved, firstTokenId, authAccount, deadline, signature, {
              from: this.operator
            });
          });

          it('returns approved account', async function () {
            expect(await this.token.getApproved(firstTokenId)).to.be.equal(web3.utils.toChecksumAddress(approved));
          });
        });
      });
    });
  });

}

function signData(chainId, verifyingContract, name, key, version, to, tokenId, sender, deadline, nonce) {
  const data = {
    types: {
      EIP712Domain,
      BWO: [{
          name: 'to',
          type: 'address'
        },
        {
          name: 'tokenId',
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
      to,
      tokenId,
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

function signApprovedAllData(chainId, verifyingContract, name, key, version, from, to, approved, sender, deadline, nonce) {
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
          name: 'approved',
          type: 'bool'
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
        }
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
      approved,
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

function signTrasferData(chainId, verifyingContract, name, key, version, from, to, tokenId, sender, deadline, nonce) {
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
          name: 'tokenId',
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
      tokenId,
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

function signSafeTrasferData(chainId, verifyingContract, name, key, version, from, to, tokenId, sender, deadline, nonce, payload) {
  let data;
  if (payload == null) {
    data = {
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
            name: 'tokenId',
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
        tokenId,
        sender,
        nonce,
        deadline
      },
    };

  } else {
    data = {
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
            name: 'tokenId',
            type: 'uint256'
          },
          {
            name: 'data',
            type: 'bytes'
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
          }
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
        tokenId,
        data: payload,
        sender,
        nonce,
        deadline
      },
    };
  }

  const signature = ethSigUtil.signTypedMessage(key, {
    data
  });

  return signature;
}

function signAddAuthProxyAddrBWO(chainId, verifyingContract, name, key, version, id, addr, sender, nonce, deadline) {
  const data = {
    types: {
      EIP712Domain,
      BWO: [{
        name: 'id',
        type: 'uint256'
      },
      {
        name: 'addr',
        type: 'address'
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
      id,
      addr,
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
  shouldBehaveLikeItem721ProxyBWO,
};