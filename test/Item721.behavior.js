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


const ownerId = new BN(1);
const approvedId = new BN(2);
const anotherApprovedId = new BN(3);
const operatorId = new BN(4);
const otherId = new BN(5);



function shouldBehaveLikeItem721(errorPrefix, owner, approved, anotherApproved, operator, other) {
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
    });

    describe('balanceOfItem', function () {
      context('when the given address owns some tokens', function () {
        it('returns the amount of tokens owned by the given address', async function () {
          expect(await this.token.balanceOfItem(ownerId)).to.be.bignumber.equal('2');
        });
      });

      context('when the given address does not own any tokens', function () {
        it('returns 0', async function () {
          expect(await this.token.balanceOfItem(otherId)).to.be.bignumber.equal('0');
        });
      });

      context('when querying the zero address', function () {
        it('throws', async function () {
          await expectRevert(
            this.token.balanceOfItem(0), 'I07',
          );
        });
      });
    });

    describe('ownerOfItem', function () {
      context('when the given token ID was tracked by this token', function () {
        const tokenId = firstTokenId;

        it('returns the owner of the given token ID', async function () {
          expect(await this.token.ownerOfItem(tokenId)).to.be.bignumber.equal(ownerId);
        });
      });

      context('when the given token ID was not tracked by this token', function () {
        const tokenId = nonExistentTokenId;

        it('reverts', async function () {
          await expectRevert(
            this.token.ownerOfItem(tokenId), 'I08',
          );
        });
      });
    });

    describe('transfersById', function () {
      const tokenId = firstTokenId;
      const data = '0x42';

      let logs = null;

      beforeEach(async function () {
        await this.token.approveItem(ownerId, approvedId, tokenId, {
          from: owner
        });
        await this.token.setApprovalForAllItem(ownerId, operator, true, {
          from: owner
        });
      });

      const transferWasSuccessful = function ({
        owner,
        tokenId,
        approved
      }) {
        it('transfers the ownership of the given token ID to the given address', async function () {
          expect(await this.token.ownerOfItem(tokenId)).to.be.bignumber.equal(this.toWhomId);
        });

        it('emits a TransferItem event', async function () {
          expectEvent.inLogs(logs, 'TransferItem', {
            from: ownerId,
            to: this.toWhomId,
            tokenId: tokenId
          });
        });

        it('clears the approval for the token ID', async function () {
          expect(await this.token.getApprovedItem(tokenId)).to.be.bignumber.equal(ZERO);
        });

        it('emits an ApprovalItem event', async function () {
          expectEvent.inLogs(logs, 'ApprovalItem', {
            owner: ownerId,
            approved: ZERO,
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

      const shouldTransferTokensByUsers = function (transferFunction) {
        context('when called by the owner', function () {
          beforeEach(async function () {
            ({
              logs
            } = await transferFunction.call(this, ownerId, ownerId, this.toWhomId, tokenId, {
              from: owner
            }));
          });
          transferWasSuccessful({
            owner,
            tokenId,
            approved
          });
        });

        context('when called by the approved individual', function () {
          beforeEach(async function () {
            ({
              logs
            } = await transferFunction.call(this, approvedId, ownerId, this.toWhomId, tokenId, {
              from: approved
            }));
          });
          transferWasSuccessful({
            owner,
            tokenId,
            approved
          });
        });

        context('when called by the operator', function () {
          beforeEach(async function () {
            ({
              logs
            } = await transferFunction.call(this, operatorId, ownerId, this.toWhomId, tokenId, {
              from: operator
            }));
          });
          transferWasSuccessful({
            owner,
            tokenId,
            approved
          });
        });

        context('when called by the owner without an approved user', function () {
          beforeEach(async function () {
            await this.token.approveItem(ownerId, ZERO, tokenId, {
              from: owner
            });
            ({
              logs
            } = await transferFunction.call(this, operatorId, ownerId, this.toWhomId, tokenId, {
              from: operator
            }));
          });
          transferWasSuccessful({
            owner,
            tokenId,
            approved: null
          });
        });

        context('when sent to the owner', function () {
          beforeEach(async function () {
            ({
              logs
            } = await transferFunction.call(this, ownerId, ownerId, ownerId, tokenId, {
              from: owner
            }));
          });

          it('keeps ownership of the token', async function () {
            expect(await this.token.ownerOfItem(tokenId)).to.be.bignumber.equal(ownerId);
          });

          it('clears the approval for the token ID', async function () {
            expect(await this.token.getApprovedItem(tokenId)).to.be.bignumber.equal(ZERO);
          });

          it('emits only a transferCash event', async function () {
            expectEvent.inLogs(logs, 'TransferItem', {
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
            await expectRevert(
              transferFunction.call(this, ownerId, otherId, otherId, tokenId, {
                from: owner
              }),
              'I19',
            );
          });
        });

        context('when the sender is not authorized for the token id', function () {
          it('reverts', async function () {
            await expectRevert(
              transferFunction.call(this, otherId, ownerId, otherId, tokenId, {
                from: other
              }),
              'I14',
            );
          });
        });

        context('when the given token ID does not exist', function () {
          it('reverts', async function () {
            await expectRevert(
              transferFunction.call(this, ownerId, ownerId, otherId, nonExistentTokenId, {
                from: owner
              }),
              'I16',
            );
          });
        });

        context('when the address to transfer the token to is the zero id', function () {
          it('reverts', async function () {
            await expectRevert(
              transferFunction.call(this, ownerId, ownerId, 0, tokenId, {
                from: owner
              }),
              'I20',
            );
          });
        });
      };

      describe('via transferFromItem', function () {
        shouldTransferTokensByUsers(function (senderId, fromId, toId, tokenId, opts) {
          return this.token.transferFromItem(senderId, fromId, toId, tokenId, opts);
        });
      });

      describe('via safeTransferFromItem', function () {
        const safeTransferFromItemWithData = function (senderId, fromId, toId, tokenId, opts) {
          return this.token.methods['safeTransferFromItem(uint256,uint256,uint256,uint256,bytes)'](senderId, fromId, toId, tokenId, data, opts);
        };

        const safeTransferFromItemWithoutData = function (senderId, fromId, toId, tokenId, opts) {
          return this.token.methods['safeTransferFromItem(uint256,uint256,uint256,uint256)'](senderId, fromId, toId, tokenId, opts);
        };

        const shouldTransferSafely = function (transferFun, data) {
          describe('to a user account', function () {
            shouldTransferTokensByUsers(transferFun);
          });

          describe('to a valid receiver contract', function () {
            beforeEach(async function () {
              this.receiver = await ERC721ReceiverMock.new(RECEIVER_MAGIC_VALUE, Error.None);
              this.toWhom = this.receiver.address;
              await this.world.getOrCreateAccountId(this.receiver.address);
              this.receiverId = new BN(await this.world.getAccountIdByAddress(this.receiver.address));

            });

            shouldTransferTokensByUsers(transferFun);

            it('calls onERC721Received', async function () {
              const receipt = await transferFun.call(this, ownerId, ownerId, this.receiverId, tokenId, {
                from: owner
              });

              await expectEvent.inTransaction(receipt.tx, ERC721ReceiverMock, 'Received', {
                operator: owner,
                from: owner,
                tokenId: tokenId,
                data: data,
              });
            });

            it('calls onERC721Received from approved', async function () {
              const receipt = await transferFun.call(this, approvedId, ownerId, this.receiverId, tokenId, {
                from: approved
              });

              await expectEvent.inTransaction(receipt.tx, ERC721ReceiverMock, 'Received', {
                operator: approved,
                from: owner,
                tokenId: tokenId,
                data: data,
              });
            });

            describe('with an invalid token id', function () {
              it('reverts', async function () {
                await expectRevert(
                  transferFun.call(
                    this,
                    ownerId,
                    ownerId,
                    this.receiverId,
                    nonExistentTokenId, {
                      from: owner
                    },
                  ),
                  'I16',
                );
              });
            });
          });
        };

        describe('with data', function () {
          shouldTransferSafely(safeTransferFromItemWithData, data);
        });

        describe('without data', function () {
          shouldTransferSafely(safeTransferFromItemWithoutData, null);
        });

        describe('to a receiver contract returning unexpected value', function () {
          it('reverts', async function () {
            const invalidReceiver = await ERC721ReceiverMock.new('0x42', Error.None);
            await this.world.getOrCreateAccountId(invalidReceiver.address);
            const invalidReceiverId = new BN(await this.world.getAccountIdByAddress(invalidReceiver.address));
            await expectRevert(
              this.token.safeTransferFromItem(ownerId, ownerId, invalidReceiverId, tokenId, '0x', {
                from: owner
              }),
              'I15',
            );
          });
        });

        describe('to a receiver contract that reverts with message', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.new(RECEIVER_MAGIC_VALUE, Error.RevertWithMessage);
            await this.world.getOrCreateAccountId(revertingReceiver.address);
            const revertingReceiverId = new BN(await this.world.getAccountIdByAddress(revertingReceiver.address));

            await expectRevert(
              this.token.safeTransferFromItem(ownerId, ownerId, revertingReceiverId, tokenId, '0x', {
                from: owner
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
            await expectRevert(
              this.token.safeTransferFromItem(ownerId, ownerId, revertingReceiverId, tokenId, '0x', {
                from: owner
              }),
              'I15',
            );
          });
        });

        describe('to a receiver contract that panics', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.new(RECEIVER_MAGIC_VALUE, Error.Panic);
            await this.world.getOrCreateAccountId(revertingReceiver.address);
            const revertingReceiverId = new BN(await this.world.getAccountIdByAddress(revertingReceiver.address));

            await expectRevert.unspecified(
              this.token.safeTransferFromItem(ownerId, ownerId, revertingReceiverId, tokenId, '0x', {
                from: owner
              }),
            );
          });
        });

        describe('to a contract that does not implement the required function', function () {
          it('reverts', async function () {
            const nonReceiver = this.token;
            await this.world.getOrCreateAccountId(nonReceiver.address);
            const nonReceiverId = new BN(await this.world.getAccountIdByAddress(nonReceiver.address));

            await expectRevert(
              this.token.safeTransferFromItem(ownerId, ownerId, nonReceiverId, tokenId, '0x', {
                from: owner
              }),
              'I15',
            );
          });
        });
      });
    });

    describe('safe mint', function () {
      const tokenId = fourthTokenId;
      const data = '0x42';

      describe('via safeMint', function () { // regular minting is tested in ERC721Mintable.test.js and others
        it('calls onERC721Received — with data', async function () {
          this.receiver = await ERC721ReceiverMock.new(RECEIVER_MAGIC_VALUE, Error.None);
          const receipt = await this.token.safeMint(this.receiver.address, tokenId, data);

          await expectEvent.inTransaction(receipt.tx, ERC721ReceiverMock, 'Received', {
            from: ZERO_ADDRESS,
            tokenId: tokenId,
            data: data,
          });
        });

        it('calls onERC721Received — without data', async function () {
          this.receiver = await ERC721ReceiverMock.new(RECEIVER_MAGIC_VALUE, Error.None);
          const receipt = await this.token.safeMint(this.receiver.address, tokenId);

          await expectEvent.inTransaction(receipt.tx, ERC721ReceiverMock, 'Received', {
            from: ZERO_ADDRESS,
            tokenId: tokenId,
          });
        });

        context('to a receiver contract returning unexpected value', function () {
          it('reverts', async function () {
            const invalidReceiver = await ERC721ReceiverMock.new('0x42', Error.None);
            await expectRevert(
              this.token.safeMint(invalidReceiver.address, tokenId),
              'I15',
            );
          });
        });

        context('to a receiver contract that reverts with message', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.new(RECEIVER_MAGIC_VALUE, Error.RevertWithMessage);
            await expectRevert(
              this.token.safeMint(revertingReceiver.address, tokenId),
              'ERC721ReceiverMock: reverting',
            );
          });
        });

        context('to a receiver contract that reverts without message', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.new(RECEIVER_MAGIC_VALUE, Error.RevertWithoutMessage);
            await expectRevert(
              this.token.safeMint(revertingReceiver.address, tokenId),
              'I15',
            );
          });
        });

        context('to a receiver contract that panics', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.new(RECEIVER_MAGIC_VALUE, Error.Panic);
            await expectRevert.unspecified(
              this.token.safeMint(revertingReceiver.address, tokenId),
            );
          });
        });

        context('to a contract that does not implement the required function', function () {
          it('reverts', async function () {
            const nonReceiver = this.token;
            await expectRevert(
              this.token.safeMint(nonReceiver.address, tokenId),
              'I15',
            );
          });
        });
      });
    });

    describe('approveItem', function () {
      const tokenId = firstTokenId;

      let logs = null;

      const itClearsApproval = function () {
        it('clears approval for the token', async function () {
          expect(await this.token.getApprovedItem(tokenId)).to.be.bignumber.equal(ZERO);
        });
      };

      const itApproves = function (id) {
        it('sets the approval for the target id', async function () {
          expect(await this.token.getApprovedItem(tokenId)).to.be.bignumber.equal(id);
        });
      };

      const itEmitsApprovalEvent = function (id) {
        it('emits an approval event', async function () {
          expectEvent.inLogs(logs, 'ApprovalItem', {
            owner: ownerId,
            approved: id,
            tokenId: tokenId,
          });
        });
      };

      context('when clearing approval', function () {
        context('when there was no prior approval', function () {
          beforeEach(async function () {
            ({
              logs
            } = await this.token.approveItem(ownerId, ZERO, tokenId, {
              from: owner
            }));
          });

          itClearsApproval();
          itEmitsApprovalEvent(ZERO);
        });

        context('when there was a prior approval', function () {
          beforeEach(async function () {
            await this.token.approveItem(ownerId, approvedId, tokenId, {
              from: owner
            });
            ({
              logs
            } = await this.token.approveItem(ownerId, 0, tokenId, {
              from: owner
            }));
          });

          itClearsApproval();
          itEmitsApprovalEvent(ZERO);
        });
      });

      context('when approving a non-zero id', function () {
        context('when there was no prior approval', function () {
          beforeEach(async function () {
            ({
              logs
            } = await this.token.approveItem(ownerId, approvedId, tokenId, {
              from: owner
            }));
          });

          itApproves(approvedId);
          itEmitsApprovalEvent(approvedId);
        });

        context('when there was a prior approval to the same id', function () {
          beforeEach(async function () {
            await this.token.approveItem(ownerId, approvedId, tokenId, {
              from: owner
            });
            ({
              logs
            } = await this.token.approveItem(ownerId, approvedId, tokenId, {
              from: owner
            }));
          });

          itApproves(approvedId);
          itEmitsApprovalEvent(approvedId);
        });

        context('when there was a prior approval to a different id', function () {
          beforeEach(async function () {
            await this.token.approveItem(ownerId, anotherApprovedId, tokenId, {
              from: owner
            });
            ({
              logs
            } = await this.token.approveItem(ownerId, anotherApprovedId, tokenId, {
              from: owner
            }));
          });

          itApproves(anotherApprovedId);
          itEmitsApprovalEvent(anotherApprovedId);
        });
      });

      context('when the id that receives the approval is the owner', function () {
        it('reverts', async function () {
          await expectRevert(
            this.token.approveItem(ownerId, ownerId, tokenId, {
              from: owner
            }), 'I09',
          );
        });
      });

      context('when the sender does not own the given token ID', function () {
        it('reverts', async function () {
          await expectRevert(this.token.approveItem(otherId, approvedId, tokenId, {
              from: other
            }),
            'I10');
        });
      });

      context('when the sender is approved for the given token ID', function () {
        it('reverts', async function () {
          await this.token.approveItem(ownerId, approvedId, tokenId, {
            from: owner
          });
          await expectRevert(this.token.approveItem(approvedId, anotherApprovedId, tokenId, {
              from: approved
            }),
            'I10');
        });
      });

      context('when the sender is an operator', function () {
        beforeEach(async function () {
          await this.token.setApprovalForAllItem(ownerId, operator, true, {
            from: owner
          });
          ({
            logs
          } = await this.token.approveItem(operatorId, approvedId, tokenId, {
            from: operator
          }));
        });

        itApproves(approvedId);
        itEmitsApprovalEvent(approvedId);
      });

      context('when the given token ID does not exist', function () {
        it('reverts', async function () {
          await expectRevert(this.token.approveItem(operatorId, approvedId, nonExistentTokenId, {
              from: operator
            }),
            'I08');
        });
      });
    });

    describe('setApprovalForAllItem', function () {
      context('when the operator willing to approve is not the owner', function () {
        context('when there is no operator approval set by the sender', function () {
          it('approves the operator', async function () {
            await this.token.setApprovalForAllItem(ownerId, operator, true, {
              from: owner
            });

            expect(await this.token.isApprovedForAllItem(ownerId, operator)).to.equal(true);
          });

          it('emits an approvalById event', async function () {
            const {
              logs
            } = await this.token.setApprovalForAllItem(ownerId, operator, true, {
              from: owner
            });

            expectEvent.inLogs(logs, 'ApprovalForAllItem', {
              owner: ownerId,
              operator: operator,
              approved: true,
            });
          });
        });

        context('when the operator was set as not approved', function () {
          beforeEach(async function () {
            await this.token.setApprovalForAllItem(ownerId, operator, false, {
              from: owner
            });
          });

          it('approves the operator', async function () {
            await this.token.setApprovalForAllItem(ownerId, operator, true, {
              from: owner
            });

            expect(await this.token.isApprovedForAllItem(ownerId, operator)).to.equal(true);
          });

          it('emits an approvalById event', async function () {
            const {
              logs
            } = await this.token.setApprovalForAllItem(ownerId, operator, true, {
              from: owner
            });

            expectEvent.inLogs(logs, 'ApprovalForAllItem', {
              owner: ownerId,
              operator: web3.utils.toChecksumAddress(operator),
              approved: true,
            });
          });

          it('can unset the operator approval', async function () {
            await this.token.setApprovalForAllItem(ownerId, operator, false, {
              from: owner
            });

            expect(await this.token.isApprovedForAllItem(ownerId, operator)).to.equal(false);
          });
        });

        context('when the operator was already approved', function () {
          beforeEach(async function () {
            await this.token.setApprovalForAllItem(ownerId, operator, true, {
              from: owner
            });
          });

          it('keeps the approval to the given address', async function () {
            await this.token.setApprovalForAllItem(ownerId, operator, true, {
              from: owner
            });

            expect(await this.token.isApprovedForAllItem(ownerId, operator)).to.equal(true);
          });

          it('emits an approvalById event', async function () {
            const {
              logs
            } = await this.token.setApprovalForAllItem(ownerId, operator, true, {
              from: owner
            });

            expectEvent.inLogs(logs, 'ApprovalForAllItem', {
              owner: ownerId,
              operator: web3.utils.toChecksumAddress(operator),
              approved: true,
            });
          });
        });
      });

      context('when the operator is the owner', function () {
        it('reverts', async function () {
          await expectRevert(this.token.setApprovalForAllItem(ownerId, owner, true, {
              from: owner
            }),
            'I12');
        });
      });
    });

    describe('getApproved', async function () {
      context('when token is not minted', async function () {
        it('reverts', async function () {
          await expectRevert(
            this.token.getApprovedItem(nonExistentTokenId),
            'I11',
          );
        });
      });

      context('when token has been minted ', async function () {
        it('should return the zero id', async function () {
          expect(await this.token.getApprovedItem(firstTokenId)).to.be.bignumber.equal(
            ZERO,
          );
        });

        context('when account has been approved', async function () {
          beforeEach(async function () {
            await this.token.approveItem(ownerId, approvedId, firstTokenId, {
              from: owner
            });
          });

          it('returns approved account', async function () {
            expect(await this.token.getApprovedItem(firstTokenId)).to.be.bignumber.equal(approvedId);
          });
        });
      });
    });
  });

  describe('_mint(address, uint256)', function () {
    it('reverts with a null destination address', async function () {
      await expectRevert(
        this.token.mint(ZERO_ADDRESS, firstTokenId), 'I17',
      );
    });

    context('with minted token', async function () {
      beforeEach(async function () {
        ({
          logs: this.logs
        } = await this.token.mint(owner, firstTokenId));
      });

      it('emits a Transfer event', function () {
        expectEvent.inLogs(this.logs, 'Transfer', {
          from: ZERO_ADDRESS,
          to: owner,
          tokenId: firstTokenId
        });
      });

      it('creates the token', async function () {
        expect(await this.token.balanceOfItem(ownerId)).to.be.bignumber.equal('1');
        expect(await this.token.ownerOfItem(firstTokenId)).to.bignumber.equal(ownerId);
      });

      it('reverts when adding a token id that already exists', async function () {
        await expectRevert(this.token.mint(owner, firstTokenId), 'I18');
      });
    });
  });

  describe('_burn', function () {
    it('reverts when burning a non-existent token id', async function () {
      await expectRevert(
        this.token.burn(nonExistentTokenId), 'I08',
      );
    });

    context('with minted tokens', function () {
      beforeEach(async function () {
        await this.token.mint(owner, firstTokenId);
        await this.token.mint(owner, secondTokenId);
      });

      context('with burnt token', function () {
        beforeEach(async function () {
          ({
            logs: this.logs
          } = await this.token.burn(firstTokenId));
        });

        it('emits a Transfer event', function () {
          expectEvent.inLogs(this.logs, 'Transfer', {
            from: owner,
            to: ZERO_ADDRESS,
            tokenId: firstTokenId
          });
        });

        it('emits an Approval event', function () {
          expectEvent.inLogs(this.logs, 'Approval', {
            owner,
            approved: ZERO_ADDRESS,
            tokenId: firstTokenId
          });
        });

        it('deletes the token', async function () {
          expect(await this.token.balanceOfItem(ownerId)).to.be.bignumber.equal('1');
          await expectRevert(
            this.token.ownerOfItem(firstTokenId), 'I08',
          );
        });

        it('reverts when burning a token id that has been deleted', async function () {
          await expectRevert(
            this.token.burn(firstTokenId), 'I08',
          );
        });
      });
    });
  });
}

module.exports = {
  shouldBehaveLikeItem721,
};