const {
  BN,
  constants,
  expectEvent,
  expectRevert,
} = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { ZERO_ADDRESS } = constants;

const Wallet = require('ethereumjs-wallet').default;
const ethSigUtil = require('eth-sig-util');
const { web3 } = require('hardhat');

const ERC721ReceiverMock = artifacts.require('ERC721ReceiverMock');

const Error = [
  'None',
  'RevertWithMessage',
  'RevertWithoutMessage',
  'Panic',
].reduce(
  (acc, entry, idx) =>
    Object.assign(
      {
        [entry]: idx,
      },
      acc,
    ),
  {},
);

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
const brunOwnerId = new BN(6);

const deadline = new BN(parseInt(new Date().getTime() / 1000) + 36000);

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

function shouldBehaveLikeAsset721BWO(brunOwner) {
  context('with minted tokens', function () {
    beforeEach(async function () {
      // create account

      await this.Metaverse.createAccount(owner, false);
      await this.Metaverse.createAccount(approved, false);
      await this.Metaverse.createAccount(anotherApproved, false);
      await this.Metaverse.createAccount(operator, false);
      await this.Metaverse.createAccount(other, false);
      await this.Metaverse.createAccount(brunOwner, false);

      await this.token.mint(ownerId, firstTokenId);
      await this.token.mint(ownerId, secondTokenId);
      this.toWhom = other; // default to other for toWhom in context-dependent tests
      this.toWhomId = otherId;
    });

    describe('balanceOfItem', function () {
      context('when the given address owns some tokens', function () {
        it('returns the amount of tokens owned by the given address', async function () {
          expect(
            await this.token.methods['balanceOf(uint256)'](ownerId),
          ).to.be.bignumber.equal('2');
        });
      });

      context('when the given address does not own any tokens', function () {
        it('returns 0', async function () {
          expect(
            await this.token.methods['balanceOf(uint256)'](otherId),
          ).to.be.bignumber.equal('0');
        });
      });

      context('when querying the zero address', function () {
        it('throws', async function () {
          await expectRevert(
            this.token.methods['balanceOf(uint256)'](0),
            'Asset721: id zero is not a valid owner',
          );
        });
      });
    });

    describe('ownerAccountOf', function () {
      context('when the given token ID was tracked by this token', function () {
        const tokenId = firstTokenId;

        it('returns the owner of the given token ID', async function () {
          expect(
            await this.token.ownerAccountOf(tokenId),
          ).to.be.bignumber.equal(ownerId);
        });
      });

      context(
        'when the given token ID was not tracked by this token',
        function () {
          const tokenId = nonExistentTokenId;

          it('reverts', async function () {
            await expectRevert(
              this.token.ownerAccountOf(tokenId),
              'Asset721: owner query for nonexistent token',
            );
          });
        },
      );
    });

    describe('transferBWO', function () {
      const tokenId = firstTokenId;
      const data = '0x42';

      let logs = null;

      beforeEach(async function () {
        const nonce = await this.token.getNonce(owner);
        const signature = signApprove(
          this.chainId,
          this.tokenCore.address,
          this.tokenName,
          ownerW.getPrivateKey(),
          this.tokenVersion,
          approved,
          tokenId,
          owner,
          deadline,
          nonce,
        );

        await this.token.approveBWO(
          approved,
          tokenId,
          owner,
          deadline,
          signature,
          {
            from: this.operator,
          },
        );

        const nonceAll = await this.token.getNonce(owner);

        const signatureAll = signApprovedAllData(
          this.chainId,
          this.tokenCore.address,
          this.tokenName,
          ownerW.getPrivateKey(),
          this.tokenVersion,
          ownerId,
          operator,
          true,
          owner,
          deadline,
          nonceAll,
        );

        await this.token.setApprovalForAllBWO(
          ownerId,
          operator,
          true,
          owner,
          deadline,
          signatureAll,
          {
            from: this.operator,
          },
        );
      });

      const transferWasSuccessful = function ({
        owner,
        tokenId,
        sender,
        nonce,
      }) {
        it('transfers the ownership of the given token ID to the given address', async function () {
          expect(
            await this.token.ownerAccountOf(tokenId),
          ).to.be.bignumber.equal(this.toWhomId);
        });

        it('emits a TransferItemBWO event', async function () {
          expectEvent.inLogs(logs, 'AssetTransfer', {
            from: ownerId,
            to: this.toWhomId,
            tokenId: tokenId,
            isBWO: true,
            sender: web3.utils.toChecksumAddress(sender),
          });
        });

        it('clears the approval for the token ID', async function () {
          expect(await this.token.getApproved(tokenId)).to.be.equal(
            ZERO_ADDRESS,
          );
        });

        it('adjusts owners balances', async function () {
          expect(
            await this.token.methods['balanceOf(uint256)'](ownerId),
          ).to.be.bignumber.equal('1');
        });

        it('adjusts owners tokens by index', async function () {
          if (!this.token.tokenOfOwnerByIndex) return;

          expect(
            await this.token.tokenOfOwnerByIndex(this.toWhom, 0),
          ).to.be.bignumber.equal(tokenId);

          expect(
            await this.token.tokenOfOwnerByIndex(owner, 0),
          ).to.be.bignumber.not.equal(tokenId);
        });
      };

      const shouldTransferTokensByUsers = function (transferFunction, data) {
        context('when called by the owner', function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(owner);
            this.nonce = nonce;
            let signature;
            if (data == null) {
              signature = signTransferData(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                ownerId,
                this.toWhomId,
                tokenId,
                owner,
                deadline,
                nonce,
              );
            } else {
              signature = signSafeTransferData(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                ownerId,
                this.toWhomId,
                tokenId,
                owner,
                deadline,
                nonce,
                data,
              );
            }

            ({ logs } = await transferFunction.call(
              this,
              owner,
              ownerId,
              this.toWhomId,
              tokenId,
              signature,
              {
                from: this.operator,
              },
            ));
          });
          transferWasSuccessful({
            owner,
            tokenId,
            sender: owner,
          });
        });

        context('when sent to the owner', function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(owner);
            let signature;
            if (data == null) {
              signature = signTransferData(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                ownerId,
                ownerId,
                tokenId,
                owner,
                deadline,
                nonce,
              );
            } else {
              signature = signSafeTransferData(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                ownerId,
                ownerId,
                tokenId,
                owner,
                deadline,
                nonce,
                data,
              );
            }
            ({ logs } = await transferFunction.call(
              this,
              owner,
              ownerId,
              ownerId,
              tokenId,
              signature,
              {
                from: this.operator,
              },
            ));
          });

          it('keeps ownership of the token', async function () {
            expect(
              await this.token.ownerAccountOf(tokenId),
            ).to.be.bignumber.equal(ownerId);
          });

          it('clears the approval for the token ID', async function () {
            expect(await this.token.getApproved(tokenId)).to.be.equal(
              ZERO_ADDRESS,
            );
          });

          it('emits only a transferCash event', async function () {
            expectEvent.inLogs(logs, 'AssetTransfer', {
              from: ownerId,
              to: ownerId,
              tokenId: tokenId,
              isBWO: true,
            });
          });

          it('keeps the owner balance', async function () {
            expect(
              await this.token.methods['balanceOf(uint256)'](ownerId),
            ).to.be.bignumber.equal('2');
          });

          it('keeps same tokens by index', async function () {
            if (!this.token.tokenOfOwnerByIndex) return;
            const tokensListed = await Promise.all(
              [0, 1].map((i) => this.token.tokenOfOwnerByIndex(owner, i)),
            );
            expect(tokensListed.map((t) => t.toNumber())).to.have.members([
              firstTokenId.toNumber(),
              secondTokenId.toNumber(),
            ]);
          });
        });

        context(
          'when the address of the previous owner is incorrect',
          function () {
            it('reverts', async function () {
              const nonce = await this.token.getNonce(owner);
              let signature;
              if (data == null) {
                signature = signTransferData(
                  this.chainId,
                  this.tokenCore.address,
                  this.tokenName,
                  ownerW.getPrivateKey(),
                  this.tokenVersion,
                  otherId,
                  otherId,
                  tokenId,
                  owner,
                  deadline,
                  nonce,
                );
              } else {
                signature = signSafeTransferData(
                  this.chainId,
                  this.tokenCore.address,
                  this.tokenName,
                  ownerW.getPrivateKey(),
                  this.tokenVersion,
                  otherId,
                  otherId,
                  tokenId,
                  owner,
                  deadline,
                  nonce,
                  data,
                );
              }

              await expectRevert(
                transferFunction.call(
                  this,
                  owner,
                  otherId,
                  otherId,
                  tokenId,
                  signature,
                  {
                    from: this.operator,
                  },
                ),
                'Asset721: transfer from incorrect owner',
              );
            });
          },
        );

        context(
          'when the sender is not authorized for the token id',
          function () {
            it('reverts', async function () {
              const nonce = await this.token.getNonce(other);
              let signature;
              if (data == null) {
                signature = signTransferData(
                  this.chainId,
                  this.tokenCore.address,
                  this.tokenName,
                  otherW.getPrivateKey(),
                  this.tokenVersion,
                  ownerId,
                  otherId,
                  tokenId,
                  other,
                  deadline,
                  nonce,
                );
              } else {
                signature = signSafeTransferData(
                  this.chainId,
                  this.tokenCore.address,
                  this.tokenName,
                  otherW.getPrivateKey(),
                  this.tokenVersion,
                  ownerId,
                  otherId,
                  tokenId,
                  other,
                  deadline,
                  nonce,
                  data,
                );
              }
              await expectRevert(
                transferFunction.call(
                  this,
                  other,
                  ownerId,
                  otherId,
                  tokenId,
                  signature,
                  {
                    from: this.operator,
                  },
                ),
                'Asset721: transfer caller is not owner nor approved',
              );
            });
          },
        );

        context('when the given token ID does not exist', function () {
          it('reverts', async function () {
            const nonce = await this.token.getNonce(owner);
            let signature;
            if (data == null) {
              signature = signTransferData(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                ownerId,
                otherId,
                nonExistentTokenId,
                owner,
                deadline,
                nonce,
              );
            } else {
              signature = signSafeTransferData(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                ownerId,
                otherId,
                nonExistentTokenId,
                owner,
                deadline,
                nonce,
                data,
              );
            }

            await expectRevert(
              transferFunction.call(
                this,
                owner,
                ownerId,
                otherId,
                nonExistentTokenId,
                signature,
                {
                  from: this.operator,
                },
              ),
              'Asset721: operator query for nonexistent token',
            );
          });
        });

        context(
          'when the address to transfer the token to is the zero id',
          function () {
            it('reverts', async function () {
              const nonce = await this.token.getNonce(owner);
              let signature;
              if (data == null) {
                signature = signTransferData(
                  this.chainId,
                  this.tokenCore.address,
                  this.tokenName,
                  ownerW.getPrivateKey(),
                  this.tokenVersion,
                  ownerId,
                  ZERO,
                  tokenId,
                  owner,
                  deadline,
                  nonce,
                );
              } else {
                signature = signSafeTransferData(
                  this.chainId,
                  this.tokenCore.address,
                  this.tokenName,
                  ownerW.getPrivateKey(),
                  this.tokenVersion,
                  ownerId,
                  ZERO,
                  tokenId,
                  owner,
                  deadline,
                  nonce,
                  data,
                );
              }

              await transferFunction.call(
                this,
                owner,
                ownerId,
                ZERO,
                tokenId,
                signature,
                {
                  from: this.operator,
                },
              );

              await expectRevert(
                this.token.ownerOf(tokenId),
                'Asset721: owner query for nonexistent token',
              );
            });
          },
        );
      };

      describe('via transferFromItemBWO', function () {
        shouldTransferTokensByUsers(function (
          sender,
          fromId,
          toId,
          tokenId,
          signature,
          opts,
        ) {
          return this.token.transferFromBWO(
            fromId,
            toId,
            tokenId,
            sender,
            deadline,
            signature,
            opts,
          );
        },
        null);
      });

      describe('via safeTransferFromBWO', function () {
        const safeTransferFromBWOWithData = function (
          sender,
          fromId,
          toId,
          tokenId,
          signature,
          opts,
        ) {
          return this.token.methods[
            'safeTransferFromBWO(uint256,uint256,uint256,bytes,address,uint256,bytes)'
          ](fromId, toId, tokenId, data, sender, deadline, signature, opts);
        };

        // const safeTransferFromBWOWithoutData = function (sender, fromId, toId, tokenId, signature, opts) {
        //   return this.token.methods['safeTransferFromBWO(uint256,uint256,uint256,address,uint256,bytes)'](fromId, toId, tokenId, sender, deadline, signature, opts);
        // };

        const shouldTransferSafely = function (transferFun, data) {
          describe('to a user account', function () {
            shouldTransferTokensByUsers(transferFun, data);
          });

          describe('to a valid receiver contract', function () {
            beforeEach(async function () {
              this.receiver = await ERC721ReceiverMock.new(
                RECEIVER_MAGIC_VALUE,
                Error.None,
              );
              this.toWhom = this.receiver.address;
              await this.Metaverse.createAccount(this.receiver.address, false);
              this.receiverId = new BN(
                await this.Metaverse.getAccountIdByAddress(
                  this.receiver.address,
                ),
              );
            });

            shouldTransferTokensByUsers(transferFun, data);

            it('calls onERC721Received', async function () {
              const nonce = await this.token.getNonce(owner);

              const signature = signSafeTransferData(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                ownerId,
                this.receiverId,
                tokenId,
                owner,
                deadline,
                nonce,
                data,
              );

              const receipt = await transferFun.call(
                this,
                owner,
                ownerId,
                this.receiverId,
                tokenId,
                signature,
                {
                  from: this.operator,
                },
              );

              await expectEvent.inTransaction(
                receipt.tx,
                ERC721ReceiverMock,
                'Received',
                {
                  operator: this.operator,
                  from: web3.utils.toChecksumAddress(owner),
                  tokenId: tokenId,
                  data: data,
                },
              );
            });

            describe('with an invalid token id', function () {
              it('reverts', async function () {
                const nonce = await this.token.getNonce(owner);
                const signature = signSafeTransferData(
                  this.chainId,
                  this.tokenCore.address,
                  this.tokenName,
                  ownerW.getPrivateKey(),
                  this.tokenVersion,
                  ownerId,
                  this.receiverId,
                  nonExistentTokenId,
                  owner,
                  deadline,
                  nonce,
                  data,
                );

                await expectRevert(
                  transferFun.call(
                    this,
                    owner,
                    ownerId,
                    this.receiverId,
                    nonExistentTokenId,
                    signature,
                    {
                      from: this.operator,
                    },
                  ),
                  'Asset721: operator query for nonexistent token',
                );
              });
            });
          });
        };

        describe('with data', function () {
          shouldTransferSafely(safeTransferFromBWOWithData, data);
        });

        describe('to a receiver contract returning unexpected value', function () {
          it('reverts', async function () {
            const invalidReceiver = await ERC721ReceiverMock.new(
              '0x42',
              Error.None,
            );
            await this.Metaverse.createAccount(invalidReceiver.address, false);
            const invalidReceiverId = new BN(
              await this.Metaverse.getAccountIdByAddress(
                invalidReceiver.address,
              ),
            );
            const nonce = await this.token.getNonce(owner);
            const signature = signSafeTransferData(
              this.chainId,
              this.tokenCore.address,
              this.tokenName,
              ownerW.getPrivateKey(),
              this.tokenVersion,
              ownerId,
              invalidReceiverId,
              tokenId,
              owner,
              deadline,
              nonce,
              '0x',
            );

            await expectRevert(
              this.token.safeTransferFromBWO(
                ownerId,
                invalidReceiverId,
                tokenId,
                '0x',
                owner,
                deadline,
                signature,
                {
                  from: this.operator,
                },
              ),
              'Asset721: transfer to non ERC721Receiver implementer',
            );
          });
        });

        describe('to a receiver contract that reverts with message', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.new(
              RECEIVER_MAGIC_VALUE,
              Error.RevertWithMessage,
            );
            await this.Metaverse.createAccount(
              revertingReceiver.address,
              false,
            );
            const revertingReceiverId = new BN(
              await this.Metaverse.getAccountIdByAddress(
                revertingReceiver.address,
              ),
            );

            const nonce = await this.token.getNonce(owner);
            const signature = signSafeTransferData(
              this.chainId,
              this.tokenCore.address,
              this.tokenName,
              ownerW.getPrivateKey(),
              this.tokenVersion,
              ownerId,
              revertingReceiverId,
              tokenId,
              owner,
              deadline,
              nonce,
              '0x',
            );

            await expectRevert(
              this.token.safeTransferFromBWO(
                ownerId,
                revertingReceiverId,
                tokenId,
                '0x',
                owner,
                deadline,
                signature,
                {
                  from: this.operator,
                },
              ),
              'ERC721ReceiverMock: reverting',
            );
          });
        });

        describe('to a receiver contract that reverts without message', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.new(
              RECEIVER_MAGIC_VALUE,
              Error.RevertWithoutMessage,
            );
            await this.Metaverse.createAccount(
              revertingReceiver.address,
              false,
            );
            const revertingReceiverId = new BN(
              await this.Metaverse.getAccountIdByAddress(
                revertingReceiver.address,
              ),
            );
            const nonce = await this.token.getNonce(owner);
            const signature = signSafeTransferData(
              this.chainId,
              this.tokenCore.address,
              this.tokenName,
              ownerW.getPrivateKey(),
              this.tokenVersion,
              ownerId,
              revertingReceiverId,
              tokenId,
              owner,
              deadline,
              nonce,
              '0x',
            );

            await expectRevert(
              this.token.safeTransferFromBWO(
                ownerId,
                revertingReceiverId,
                tokenId,
                '0x',
                owner,
                deadline,
                signature,
                {
                  from: this.operator,
                },
              ),
              'Asset721: transfer to non ERC721Receiver implementer',
            );
          });
        });

        describe('to a receiver contract that panics', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.new(
              RECEIVER_MAGIC_VALUE,
              Error.Panic,
            );
            await this.Metaverse.createAccount(
              revertingReceiver.address,
              false,
            );
            const revertingReceiverId = new BN(
              await this.Metaverse.getAccountIdByAddress(
                revertingReceiver.address,
              ),
            );

            const nonce = await this.token.getNonce(owner);
            const signature = signSafeTransferData(
              this.chainId,
              this.tokenCore.address,
              this.tokenName,
              ownerW.getPrivateKey(),
              this.tokenVersion,
              ownerId,
              revertingReceiverId,
              tokenId,
              owner,
              deadline,
              nonce,
              '0x',
            );

            await expectRevert.unspecified(
              this.token.safeTransferFromBWO(
                ownerId,
                revertingReceiverId,
                tokenId,
                '0x',
                owner,
                deadline,
                signature,
                {
                  from: this.operator,
                },
              ),
            );
          });
        });

        describe('to a contract that does not implement the required function', function () {
          it('reverts', async function () {
            const nonReceiver = this.token;
            await this.Metaverse.createAccount(nonReceiver.address, false);
            const nonReceiverId = new BN(
              await this.Metaverse.getAccountIdByAddress(nonReceiver.address),
            );
            const nonce = await this.token.getNonce(owner);
            const signature = signSafeTransferData(
              this.chainId,
              this.tokenCore.address,
              this.tokenName,
              ownerW.getPrivateKey(),
              this.tokenVersion,
              ownerId,
              nonReceiverId,
              tokenId,
              owner,
              deadline,
              nonce,
              '0x',
            );

            await expectRevert(
              this.token.safeTransferFromBWO(
                ownerId,
                nonReceiverId,
                tokenId,
                '0x',
                owner,
                deadline,
                signature,
                {
                  from: this.operator,
                },
              ),
              'Asset721: transfer to non ERC721Receiver implementer',
            );
          });
        });
      });
    });

    describe('safe mint', function () {
      const tokenId = fourthTokenId;
      const data = '0x42';

      describe('via safeMint', function () {
        // regular minting is tested in ERC721Mintable.test.js and others
        it('calls onERC721Received — with data', async function () {
          this.receiver = await ERC721ReceiverMock.new(
            RECEIVER_MAGIC_VALUE,
            Error.None,
          );

          await this.Metaverse.createAccount(this.receiver.address, false);

          const tmpReceiverId = await this.Metaverse.getAccountIdByAddress(
            this.receiver.address,
          );

          const receipt = await this.token.safeMint(
            tmpReceiverId,
            tokenId,
            data,
          );

          await expectEvent.inTransaction(
            receipt.tx,
            ERC721ReceiverMock,
            'Received',
            {
              from: ZERO_ADDRESS,
              tokenId: tokenId,
              data: data,
            },
          );
        });

        it('calls onERC721Received — without data', async function () {
          this.receiver = await ERC721ReceiverMock.new(
            RECEIVER_MAGIC_VALUE,
            Error.None,
          );

          await this.Metaverse.createAccount(this.receiver.address, false);

          const tmpReceiverId = await this.Metaverse.getAccountIdByAddress(
            this.receiver.address,
          );

          const receipt = await this.token.safeMint(
            tmpReceiverId,
            tokenId,
            '0x',
          );
          await expectEvent.inTransaction(
            receipt.tx,
            ERC721ReceiverMock,
            'Received',
            {
              from: ZERO_ADDRESS,
              tokenId: tokenId,
            },
          );
        });

        context(
          'to a receiver contract returning unexpected value',
          function () {
            it('reverts', async function () {
              const invalidReceiver = await ERC721ReceiverMock.new(
                '0x42',
                Error.None,
              );

              await this.Metaverse.createAccount(
                invalidReceiver.address,
                false,
              );

              const invalidReceiverId =
                await this.Metaverse.getAccountIdByAddress(
                  invalidReceiver.address,
                );

              await expectRevert(
                this.token.safeMint(invalidReceiverId, tokenId, '0x'),
                'Asset721: transfer to non ERC721Receiver implementer',
              );
            });
          },
        );

        context(
          'to a receiver contract that reverts with message',
          function () {
            it('reverts', async function () {
              const revertingReceiver = await ERC721ReceiverMock.new(
                RECEIVER_MAGIC_VALUE,
                Error.RevertWithMessage,
              );

              await this.Metaverse.createAccount(
                revertingReceiver.address,
                false,
              );

              const revertingReceiverId =
                await this.Metaverse.getAccountIdByAddress(
                  revertingReceiver.address,
                );

              await expectRevert(
                this.token.safeMint(revertingReceiverId, tokenId, '0x'),
                'ERC721ReceiverMock: reverting',
              );
            });
          },
        );

        context(
          'to a receiver contract that reverts without message',
          function () {
            it('reverts', async function () {
              const revertingReceiver = await ERC721ReceiverMock.new(
                RECEIVER_MAGIC_VALUE,
                Error.RevertWithoutMessage,
              );

              await this.Metaverse.createAccount(
                revertingReceiver.address,
                false,
              );

              const revertingReceiverId =
                await this.Metaverse.getAccountIdByAddress(
                  revertingReceiver.address,
                );

              await expectRevert(
                this.token.safeMint(revertingReceiverId, tokenId, '0x'),
                'Asset721: transfer to non ERC721Receiver implementer',
              );
            });
          },
        );

        context('to a receiver contract that panics', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.new(
              RECEIVER_MAGIC_VALUE,
              Error.Panic,
            );

            await this.Metaverse.createAccount(
              revertingReceiver.address,
              false,
            );

            const revertingReceiverId =
              await this.Metaverse.getAccountIdByAddress(
                revertingReceiver.address,
              );

            await expectRevert.unspecified(
              this.token.safeMint(revertingReceiverId, tokenId, '0x'),
            );
          });
        });

        context(
          'to a contract that does not implement the required function',
          function () {
            it('reverts', async function () {
              const nonReceiver = this.token;
              await this.Metaverse.createAccount(nonReceiver.address, false);
              const nonReceiverId = await this.Metaverse.getAccountIdByAddress(
                nonReceiver.address,
              );

              await expectRevert(
                this.token.safeMint(nonReceiverId, tokenId, '0x'),
                'Asset721: transfer to non ERC721Receiver implementer',
              );
            });
          },
        );
      });
    });

    describe('approveId', function () {
      const tokenId = firstTokenId;

      let logs = null;

      const itClearsApproval = function () {
        it('clears approval for the token', async function () {
          expect(await this.token.getApproved(tokenId)).to.be.equal(
            ZERO_ADDRESS,
          );
        });
      };

      const itApproves = function (addr) {
        it('sets the approval for the target address', async function () {
          expect(await this.token.getApproved(tokenId)).to.be.equal(
            web3.utils.toChecksumAddress(addr),
          );
        });
      };

      const itEmitsApprovalEvent = function (addr, sender, nonce) {
        it('emits an approval event', async function () {
          expectEvent.inLogs(logs, 'AssetApproval', {
            tokenId: tokenId,
            isBWO: true,
            sender: web3.utils.toChecksumAddress(sender),
          });
        });
      };

      context('when clearing approval', function () {
        context('when there was no prior approval', function () {
          let nonce = null;
          beforeEach(async function () {
            nonce = await this.token.getNonce(owner);
            const signature = signApprove(
              this.chainId,
              this.tokenCore.address,
              this.tokenName,
              ownerW.getPrivateKey(),
              this.tokenVersion,
              ZERO_ADDRESS,
              tokenId,
              owner,
              deadline,
              nonce,
            );
            ({ logs } = await this.token.approveBWO(
              ZERO_ADDRESS,
              tokenId,
              owner,
              deadline,
              signature,
              {
                from: this.operator,
              },
            ));
          });

          itClearsApproval();
          itEmitsApprovalEvent(ZERO_ADDRESS, owner, nonce);
        });

        context('when there was a prior approval', function () {
          let nonce = null;
          beforeEach(async function () {
            nonce = await this.token.getNonce(owner);
            const signature = signApprove(
              this.chainId,
              this.tokenCore.address,
              this.tokenName,
              ownerW.getPrivateKey(),
              this.tokenVersion,
              approved,
              tokenId,
              owner,
              deadline,
              nonce,
            );

            await this.token.approveBWO(
              approved,
              tokenId,
              owner,
              deadline,
              signature,
              {
                from: this.operator,
              },
            );

            const nonce2 = await this.token.getNonce(owner);
            const signature2 = signApprove(
              this.chainId,
              this.tokenCore.address,
              this.tokenName,
              ownerW.getPrivateKey(),
              this.tokenVersion,
              ZERO_ADDRESS,
              tokenId,
              owner,
              deadline,
              nonce2,
            );
            ({ logs } = await this.token.approveBWO(
              ZERO_ADDRESS,
              tokenId,
              owner,
              deadline,
              signature2,
              {
                from: this.operator,
              },
            ));
          });

          itClearsApproval();
          itEmitsApprovalEvent(ZERO_ADDRESS, owner, nonce);
        });
      });

      context('when approving a non-zero id', function () {
        context('when there was no prior approval', function () {
          let nonce = null;
          beforeEach(async function () {
            nonce = await this.token.getNonce(owner);
            const signature = signApprove(
              this.chainId,
              this.tokenCore.address,
              this.tokenName,
              ownerW.getPrivateKey(),
              this.tokenVersion,
              approved,
              tokenId,
              owner,
              deadline,
              nonce,
            );
            ({ logs } = await this.token.approveBWO(
              approved,
              tokenId,
              owner,
              deadline,
              signature,
              {
                from: this.operator,
              },
            ));
          });

          itApproves(approved);
          itEmitsApprovalEvent(approved, owner, nonce);
        });

        context('when there was a prior approval to the same id', function () {
          let nonce = null;
          beforeEach(async function () {
            nonce = await this.token.getNonce(owner);
            const signature = signApprove(
              this.chainId,
              this.tokenCore.address,
              this.tokenName,
              ownerW.getPrivateKey(),
              this.tokenVersion,
              approved,
              tokenId,
              owner,
              deadline,
              nonce,
            );

            await this.token.approveBWO(
              approved,
              tokenId,
              owner,
              deadline,
              signature,
              {
                from: this.operator,
              },
            );
            const nonce2 = await this.token.getNonce(owner);
            const signature2 = signApprove(
              this.chainId,
              this.tokenCore.address,
              this.tokenName,
              ownerW.getPrivateKey(),
              this.tokenVersion,
              approved,
              tokenId,
              owner,
              deadline,
              nonce2,
            );

            ({ logs } = await this.token.approveBWO(
              approved,
              tokenId,
              owner,
              deadline,
              signature2,
              {
                from: this.operator,
              },
            ));
          });

          itApproves(approved);
          itEmitsApprovalEvent(approved, owner, nonce);
        });

        context(
          'when there was a prior approval to a different id',
          function () {
            let nonce2 = null;
            beforeEach(async function () {
              const nonce = await this.token.getNonce(owner);
              const signature = signApprove(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                anotherApproved,
                tokenId,
                owner,
                deadline,
                nonce,
              );
              await this.token.approveBWO(
                anotherApproved,
                tokenId,
                owner,
                deadline,
                signature,
                {
                  from: this.operator,
                },
              );
              nonce2 = await this.token.getNonce(owner);
              const signature2 = signApprove(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                anotherApproved,
                tokenId,
                owner,
                deadline,
                nonce2,
              );
              ({ logs } = await this.token.approveBWO(
                anotherApproved,
                tokenId,
                owner,
                deadline,
                signature2,
                {
                  from: this.operator,
                },
              ));
            });

            itApproves(anotherApproved);
            itEmitsApprovalEvent(anotherApproved, owner, nonce2);
          },
        );
      });

      context(
        'when the id that receives the approval is the owner',
        function () {
          it('reverts', async function () {
            const nonce = await this.token.getNonce(owner);
            const signature = signApprove(
              this.chainId,
              this.tokenCore.address,
              this.tokenName,
              ownerW.getPrivateKey(),
              this.tokenVersion,
              owner,
              tokenId,
              owner,
              deadline,
              nonce,
            );
            await expectRevert(
              this.token.approveBWO(
                owner,
                tokenId,
                owner,
                deadline,
                signature,
                {
                  from: this.operator,
                },
              ),
              'Asset721: approval to current account',
            );
          });
        },
      );

      context('when the sender does not own the given token ID', function () {
        it('reverts', async function () {
          const nonce = await this.token.getNonce(other);
          const signature = signApproveData(
            this.chainId,
            this.tokenCore.address,
            this.tokenName,
            otherW.getPrivateKey(),
            this.tokenVersion,
            approved,
            tokenId,
            other,
            deadline,
            nonce,
          );
          await expectRevert(
            this.token.approveBWO(
              approved,
              tokenId,
              other,
              deadline,
              signature,
              {
                from: this.operator,
              },
            ),
            'Asset721: approve caller is not owner or approved for all',
          );
        });
      });

      context('when the given token ID does not exist', function () {
        it('reverts', async function () {
          const nonce = await this.token.getNonce(operator);
          const signature = signApproveData(
            this.chainId,
            this.tokenCore.address,
            this.tokenName,
            operatorW.getPrivateKey(),
            this.tokenVersion,
            approved,
            nonExistentTokenId,
            operator,
            deadline,
            nonce,
          );

          await expectRevert(
            this.token.approveBWO(
              approved,
              nonExistentTokenId,
              operator,
              deadline,
              signature,
              {
                from: this.operator,
              },
            ),
            'Asset721: owner query for nonexistent token',
          );
        });
      });
    });

    describe('setApprovalForAllBWO', function () {
      context(
        'when the operator willing to approve is not the owner',
        function () {
          context(
            'when there is no operator approval set by the sender',
            function () {
              it('approves the operator', async function () {
                const nonce = await this.token.getNonce(owner);
                const signature = signApprovedAllData(
                  this.chainId,
                  this.tokenCore.address,
                  this.tokenName,
                  ownerW.getPrivateKey(),
                  this.tokenVersion,
                  ownerId,
                  operator,
                  true,
                  owner,
                  deadline,
                  nonce,
                );
                await this.token.setApprovalForAllBWO(
                  ownerId,
                  operator,
                  true,
                  owner,
                  deadline,
                  signature,
                  {
                    from: this.operator,
                  },
                );

                expect(
                  await this.token.methods['isApprovedForAll(uint256,address)'](
                    ownerId,
                    operator,
                  ),
                ).to.equal(true);
              });

              it('emits an approvalById event', async function () {
                const nonce = await this.token.getNonce(owner);
                const signature = signApprovedAllData(
                  this.chainId,
                  this.tokenCore.address,
                  this.tokenName,
                  ownerW.getPrivateKey(),
                  this.tokenVersion,
                  ownerId,
                  operator,
                  true,
                  owner,
                  deadline,
                  nonce,
                );

                const { logs } = await this.token.setApprovalForAllBWO(
                  ownerId,
                  operator,
                  true,
                  owner,
                  deadline,
                  signature,
                  {
                    from: this.operator,
                  },
                );

                expectEvent.inLogs(logs, 'AssetApprovalForAll', {
                  from: ownerId,
                  to: web3.utils.toChecksumAddress(operator),
                  approved: true,
                  isBWO: true,
                  sender: web3.utils.toChecksumAddress(owner),
                  nonce: nonce,
                });
              });
            },
          );

          context('when the operator was set as not approved', function () {
            beforeEach(async function () {
              const nonce = await this.token.getNonce(owner);
              const signature = signApprovedAllData(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                ownerId,
                operator,
                false,
                owner,
                deadline,
                nonce,
              );

              await this.token.setApprovalForAllBWO(
                ownerId,
                operator,
                false,
                owner,
                deadline,
                signature,
                {
                  from: this.operator,
                },
              );
            });

            it('approves the operator', async function () {
              const nonce = await this.token.getNonce(owner);
              const signature = signApprovedAllData(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                ownerId,
                operator,
                true,
                owner,
                deadline,
                nonce,
              );
              await this.token.setApprovalForAllBWO(
                ownerId,
                operator,
                true,
                owner,
                deadline,
                signature,
                {
                  from: this.operator,
                },
              );

              expect(
                await this.token.methods['isApprovedForAll(uint256,address)'](
                  ownerId,
                  operator,
                ),
              ).to.equal(true);
            });

            it('emits an approvalById event', async function () {
              const nonce = await this.token.getNonce(owner);
              const signature = signApprovedAllData(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                ownerId,
                operator,
                true,
                owner,
                deadline,
                nonce,
              );
              const { logs } = await this.token.setApprovalForAllBWO(
                ownerId,
                operator,
                true,
                owner,
                deadline,
                signature,
                {
                  from: this.operator,
                },
              );

              expectEvent.inLogs(logs, 'AssetApprovalForAll', {
                from: ownerId,
                to: web3.utils.toChecksumAddress(operator),
                approved: true,
                isBWO: true,
                sender: web3.utils.toChecksumAddress(owner),
                nonce: nonce,
              });
            });

            it('can unset the operator approval', async function () {
              const nonce = await this.token.getNonce(owner);
              const signature = signApprovedAllData(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                ownerId,
                operator,
                false,
                owner,
                deadline,
                nonce,
              );
              await this.token.setApprovalForAllBWO(
                ownerId,
                operator,
                false,
                owner,
                deadline,
                signature,
                {
                  from: this.operator,
                },
              );

              expect(
                await this.token.methods['isApprovedForAll(uint256,address)'](
                  ownerId,
                  operator,
                ),
              ).to.equal(false);
            });
          });

          context('when the operator was already approved', function () {
            beforeEach(async function () {
              const nonce = await this.token.getNonce(owner);
              const signature = signApprovedAllData(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                ownerId,
                operator,
                true,
                owner,
                deadline,
                nonce,
              );
              await this.token.setApprovalForAllBWO(
                ownerId,
                operator,
                true,
                owner,
                deadline,
                signature,
                {
                  from: this.operator,
                },
              );
            });

            it('keeps the approval to the given address', async function () {
              const nonce = await this.token.getNonce(owner);
              const signature = signApprovedAllData(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                ownerId,
                operator,
                true,
                owner,
                deadline,
                nonce,
              );

              await this.token.setApprovalForAllBWO(
                ownerId,
                operator,
                true,
                owner,
                deadline,
                signature,
                {
                  from: this.operator,
                },
              );

              expect(
                await this.token.methods['isApprovedForAll(uint256,address)'](
                  ownerId,
                  operator,
                ),
              ).to.equal(true);
            });

            it('emits an approvalById event', async function () {
              const nonce = await this.token.getNonce(owner);
              const signature = signApprovedAllData(
                this.chainId,
                this.tokenCore.address,
                this.tokenName,
                ownerW.getPrivateKey(),
                this.tokenVersion,
                ownerId,
                operator,
                true,
                owner,
                deadline,
                nonce,
              );
              const { logs } = await this.token.setApprovalForAllBWO(
                ownerId,
                operator,
                true,
                owner,
                deadline,
                signature,
                {
                  from: this.operator,
                },
              );

              expectEvent.inLogs(logs, 'AssetApprovalForAll', {
                from: ownerId,
                to: web3.utils.toChecksumAddress(operator),
                approved: true,
                isBWO: true,
                sender: web3.utils.toChecksumAddress(owner),
                nonce: nonce,
              });
            });
          });
        },
      );

      context('when the operator is the owner', function () {
        it('reverts', async function () {
          const nonce = await this.token.getNonce(owner);
          const signature = signApprovedAllData(
            this.chainId,
            this.tokenCore.address,
            this.tokenName,
            ownerW.getPrivateKey(),
            this.tokenVersion,
            ownerId,
            owner,
            true,
            owner,
            deadline,
            nonce,
          );
          await expectRevert(
            this.token.setApprovalForAllBWO(
              ownerId,
              owner,
              true,
              owner,
              deadline,
              signature,
              {
                from: this.operator,
              },
            ),
            'Asset721: approval to current account',
          );
        });
      });
    });

    describe('getApproved', async function () {
      context('when token is not minted', async function () {
        it('reverts', async function () {
          await expectRevert(
            this.token.getApproved(nonExistentTokenId),
            'Asset721: approved query for nonexistent token',
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
            const nonce = await this.token.getNonce(owner);
            const signature = signApprove(
              this.chainId,
              this.tokenCore.address,
              this.tokenName,
              ownerW.getPrivateKey(),
              this.tokenVersion,
              approved,
              firstTokenId,
              owner,
              deadline,
              nonce,
            );

            await this.token.approveBWO(
              approved,
              firstTokenId,
              owner,
              deadline,
              signature,
              {
                from: this.operator,
              },
            );
          });

          it('returns approved account', async function () {
            expect(await this.token.getApproved(firstTokenId)).to.be.equal(
              web3.utils.toChecksumAddress(approved),
            );
          });
        });
      });
    });
  });

  describe('_mint(address, uint256)', function () {
    it('reverts with a null destination address', async function () {
      await expectRevert(
        this.token.mint(0, firstTokenId),
        'Asset721: mint to the zero id',
      );
    });

    context('with minted token', async function () {
      beforeEach(async function () {
        await this.Metaverse.createAccount(owner, false);

        ({ logs: this.logs } = await this.token.mint(ownerId, firstTokenId));
      });

      it('emits a Transfer event', function () {
        expectEvent.inLogs(this.logs, 'Transfer', {
          from: ZERO_ADDRESS,
          to: web3.utils.toChecksumAddress(owner),
          tokenId: firstTokenId,
        });
      });

      it('creates the token', async function () {
        expect(
          await this.token.methods['balanceOf(uint256)'](ownerId),
        ).to.be.bignumber.equal('1');
        expect(
          await this.token.ownerAccountOf(firstTokenId),
        ).to.bignumber.equal(ownerId);
      });

      it('reverts when adding a token id that already exists', async function () {
        await expectRevert(
          this.token.mint(owner, firstTokenId),
          'Asset721: token already minted',
        );
      });
    });
  });

  describe('_burn', function () {
    it('reverts when burning a non-existent token id', async function () {
      await expectRevert(
        this.token.burn(nonExistentTokenId),
        'Asset721: owner query for nonexistent token',
      );
    });

    context('with minted tokens', function () {
      beforeEach(async function () {
        await this.Metaverse.createAccount(owner, false);

        await this.token.mint(brunOwnerId, firstTokenId);
        await this.token.mint(brunOwnerId, secondTokenId);
      });

      context('with burnt token', function () {
        beforeEach(async function () {
          this.receipt = await this.token.burn(firstTokenId, {
            from: brunOwner,
          });
        });

        it('emits a Transfer event', function () {
          expectEvent(this.receipt, 'Transfer', {
            from: brunOwner,
            to: ZERO_ADDRESS,
            tokenId: firstTokenId,
          });
        });

        it('deletes the token', async function () {
          expect(
            await this.token.methods['balanceOf(address)'](brunOwner),
          ).to.be.bignumber.equal('1');
          await expectRevert(
            this.token.ownerOf(firstTokenId),
            'Asset721: owner query for nonexistent token',
          );
        });

        it('reverts when burning a token id that has been deleted', async function () {
          await expectRevert(
            this.token.burn(firstTokenId),
            'Asset721: owner query for nonexistent token',
          );
        });
      });
    });
  });
}

function signApprove(
  chainId,
  verifyingContract,
  name,
  key,
  version,
  spender,
  tokenId,
  sender,
  deadline,
  nonce,
) {
  const data = {
    types: {
      EIP712Domain,
      approveBWO: [
        {
          name: 'spender',
          type: 'address',
        },
        {
          name: 'tokenId',
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
    primaryType: 'approveBWO',
    message: {
      spender,
      tokenId,
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

function signApproveData(
  chainId,
  verifyingContract,
  name,
  key,
  version,
  to,
  tokenId,
  sender,
  deadline,
  nonce,
) {
  const data = {
    types: {
      EIP712Domain,
      approveBWO: [
        {
          name: 'to',
          type: 'address',
        },
        {
          name: 'tokenId',
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
    primaryType: 'approveBWO',
    message: {
      to,
      tokenId,
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

function signApprovedAllData(
  chainId,
  verifyingContract,
  name,
  key,
  version,
  from,
  to,
  approved,
  sender,
  deadline,
  nonce,
) {
  const data = {
    types: {
      EIP712Domain,
      setApprovalForAllBWO: [
        {
          name: 'from',
          type: 'uint256',
        },
        {
          name: 'to',
          type: 'address',
        },
        {
          name: 'approved',
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
      name,
      version,
      chainId,
      verifyingContract,
    },
    primaryType: 'setApprovalForAllBWO',
    message: {
      from,
      to,
      approved,
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

function signTransferData(
  chainId,
  verifyingContract,
  name,
  key,
  version,
  from,
  to,
  tokenId,
  sender,
  deadline,
  nonce,
) {
  const data = {
    types: {
      EIP712Domain,
      transferFromBWO: [
        {
          name: 'from',
          type: 'uint256',
        },
        {
          name: 'to',
          type: 'uint256',
        },
        {
          name: 'tokenId',
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
    primaryType: 'transferFromBWO',
    message: {
      from,
      to,
      tokenId,
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

function signSafeTransferData(
  chainId,
  verifyingContract,
  name,
  key,
  version,
  from,
  to,
  tokenId,
  sender,
  deadline,
  nonce,
  payload,
) {
  let data;
  if (payload == null) {
    data = {
      types: {
        EIP712Domain,
        safeTransferFromBWO: [
          {
            name: 'from',
            type: 'uint256',
          },
          {
            name: 'to',
            type: 'uint256',
          },
          {
            name: 'tokenId',
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
      primaryType: 'safeTransferFromBWO',
      message: {
        from,
        to,
        tokenId,
        sender,
        nonce,
        deadline,
      },
    };
  } else {
    data = {
      types: {
        EIP712Domain,
        safeTransferFromBWO: [
          {
            name: 'from',
            type: 'uint256',
          },
          {
            name: 'to',
            type: 'uint256',
          },
          {
            name: 'tokenId',
            type: 'uint256',
          },
          {
            name: 'data',
            type: 'bytes',
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
      primaryType: 'safeTransferFromBWO',
      message: {
        from,
        to,
        tokenId,
        data: payload,
        sender,
        nonce,
        deadline,
      },
    };
  }

  const signature = ethSigUtil.signTypedMessage(key, {
    data,
  });

  return signature;
}

module.exports = {
  shouldBehaveLikeAsset721BWO,
};
