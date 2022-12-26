const {
  BN,
  constants,
  expectEvent,
  expectRevert,
} = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { ZERO_ADDRESS } = constants;

const { web3 } = require('hardhat');

const firstTokenId = new BN('5042');
const secondTokenId = new BN('79217');
const thirdTokenId = new BN('79218');

const ownerId = new BN('1');
const approvedId = new BN('2');

const deadline = new BN(parseInt(new Date().getTime() / 1000) + 36000);

function shouldBehaveLikeAsset721Proxy(
  owner,
  approved,
  anotherApproved,
  authAccount,
) {
  describe('proxy', function () {
    beforeEach(async function () {
      // create account

      await this.Metaverse.createAccount(owner, false);
      await this.Metaverse.createAccount(approved, false);

      await this.token.methods['mint(address,uint256)'](owner, firstTokenId);
      await this.token.methods['mint(address,uint256)'](owner, secondTokenId);
      await this.token.methods['mint(address,uint256)'](approved, thirdTokenId);

      this.domain = {
        name: 'metaverse',
        version: '1.0.0',
        chainId: this.chainId.toString(),
        verifyingContract: this.MetaverseCore.address,
      };

      this.signAuthTypes = {
        AddAuth: [
          {
            name: 'id',
            type: 'uint256',
          },
          {
            name: 'addr',
            type: 'address',
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
      };

      const value = {
        id: ownerId.toString(),
        addr: authAccount,
        sender: owner,
        nonce: '0',
        deadline: deadline.toString(),
      };

      this.ownerSinger = await ethers.getSigner(owner);

      this.authAccountSinger = await ethers.getSigner(authAccount);

      const signature = await this.authAccountSinger._signTypedData(
        this.domain,
        this.signAuthTypes,
        value,
      );

      await this.Metaverse.addAuthAddress(
        ownerId,
        authAccount,
        deadline,
        signature,
        {
          from: owner,
        },
      );
    });

    it('balanceOf proxy', function () {
      it('returns the amount of tokens owned by owner account', async function () {
        expect(
          await this.token.methods['balanceOf(address)'](owner),
        ).to.be.bignumber.equal('2');
      });

      it('returns the amount of tokens owned by auth account', async function () {
        expect(
          await this.token.methods['balanceOf(address)'](authAccount),
        ).to.be.bignumber.equal('2');
      });
    });

    it('ownerOf proxy', async function () {
      expect(
        await this.token.methods['ownerOf(uint256)'](firstTokenId),
      ).to.equal(owner);
      expect(
        await this.token.methods['ownerOf(uint256)'](secondTokenId),
      ).to.equal(owner);
    });

    describe('approve proxy', function () {
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

      const itEmitsApprovalEvent = function (owneraddr, approvedaddr) {
        it('emits an approval event', async function () {
          expectEvent.inLogs(logs, 'Approval', {
            owner: owneraddr,
            approved: approvedaddr,
            tokenId: tokenId,
          });
        });
      };

      context('when clearing approval', function () {
        context('when there was no prior approval', function () {
          beforeEach(async function () {
            ({ logs } = await this.token.approve(ZERO_ADDRESS, tokenId, {
              from: authAccount,
            }));
          });

          itClearsApproval();
          itEmitsApprovalEvent(owner, ZERO_ADDRESS);
        });

        context('when there was a prior approval', function () {
          beforeEach(async function () {
            await this.token.approve(approved, tokenId, {
              from: authAccount,
            });

            ({ logs } = await this.token.approve(ZERO_ADDRESS, tokenId, {
              from: authAccount,
            }));
          });

          itClearsApproval();
          itEmitsApprovalEvent(owner, ZERO_ADDRESS);
        });
      });

      context('when approving a non-zero id', function () {
        context('when there was no prior approval', function () {
          beforeEach(async function () {
            ({ logs } = await this.token.approve(approved, tokenId, {
              from: authAccount,
            }));
          });

          itApproves(approved);
          itEmitsApprovalEvent(owner, approved);
        });

        context('when there was a prior approval to the same id', function () {
          beforeEach(async function () {
            await this.token.approve(approved, tokenId, {
              from: authAccount,
            });

            ({ logs } = await this.token.approve(approved, tokenId, {
              from: authAccount,
            }));
          });

          itApproves(approved);
          itEmitsApprovalEvent(owner, approved);
        });

        context(
          'when there was a prior approval to a different id',
          function () {
            beforeEach(async function () {
              await this.token.approve(approved, tokenId, {
                from: authAccount,
              });

              ({ logs } = await this.token.approve(anotherApproved, tokenId, {
                from: authAccount,
              }));
            });

            itApproves(anotherApproved);
            itEmitsApprovalEvent(owner, anotherApproved);
          },
        );
      });

      context('when the sender does not own the given token ID', function () {
        it('reverts', async function () {
          await expectRevert(
            this.token.approve(anotherApproved, thirdTokenId, {
              from: authAccount,
            }),
            'Asset721: approve caller is not owner nor approved for all',
          );
        });
      });
    });

    it('approveBWO proxy', async function () {
      domain = {
        name: this.tokenName,
        version: this.tokenVersion,
        chainId: this.chainId.toString(),
        verifyingContract: this.tokenCore.address,
      };

      const nonce = await this.token.getNonce(authAccount);
      const BWOType = {
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
      };

      const signature = await this.authAccountSinger._signTypedData(
        domain,
        BWOType,
        {
          spender: approved,
          tokenId: firstTokenId.toString(),
          sender: authAccount,
          nonce: nonce.toString(),
          deadline: deadline.toString(),
        },
      );

      await this.token.approveBWO(
        approved,
        firstTokenId,
        authAccount,
        deadline,
        signature,
        { from: this.operator },
      );

      expect(await this.token.getApproved(firstTokenId)).to.be.equal(
        web3.utils.toChecksumAddress(approved),
      );
    });

    it('setApprovalForAll and isApprovedForAll proxy', async function () {
      await this.token.setApprovalForAll(approved, true, { from: authAccount });

      expect(
        await this.token.methods['isApprovedForAll(address,address)'](
          authAccount,
          approved,
        ),
      ).to.be.equal(true);
    });

    it('setApprovalForAll proxy and isApprovedForAll proxy', async function () {
      domain = {
        name: this.tokenName,
        version: this.tokenVersion,
        chainId: this.chainId.toString(),
        verifyingContract: this.tokenCore.address,
      };

      const nonce = await this.token.getNonce(authAccount);

      const BWOType = {
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
      };

      const signature = await this.authAccountSinger._signTypedData(
        domain,
        BWOType,
        {
          from: ownerId.toString(),
          to: approved,
          approved: true,
          sender: authAccount,
          nonce: nonce.toString(),
          deadline: deadline.toString(),
        },
      );

      await this.token.setApprovalForAllBWO(
        ownerId,
        approved,
        true,
        authAccount,
        deadline,
        signature,
        { from: this.operator },
      );

      expect(
        await this.token.methods['isApprovedForAll(address,address)'](
          owner,
          approved,
        ),
      ).to.be.equal(true);
    });

    it('transferFrom proxy', async function () {
      await this.token.methods['transferFrom(address,address,uint256)'](
        owner,
        approved,
        firstTokenId,
        { from: authAccount },
      );

      expect(await this.token.ownerOf(firstTokenId)).to.be.equal(
        web3.utils.toChecksumAddress(approved),
      );
    });

    it('asset transferFrom proxy', async function () {
      await this.token.methods['transferFrom(uint256,uint256,uint256)'](
        ownerId,
        approvedId,
        firstTokenId,
        { from: authAccount },
      );

      expect(await this.token.ownerOf(firstTokenId)).to.be.equal(
        web3.utils.toChecksumAddress(approved),
      );
    });

    it('transferFromBWO proxy', async function () {
      domain = {
        name: this.tokenName,
        version: this.tokenVersion,
        chainId: this.chainId.toString(),
        verifyingContract: this.tokenCore.address,
      };

      const nonce = await this.token.getNonce(authAccount);

      const BWOType = {
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
      };

      const signature = await this.authAccountSinger._signTypedData(
        domain,
        BWOType,
        {
          from: ownerId.toString(),
          to: approvedId.toString(),
          tokenId: firstTokenId.toString(),
          sender: authAccount,
          nonce: nonce.toString(),
          deadline: deadline.toString(),
        },
      );

      await this.token.transferFromBWO(
        ownerId,
        approvedId,
        firstTokenId,
        authAccount,
        deadline,
        signature,
        { from: this.operator },
      );

      expect(await this.token.ownerOf(firstTokenId)).to.be.equal(
        web3.utils.toChecksumAddress(approved),
      );
    });

    it('safeTransferFrom proxy', async function () {
      await this.token.methods[
        'safeTransferFrom(address,address,uint256,bytes)'
      ](owner, approved, firstTokenId, '0x', { from: authAccount });

      expect(await this.token.ownerOf(firstTokenId)).to.be.equal(
        web3.utils.toChecksumAddress(approved),
      );
    });

    it('asset safeTransferFrom proxy', async function () {
      await this.token.methods[
        'safeTransferFrom(uint256,uint256,uint256,bytes)'
      ](ownerId, approvedId, firstTokenId, '0x', { from: authAccount });

      expect(await this.token.ownerOf(firstTokenId)).to.be.equal(
        web3.utils.toChecksumAddress(approved),
      );
    });

    it('safeTransferFromBWO proxy', async function () {
      domain = {
        name: this.tokenName,
        version: this.tokenVersion,
        chainId: this.chainId.toString(),
        verifyingContract: this.tokenCore.address,
      };

      const nonce = await this.token.getNonce(authAccount);

      const BWOType = {
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
      };

      const signature = await this.authAccountSinger._signTypedData(
        domain,
        BWOType,
        {
          from: ownerId.toString(),
          to: approvedId.toString(),
          tokenId: firstTokenId.toString(),
          data: '0x',
          sender: authAccount,
          nonce: nonce.toString(),
          deadline: deadline.toString(),
        },
      );

      await this.token.safeTransferFromBWO(
        ownerId,
        approvedId,
        firstTokenId,
        '0x',
        authAccount,
        deadline,
        signature,
        { from: this.operator },
      );

      expect(await this.token.ownerOf(firstTokenId)).to.be.equal(
        web3.utils.toChecksumAddress(approved),
      );
    });

    it('burn proxy', async function () {
      await this.token.burn(firstTokenId, { from: authAccount });

      expect(
        await this.token.methods['balanceOf(address)'](authAccount),
      ).to.be.bignumber.equal('1');

      expect(
        await this.token.methods['balanceOf(uint256)'](ownerId),
      ).to.be.bignumber.equal('1');
    });
  });
}

module.exports = {
  shouldBehaveLikeAsset721Proxy,
};
