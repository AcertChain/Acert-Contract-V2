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

function shouldBehaveLikeItem721BWO() {
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

    describe('transferBWO', function () {
      const tokenId = firstTokenId;
      const data = '0x42';

      let logs = null;

      beforeEach(async function () {
        const nonce = await this.token.getNonce(ownerId);
        const signature = signData(this.chainId, this.token.address, this.tokenName,
          ownerW.getPrivateKey(), this.tokenVersion, owner, approvedId, tokenId,
          deadline, nonce);

        await this.token.approveItemBWO(owner, approvedId, tokenId, deadline, signature, {
          from: this.operator
        });

        const nonceAll = await this.token.getNonce(ownerId);

        const signatureAll = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
          ownerW.getPrivateKey(), this.tokenVersion, ownerId, operator, true,
          deadline, nonceAll);

        await this.token.setApprovalForAllItemBWO(ownerId, operator, true, deadline, signatureAll, {
          from: this.operator
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

        it('emits a TransferItemBWO event', async function () {
          expectEvent.inLogs(logs, 'TransferItemBWO', {
            from: ownerId,
            to: this.toWhomId,
            tokenId: tokenId
          });
        });

        it('clears the approval for the token ID', async function () {
          expect(await this.token.getApprovedItem(tokenId)).to.be.bignumber.equal(ZERO);
        });

        it('emits an ApprovalItemBWO event', async function () {
          expectEvent.inLogs(logs, 'ApprovalItemBWO', {
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

      const shouldTransferTokensByUsers = function (transferFunction, data) {
        context('when called by the owner', function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(ownerId);
            let signature;
            if (data == null) {
              signature = signTrasferData(this.chainId, this.token.address, this.tokenName,
                ownerW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, this.toWhomId, tokenId,
                deadline, nonce);
            } else {
              signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                ownerW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, this.toWhomId, tokenId,
                deadline, nonce, data);
            }

            ({
              logs
            } = await transferFunction.call(this, ownerId, ownerId, this.toWhomId, tokenId, signature, {
              from: this.operator
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
            const nonce = await this.token.getNonce(approvedId);
            let signature;
            if (data == null) {

              signature = signTrasferData(this.chainId, this.token.address, this.tokenName,
                approvedW.getPrivateKey(), this.tokenVersion, approvedId, ownerId, this.toWhomId, tokenId,
                deadline, nonce);
            } else {
              signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                approvedW.getPrivateKey(), this.tokenVersion, approvedId, ownerId, this.toWhomId, tokenId,
                deadline, nonce, data);
            }

            ({
              logs
            } = await transferFunction.call(this, approvedId, ownerId, this.toWhomId, tokenId, signature, {
              from: this.operator
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
            const nonce = await this.token.getNonce(operatorId);
            let signature;
            if (data == null) {

              signature = signTrasferData(this.chainId, this.token.address, this.tokenName,
                operatorW.getPrivateKey(), this.tokenVersion, operatorId, ownerId, this.toWhomId, tokenId,
                deadline, nonce);
            } else {
              signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                operatorW.getPrivateKey(), this.tokenVersion, operatorId, ownerId, this.toWhomId, tokenId,
                deadline, nonce, data);
            }

            ({
              logs
            } = await transferFunction.call(this, operatorId, ownerId, this.toWhomId, tokenId, signature, {
              from: this.operator
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
            const nonce = await this.token.getNonce(ownerId);

            const signature = signData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, owner, ZERO, tokenId,
              deadline, nonce);

            await this.token.approveItemBWO(owner, ZERO, tokenId, deadline, signature, {
              from: this.operator
            });

            const nonceCall = await this.token.getNonce(operatorId);
            let signatureCall;
            if (data == null) {
              signatureCall = signTrasferData(this.chainId, this.token.address, this.tokenName,
                operatorW.getPrivateKey(), this.tokenVersion, operatorId, ownerId, this.toWhomId, tokenId,
                deadline, nonceCall);
            } else {
              signatureCall = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                operatorW.getPrivateKey(), this.tokenVersion, operatorId, ownerId, this.toWhomId, tokenId,
                deadline, nonceCall, data);
            }

            ({
              logs
            } = await transferFunction.call(this, operatorId, ownerId, this.toWhomId, tokenId, signatureCall, {
              from: this.operator
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
            const nonce = await this.token.getNonce(ownerId);
            let signature;
            if (data == null) {
              signature = signTrasferData(this.chainId, this.token.address, this.tokenName,
                ownerW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, ownerId, tokenId,
                deadline, nonce);
            } else {
              signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                ownerW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, ownerId, tokenId,
                deadline, nonce, data);
            }
            ({
              logs
            } = await transferFunction.call(this, ownerId, ownerId, ownerId, tokenId, signature, {
              from: this.operator
            }));
          });

          it('keeps ownership of the token', async function () {
            expect(await this.token.ownerOfItem(tokenId)).to.be.bignumber.equal(ownerId);
          });

          it('clears the approval for the token ID', async function () {
            expect(await this.token.getApprovedItem(tokenId)).to.be.bignumber.equal(ZERO);
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
            const nonce = await this.token.getNonce(ownerId);
            let signature;
            if (data == null) {

              signature = signTrasferData(this.chainId, this.token.address, this.tokenName,
                ownerW.getPrivateKey(), this.tokenVersion, ownerId, otherId, otherId, tokenId,
                deadline, nonce);
            } else {
              signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                ownerW.getPrivateKey(), this.tokenVersion, ownerId, otherId, otherId, tokenId,
                deadline, nonce, data);
            }


            await expectRevert(
              transferFunction.call(this, ownerId, otherId, otherId, tokenId, signature, {
                from: this.operator
              }),
              'I19',
            );
          });
        });

        context('when the sender is not authorized for the token id', function () {
          it('reverts', async function () {
            const nonce = await this.token.getNonce(otherId);
            let signature;
            if (data == null) {

              signature = signTrasferData(this.chainId, this.token.address, this.tokenName,
                otherW.getPrivateKey(), this.tokenVersion, otherId, ownerId, otherId, tokenId,
                deadline, nonce);
            } else {
              signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                otherW.getPrivateKey(), this.tokenVersion, otherId, ownerId, otherId, tokenId,
                deadline, nonce, data);
            }
            await expectRevert(
              transferFunction.call(this, otherId, ownerId, otherId, tokenId, signature, {
                from: this.operator
              }),
              'I14',
            );
          });
        });

        context('when the given token ID does not exist', function () {
          it('reverts', async function () {
            const nonce = await this.token.getNonce(ownerId);
            let signature;
            if (data == null) {
              signature = signTrasferData(this.chainId, this.token.address, this.tokenName,
                ownerW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, otherId, nonExistentTokenId,
                deadline, nonce);
            } else {
              signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                ownerW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, otherId, nonExistentTokenId,
                deadline, nonce, data);
            }

            await expectRevert(
              transferFunction.call(this, ownerId, ownerId, otherId, nonExistentTokenId, signature, {
                from: this.operator
              }),
              'I16',
            );
          });
        });

        context('when the address to transfer the token to is the zero id', function () {
          it('reverts', async function () {
            const nonce = await this.token.getNonce(ownerId);
            let signature;
            if (data == null) {
              signature = signTrasferData(this.chainId, this.token.address, this.tokenName,
                ownerW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, ZERO, tokenId,
                deadline, nonce);
            } else {
              signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                ownerW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, ZERO, tokenId,
                deadline, nonce, data);
            }

            await expectRevert(
              transferFunction.call(this, ownerId, ownerId, ZERO, tokenId, signature, {
                from: this.operator
              }),
              'I20',
            );
          });
        });
      };

      describe('via transferFromItemBWO', function () {
        shouldTransferTokensByUsers(function (senderId, fromId, toId, tokenId, signature, opts) {
          return this.token.transferFromItemBWO(senderId, fromId, toId, tokenId, deadline, signature, opts);
        }, null);
      });

      describe('via safeTransferFromItemBWO', function () {
        const safeTransferFromItemBWOWithData = function (senderId, fromId, toId, tokenId, signature, opts) {
          return this.token.methods['safeTransferFromItemBWO(uint256,uint256,uint256,uint256,uint256,bytes,bytes)'](senderId, fromId, toId, tokenId, deadline, data, signature, opts);
        };

        const safeTransferFromItemBWOWithoutData = function (senderId, fromId, toId, tokenId, signature, opts) {
          return this.token.methods['safeTransferFromItemBWO(uint256,uint256,uint256,uint256,uint256,bytes)'](senderId, fromId, toId, tokenId, deadline, signature, opts);
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
              const nonce = await this.token.getNonce(ownerId);

              const signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                ownerW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, this.receiverId, tokenId,
                deadline, nonce, data);

              const receipt = await transferFun.call(this, ownerId, ownerId, this.receiverId, tokenId, signature, {
                from: this.operator
              });

              await expectEvent.inTransaction(receipt.tx, ERC721ReceiverMock, 'Received', {
                operator: this.operator,
                from: web3.utils.toChecksumAddress(owner),
                tokenId: tokenId,
                data: data,
              });
            });

            it('calls onERC721Received from approved', async function () {
              const nonce = await this.token.getNonce(approvedId);
              const signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                approvedW.getPrivateKey(), this.tokenVersion, approvedId, ownerId, this.receiverId, tokenId,
                deadline, nonce, data);

              const receipt = await transferFun.call(this, approvedId, ownerId, this.receiverId, tokenId, signature, {
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
                const nonce = await this.token.getNonce(ownerId);
                const signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
                  ownerW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, this.receiverId, nonExistentTokenId,
                  deadline, nonce, data);

                await expectRevert(
                  transferFun.call(
                    this,
                    ownerId,
                    ownerId,
                    this.receiverId,
                    nonExistentTokenId, signature, {
                      from: this.operator
                    },
                  ),
                  'I16',
                );
              });
            });
          });
        };

        describe('with data', function () {
          shouldTransferSafely(safeTransferFromItemBWOWithData, data);
        });

        describe('without data', function () {
          shouldTransferSafely(safeTransferFromItemBWOWithoutData, null);
        });

        describe('to a receiver contract returning unexpected value', function () {
          it('reverts', async function () {
            const invalidReceiver = await ERC721ReceiverMock.new('0x42', Error.None);
            await this.world.getOrCreateAccountId(invalidReceiver.address);
            const invalidReceiverId = new BN(await this.world.getAccountIdByAddress(invalidReceiver.address));
            const nonce = await this.token.getNonce(ownerId);
            const signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, invalidReceiverId, tokenId,
              deadline, nonce, '0x');

            await expectRevert(
              this.token.safeTransferFromItemBWO(ownerId, ownerId, invalidReceiverId, tokenId, deadline, '0x', signature, {
                from: this.operator
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

            const nonce = await this.token.getNonce(ownerId);
            const signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, revertingReceiverId, tokenId,
              deadline, nonce, '0x');

            await expectRevert(
              this.token.safeTransferFromItemBWO(ownerId, ownerId, revertingReceiverId, tokenId, deadline, '0x', signature, {
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
            const nonce = await this.token.getNonce(ownerId);
            const signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, revertingReceiverId, tokenId,
              deadline, nonce, '0x');

            await expectRevert(
              this.token.safeTransferFromItemBWO(ownerId, ownerId, revertingReceiverId, tokenId, deadline, '0x', signature, {
                from: this.operator
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

            const nonce = await this.token.getNonce(ownerId);
            const signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, revertingReceiverId, tokenId,
              deadline, nonce, '0x');

            await expectRevert.unspecified(
              this.token.safeTransferFromItemBWO(ownerId, ownerId, revertingReceiverId, tokenId, deadline, '0x', signature, {
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
            const nonce = await this.token.getNonce(ownerId);
            const signature = signSafeTrasferData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, ownerId, ownerId, nonReceiverId, tokenId,
              deadline, nonce, '0x');

            await expectRevert(
              this.token.safeTransferFromItemBWO(ownerId, ownerId, nonReceiverId, tokenId, deadline, '0x', signature, {
                from: this.operator
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

    describe('approveId', function () {
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
          expectEvent.inLogs(logs, 'ApprovalItemBWO', {
            owner: ownerId,
            approved: id,
            tokenId: tokenId,
          });
        });
      };

      context('when clearing approval', function () {
        context('when there was no prior approval', function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(ownerId);
            const signature = signData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, owner, ZERO, tokenId,
              deadline, nonce);
            ({
              logs
            } = await this.token.approveItemBWO(owner, ZERO, tokenId, deadline, signature, {
              from: this.operator
            }));
          });

          itClearsApproval();
          itEmitsApprovalEvent(ZERO);
        });

        context('when there was a prior approval', function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(ownerId);
            const signature = signData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, owner, approvedId, tokenId,
              deadline, nonce);

            await this.token.approveItemBWO(owner, approvedId, tokenId, deadline, signature, {
              from: this.operator
            });

            const nonce2 = await this.token.getNonce(ownerId);
            const signature2 = signData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, owner, ZERO, tokenId,
              deadline, nonce2);
            ({
              logs
            } = await this.token.approveItemBWO(owner, 0, tokenId, deadline, signature2, {
              from: this.operator
            }));
          });

          itClearsApproval();
          itEmitsApprovalEvent(ZERO);
        });
      });

      context('when approving a non-zero id', function () {
        context('when there was no prior approval', function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(ownerId);
            const signature = signData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, owner, approvedId, tokenId,
              deadline, nonce);
            ({
              logs
            } = await this.token.approveItemBWO(owner, approvedId, tokenId, deadline, signature, {
              from: this.operator
            }));
          });

          itApproves(approvedId);
          itEmitsApprovalEvent(approvedId);
        });

        context('when there was a prior approval to the same id', function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(ownerId);
            const signature = signData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, owner, approvedId, tokenId,
              deadline, nonce);

            await this.token.approveItemBWO(owner, approvedId, tokenId, deadline, signature, {
              from: this.operator
            });
            const nonce2 = await this.token.getNonce(ownerId);
            const signature2 = signData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, owner, approvedId, tokenId,
              deadline, nonce2);

            ({
              logs
            } = await this.token.approveItemBWO(owner, approvedId, tokenId, deadline, signature2, {
              from: this.operator
            }));
          });

          itApproves(approvedId);
          itEmitsApprovalEvent(approvedId);
        });

        context('when there was a prior approval to a different id', function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(ownerId);
            const signature = signData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, owner, anotherApprovedId, tokenId,
              deadline, nonce);
            await this.token.approveItemBWO(owner, anotherApprovedId, tokenId, deadline, signature, {
              from: this.operator
            });
            const nonce2 = await this.token.getNonce(ownerId);
            const signature2 = signData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, owner, anotherApprovedId, tokenId,
              deadline, nonce2);
            ({
              logs
            } = await this.token.approveItemBWO(owner, anotherApprovedId, tokenId, deadline, signature2, {
              from: this.operator
            }));
          });

          itApproves(anotherApprovedId);
          itEmitsApprovalEvent(anotherApprovedId);
        });
      });

      context('when the id that receives the approval is the owner', function () {
        it('reverts', async function () {
          const nonce = await this.token.getNonce(ownerId);
          const signature = signData(this.chainId, this.token.address, this.tokenName,
            ownerW.getPrivateKey(), this.tokenVersion, owner, ownerId, tokenId,
            deadline, nonce);
          await expectRevert(
            this.token.approveItemBWO(owner, ownerId, tokenId, deadline, signature, {
              from: this.operator
            }), 'I09',
          );
        });
      });

      context('when the sender does not own the given token ID', function () {
        it('reverts', async function () {
          const nonce = await this.token.getNonce(otherId);
          const signature = signData(this.chainId, this.token.address, this.tokenName,
            otherW.getPrivateKey(), this.tokenVersion, other, approvedId, tokenId,
            deadline, nonce);
          await expectRevert(this.token.approveItemBWO(other, approvedId, tokenId, deadline, signature, {
              from: this.operator
            }),
            'I10');
        });
      });

      context('when the sender is approved for the given token ID', function () {
        it('reverts', async function () {
          const nonce = await this.token.getNonce(ownerId);
          const signature = signData(this.chainId, this.token.address, this.tokenName,
            ownerW.getPrivateKey(), this.tokenVersion, owner, approvedId, tokenId,
            deadline, nonce);

          await this.token.approveItemBWO(owner, approvedId, tokenId, deadline, signature, {
            from: this.operator
          });
          const nonce2 = await this.token.getNonce(approvedId);
          const signature2 = signData(this.chainId, this.token.address, this.tokenName,
            approvedW.getPrivateKey(), this.tokenVersion, approved, anotherApprovedId, tokenId,
            deadline, nonce2);
          await expectRevert(this.token.approveItemBWO(approved, anotherApprovedId, tokenId, deadline, signature2, {
              from: this.operator
            }),
            'I10');
        });
      });

      context('when the sender is an operator', function () {
        beforeEach(async function () {
          const nonce = await this.token.getNonce(ownerId);
          const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
            ownerW.getPrivateKey(), this.tokenVersion, ownerId, operator, true,
            deadline, nonce);
          await this.token.setApprovalForAllItemBWO(ownerId, operator, true, deadline, signature, {
            from: this.operator
          });
          const nonce2 = await this.token.getNonce(operatorId);
          const signature2 = signData(this.chainId, this.token.address, this.tokenName,
            operatorW.getPrivateKey(), this.tokenVersion, operator, approvedId, tokenId,
            deadline, nonce2);
          ({
            logs
          } = await this.token.approveItemBWO(operator, approvedId, tokenId, deadline, signature2, {
            from: this.operator
          }));
        });

        itApproves(approvedId);
        itEmitsApprovalEvent(approvedId);
      });

      context('when the given token ID does not exist', function () {
        it('reverts', async function () {
          const nonce = await this.token.getNonce(operatorId);
          const signature = signData(this.chainId, this.token.address, this.tokenName,
            operatorW.getPrivateKey(), this.tokenVersion, operator, approvedId, nonExistentTokenId,
            deadline, nonce);

          await expectRevert(this.token.approveItemBWO(operator, approvedId, nonExistentTokenId, deadline, signature, {
              from: this.operator
            }),
            'I08');
        });
      });
    });

    describe('setApprovalForAllItemBWO', function () {
      context('when the operator willing to approve is not the owner', function () {
        context('when there is no operator approval set by the sender', function () {
          it('approves the operator', async function () {
            const nonce = await this.token.getNonce(ownerId);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, ownerId, operator, true,
              deadline, nonce);
            await this.token.setApprovalForAllItemBWO(ownerId, operator, true, deadline, signature, {
              from: this.operator
            });

            expect(await this.token.isApprovedForAllItem(ownerId, operator)).to.equal(true);
          });

          it('emits an approvalById event', async function () {
            const nonce = await this.token.getNonce(ownerId);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, ownerId, operator, true,
              deadline, nonce);

            const {
              logs
            } = await this.token.setApprovalForAllItemBWO(ownerId, operator, true, deadline, signature, {
              from: this.operator
            });

            expectEvent.inLogs(logs, 'ApprovalForAllItemBWO', {
              owner: ownerId,
              operator: web3.utils.toChecksumAddress(operator),
              approved: true,
            });
          });
        });

        context('when the operator was set as not approved', function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(ownerId);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, ownerId, operator, false,
              deadline, nonce);

            await this.token.setApprovalForAllItemBWO(ownerId, operator, false, deadline, signature, {
              from: this.operator
            });
          });

          it('approves the operator', async function () {
            const nonce = await this.token.getNonce(ownerId);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, ownerId, operator, true,
              deadline, nonce);
            await this.token.setApprovalForAllItemBWO(ownerId, operator, true, deadline, signature, {
              from: this.operator
            });

            expect(await this.token.isApprovedForAllItem(ownerId, operator)).to.equal(true);
          });

          it('emits an approvalById event', async function () {
            const nonce = await this.token.getNonce(ownerId);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, ownerId, operator, true,
              deadline, nonce);
            const {
              logs
            } = await this.token.setApprovalForAllItemBWO(ownerId, operator, true, deadline, signature, {
              from: this.operator
            });

            expectEvent.inLogs(logs, 'ApprovalForAllItemBWO', {
              owner: ownerId,
              operator: web3.utils.toChecksumAddress(operator),
              approved: true,
            });
          });

          it('can unset the operator approval', async function () {
            const nonce = await this.token.getNonce(ownerId);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, ownerId, operator, false,
              deadline, nonce);
            await this.token.setApprovalForAllItemBWO(ownerId, operator, false, deadline, signature, {
              from: this.operator
            });

            expect(await this.token.isApprovedForAllItem(ownerId, operator)).to.equal(false);
          });
        });

        context('when the operator was already approved', function () {
          beforeEach(async function () {
            const nonce = await this.token.getNonce(ownerId);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, ownerId, operator, true,
              deadline, nonce);
            await this.token.setApprovalForAllItemBWO(ownerId, operator, true, deadline, signature, {
              from: this.operator
            });
          });

          it('keeps the approval to the given address', async function () {
            const nonce = await this.token.getNonce(ownerId);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, ownerId, operator, true,
              deadline, nonce);

            await this.token.setApprovalForAllItemBWO(ownerId, operator, true, deadline, signature, {
              from: this.operator
            });

            expect(await this.token.isApprovedForAllItem(ownerId, operator)).to.equal(true);
          });

          it('emits an approvalById event', async function () {
            const nonce = await this.token.getNonce(ownerId);
            const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, ownerId, operator, true,
              deadline, nonce);
            const {
              logs
            } = await this.token.setApprovalForAllItemBWO(ownerId, operator, true, deadline, signature, {
              from: this.operator
            });

            expectEvent.inLogs(logs, 'ApprovalForAllItemBWO', {
              owner: ownerId,
              operator: web3.utils.toChecksumAddress(operator),
              approved: true,
            });
          });
        });
      });

      context('when the operator is the owner', function () {
        it('reverts', async function () {
          const nonce = await this.token.getNonce(ownerId);
          const signature = signApprovedAllData(this.chainId, this.token.address, this.tokenName,
            ownerW.getPrivateKey(), this.tokenVersion, ownerId, owner, true,
            deadline, nonce);
          await expectRevert(this.token.setApprovalForAllItemBWO(ownerId, owner, true, deadline, signature, {
              from: this.operator
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
            const nonce = await this.token.getNonce(ownerId);
            const signature = signData(this.chainId, this.token.address, this.tokenName,
              ownerW.getPrivateKey(), this.tokenVersion, owner, approvedId, firstTokenId,
              deadline, nonce);

            await this.token.approveItemBWO(owner, approvedId, firstTokenId, deadline, signature, {
              from: this.operator
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
          to: web3.utils.toChecksumAddress(owner),
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
          (this.receipt = await this.token.burn(firstTokenId));
        });

        it('emits a Transfer event', function () {
          expectEvent(this.receipt, 'Transfer', {
            from: web3.utils.toChecksumAddress(owner),
            to: ZERO_ADDRESS,
            tokenId: firstTokenId
          });
        });

        it('emits an Approval event', function () {
          expectEvent(this.receipt, 'Approval', {
            owner: web3.utils.toChecksumAddress(owner),
            approved: ZERO_ADDRESS,
            tokenId: firstTokenId
          });
        });

        it('deletes the token', async function () {
          expect(await this.token.balanceOfItem(ownerId)).to.be.bignumber.equal('1');
          await expectRevert(
            this.token.ownerOf(firstTokenId), 'I08',
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

function signData(chainId, verifyingContract, name, key, version, from, to, tokenId, deadline, nonce) {
  const data = {
    types: {
      EIP712Domain,
      BWO: [{
          name: 'from',
          type: 'address'
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
      nonce,
      deadline
    },
  };

  const signature = ethSigUtil.signTypedMessage(key, {
    data
  });

  return signature;
}

function signApprovedAllData(chainId, verifyingContract, name, key, version, sender, operator, approved, deadline, nonce) {
  const data = {
    types: {
      EIP712Domain,
      BWO: [{
          name: 'sender',
          type: 'uint256'
        },
        {
          name: 'operator',
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
        {
          name: 'approved',
          type: 'bool'
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
      sender,
      operator,
      nonce,
      deadline,
      approved
    },
  };

  const signature = ethSigUtil.signTypedMessage(key, {
    data
  });

  return signature;
}

function signTrasferData(chainId, verifyingContract, name, key, version, sender, from, to, tokenId, deadline, nonce) {
  const data = {
    types: {
      EIP712Domain,
      BWO: [{
          name: 'sender',
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
          name: 'tokenId',
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
      sender,
      from,
      to,
      tokenId,
      nonce,
      deadline
    },
  };

  const signature = ethSigUtil.signTypedMessage(key, {
    data
  });

  return signature;
}

function signSafeTrasferData(chainId, verifyingContract, name, key, version, sender, from, to, tokenId, deadline, nonce, payload) {
  let data;
  if (payload == null) {
    data = {
      types: {
        EIP712Domain,
        BWO: [{
            name: 'sender',
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
            name: 'tokenId',
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
        sender,
        from,
        to,
        tokenId,
        nonce,
        deadline
      },
    };

  } else {
    data = {
      types: {
        EIP712Domain,
        BWO: [{
            name: 'sender',
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
            name: 'tokenId',
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
          {
            name: 'data',
            type: 'bytes'
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
        sender,
        from,
        to,
        tokenId,
        nonce,
        deadline,
        data: payload
      },
    };
  }


  const signature = ethSigUtil.signTypedMessage(key, {
    data
  });

  return signature;
}


module.exports = {
  shouldBehaveLikeItem721BWO,
};