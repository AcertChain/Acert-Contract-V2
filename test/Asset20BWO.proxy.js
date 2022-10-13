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
const {
  web3, ethers
} = require('hardhat');

const Wallet = require('ethereumjs-wallet').default;


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


function shouldBehaveLikeAsset20ProxyBWO(errorPrefix, initialSupply, initialHolder, initialHolderId,
  recipient, recipientId, authAccount, BWOKey) {

  describe('transferCashBWO proxy and approveCashBWO proxy', function () {

    beforeEach(async function () {
      this.domain = {
        name: "metaverse",
        version: "1.0",
        chainId: this.chainId.toString(),
        verifyingContract: this.Metaverse.address
      };

      this.signAuthTypes = {
        AddAuth: [
          {
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
      };

      const value = { id: initialHolderId.toString(), addr: authAccount, sender: initialHolder, nonce: '0', deadline: deadline.toString() };

      this.initialHolderSinger = await ethers.getSigner(initialHolder)

      this.authAccountSinger = await ethers.getSigner(authAccount)

      const signature = await this.authAccountSinger._signTypedData(this.domain, this.signAuthTypes, value)

      await this.Metaverse.addAuthAddress(initialHolderId, authAccount, deadline, signature, {
        from: initialHolder
      });


    });

    it('addAuthAddress', async function () {
      expect(await this.Metaverse.getAccountIdByAddress(authAccount)).to.be.bignumber.equal(initialHolderId);
    })

    it('addAuthAddressBWO', async function () {
      await this.Metaverse.removeAuthAddress(initialHolderId, authAccount, { from: initialHolder });

      expect(await this.Metaverse.getAccountIdByAddress(authAccount)).to.be.bignumber.equal(new BN(0));

      const value = { id: initialHolderId.toString(), addr: authAccount, sender: initialHolder, nonce: '1', deadline: deadline.toString() };

      const authSignature = await this.authAccountSinger._signTypedData(this.domain, this.signAuthTypes, value)

      const nonce = await this.Metaverse.getNonce(initialHolder);

      const BWOType = {
        BWO: [
          {
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
      };

      const BWOvalue = { id: initialHolderId.toString(), addr: authAccount, sender: initialHolder, nonce: nonce.toString(), deadline: deadline.toString() };


      const signature = await this.initialHolderSinger._signTypedData(this.domain, BWOType, BWOvalue)


      await this.Metaverse.addAuthAddressBWO(initialHolderId, authAccount, initialHolder, deadline, signature, authSignature, {
        from: this.BWO
      })

      expect(await this.Metaverse.getAccountIdByAddress(authAccount)).to.be.bignumber.equal(initialHolderId);

    })

    it('approve', async function () {
      await this.token.methods['approve(address,uint256)'](recipient, initialSupply, {
        from: authAccount
      });

      expect(await this.token.methods['allowance(uint256,address)'](initialHolderId, recipient)).to.be.bignumber.equal(initialSupply);
    });

    it('approveAsset', async function () {
      await this.token.methods['approve(uint256,address,uint256)'](initialHolderId, recipient, initialSupply, {
        from: authAccount
      });

      expect(await this.token.methods['allowance(uint256,address)'](initialHolderId, recipient)).to.be.bignumber.equal(initialSupply);

    });

    it('balanceOf', async function () {
      expect(await this.token.methods['balanceOf(address)'](initialHolder)).to.be.bignumber.equal(await this.token.methods['balanceOf(address)'](authAccount));
    })

    it('transfer', async function () {
      await this.token.transfer(recipient, initialSupply, {
        from: authAccount
      });

      expect(await this.token.methods['balanceOf(address)'](recipient)).to.be.bignumber.equal(initialSupply);

    });

    it('transferFrom', async function () {
      expect(await this.token.methods['balanceOf(address)'](authAccount)).to.be.bignumber.equal(initialSupply);

      await this.token.methods['transferFrom(address,address,uint256)'](authAccount, recipient, initialSupply, { from: authAccount });

      expect(await this.token.methods['balanceOf(address)'](recipient)).to.be.bignumber.equal(initialSupply);

    });

    it('transferFromAsset', async function () {
      await this.token.methods['transferFrom(uint256,uint256,uint256)'](initialHolderId, recipientId, initialSupply, { from: authAccount });

      expect(await this.token.methods['balanceOf(address)'](recipient)).to.be.bignumber.equal(initialSupply);
    });

    it('approveAssetBWO proxy', async function () {
      const nonce = await this.token.getNonce(authAccount);
      
      domain = {
        name: this.tokenName,
        version: this.tokenVersion,
        chainId: this.chainId.toString(),
        verifyingContract: this.token.address
      };

      const BWOType = {
        BWO: [
          {
            name: 'ownerId',
            type: 'uint256'
          },
          {
            name: 'spender',
            type: 'address'
          },
          {
            name: 'amount',
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
      };

      const signature = await this.authAccountSinger._signTypedData(domain, BWOType, { ownerId: initialHolderId.toString(), spender: recipient, amount: initialSupply.toString(), sender: authAccount, nonce: nonce.toString(), deadline: deadline.toString() })


      expectEvent(await this.token.approveBWO(initialHolderId, recipient, initialSupply, authAccount, deadline, signature, {
        from: this.BWO
      }), 'AssetApproval', {
        owner: initialHolderId,
        spender: web3.utils.toChecksumAddress(recipient),
        value: initialSupply,
        isBWO: true,
        sender: authAccount,
        nonce: nonce
      });

      expect(await this.token.methods['allowance(uint256,address)'](initialHolderId, recipient)).to.be.bignumber.equal(initialSupply);

    });

    it('transferAssetBWO proxy', async function () {

      const nonce = await this.token.getNonce(authAccount);

      domain = {
        name: this.tokenName,
        version: this.tokenVersion,
        chainId: this.chainId.toString(),
        verifyingContract: this.token.address
      };

      const BWOType = {
        BWO: [
          {
            name: 'from',
            type: 'uint256'
          },
          {
            name: 'to',
            type: 'uint256'
          },
          {
            name: 'amount',
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
      };

      const signature = await this.authAccountSinger._signTypedData(domain, BWOType, { from: initialHolderId.toString(), to: recipientId.toString(), amount: initialSupply.toString(), sender: authAccount, nonce: nonce.toString(), deadline: deadline.toString() })

      await this.token.transferFromBWO(initialHolderId, recipientId, initialSupply, authAccount, deadline, signature, {
        from: this.BWO
      });

      expect(await this.token.methods['balanceOf(address)'](recipient)).to.be.bignumber.equal(initialSupply);
    });

  });
}

function signApproveData(chainId, verifyingContract, name, key, version,
  ownerId, spender, amount, sender, deadline, nonce) {
  const data = {
    types: {
      EIP712Domain,
      BWO: [{
        name: 'ownerId',
        type: 'uint256'
      },
      {
        name: 'spender',
        type: 'address'
      },
      {
        name: 'amount',
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
      ownerId,
      spender,
      amount,
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

function signTransferData(chainId, verifyingContract, name, key, version,
  sender, from, to, value, deadline, nonce) {
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
      value,
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

function signAddAuthAddressBWO(chainId, verifyingContract, name, key, version, id, addr, sender, nonce, deadline) {
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


function signAddAuthAddress(chainId, verifyingContract, name, key, version, id, addr, sender, nonce, deadline) {
  const data = {
    types: {
      EIP712Domain,
      AddAuth: [{
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
    primaryType: 'AddAuth',
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

function signRemoveAuthAddressBWO(chainId, verifyingContract, name, key, version, id, addr, sender, nonce, deadline) {
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
  shouldBehaveLikeAsset20ProxyBWO,
};



