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
  web3
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


function shouldBehaveLikeCash20ProxyBWO(errorPrefix, initialSupply, initialHolder, initialHolderId,
  recipient, recipientId, anotherAccount, anotherAccountId, BWOKey, receiptKey) {


  describe('transferCashBWO proxy and approveCashBWO proxy', function () {
    beforeEach(async function () {

      this.accountW = Wallet.generate();
      this.authAccount = this.accountW.getChecksumAddressString();

      const nonce = await this.Metaverse.getNonce(initialHolder);
      const signature = signAddAuthProxyAddrBWO(this.chainId, this.Metaverse.address, "metaverse", 
        BWOKey, "1.0", initialHolderId, this.authAccount, initialHolder, nonce, deadline);

      await this.Metaverse.addAuthProxyAddrBWO(initialHolderId, this.authAccount, initialHolder, deadline, signature)
    });

    it('approveCashBWO proxy', async function () {
      const nonce = await this.token.getNonce(this.authAccount);;
      const signature = signApproveData(this.chainId, this.token.address, this.tokenName, this.accountW.getPrivateKey(), this.tokenVersion,
      initialHolderId, recipient, initialSupply, this.authAccount, deadline, nonce);

      expectEvent(await this.token.approveCashBWO(initialHolderId, recipient, initialSupply, this.authAccount, deadline, signature, {
        from: this.BWO
      }), 'ApprovalCashBWO', {
        owner: initialHolderId,
        spender: web3.utils.toChecksumAddress(recipient),
        value: initialSupply,
        sender: this.authAccount,
        nonce: nonce
      });


      expect(await this.token.allowanceCash(initialHolderId, recipient)).to.be.bignumber.equal(initialSupply);

    });

    it('transferCashBWO proxy', async function () {

      const nonce = await this.token.getNonce(this.authAccount);

      const signature = signTransferData(this.chainId, this.token.address, this.tokenName, this.accountW.getPrivateKey(), this.tokenVersion,
        this.authAccount, initialHolderId, recipientId, initialSupply, deadline, nonce);

      await this.token.transferCashBWO(initialHolderId, recipientId, initialSupply, this.authAccount, deadline, signature, {
        from: this.BWO
      });

      expect(await this.token.balanceOf(recipient)).to.be.bignumber.equal(initialSupply);
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

function signRemoveAuthProxyAddrBWO(chainId, verifyingContract, name, key, version, id, addr, sender, nonce, deadline) {
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
  shouldBehaveLikeCash20ProxyBWO,
};



