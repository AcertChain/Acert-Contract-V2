const {
  BN,
  constants,
  expectEvent,
  expectRevert,
} = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { artifacts, ethers } = require('hardhat');
const { ZERO_ADDRESS } = constants;

const Asset20 = artifacts.require('MogaToken');
const Asset20Storage = artifacts.require('Asset20Storage');
const World = artifacts.require('MonsterGalaxy');
const WorldStorage = artifacts.require('WorldStorage');
const Metaverse = artifacts.require('MogaMetaverse');
const MetaverseStorage = artifacts.require('MetaverseStorage');
const Miner = artifacts.require('Miner');

const name = 'My Token';
const symbol = 'MTKN';
const version = '1.0.0';
const initialSupply = new BN(100);

contract('Miner', function (accounts) {
  beforeEach(async function () {
    const [minerA, minerB, minerC] = accounts;
    this.minerA = minerA;
    this.minerB = minerB;
    this.minerC = minerC;

    this.MetaverseStorage = await MetaverseStorage.new();
    this.Metaverse = await Metaverse.new(
      'metaverse',
      '1.0',
      0,
      this.MetaverseStorage.address,
    );
    await this.MetaverseStorage.updateMetaverse(this.Metaverse.address);

    this.WorldStorage = await WorldStorage.new();
    this.world = await World.new(
      this.Metaverse.address,
      this.WorldStorage.address,
      'world',
      '1.0',
    );
    await this.WorldStorage.updateWorld(this.world.address);

    this.tokenStorage = await Asset20Storage.new();
    this.token = await Asset20.new(
      name,
      symbol,
      version,
      this.world.address,
      this.tokenStorage.address,
    );
    await this.tokenStorage.updateAsset(this.token.address);

    // register world
    await this.Metaverse.registerWorld(this.world.address);

    // register token
    await this.world.registerAsset(this.token.address);

    this.miner = await Miner.new();

    // register miner
    await this.token.transferOwnership(this.miner.address);

    await this.miner.addMiner(minerA);
    await this.miner.addMiner(minerB);
    await this.miner.addMiner(minerC);
  });

  it('token miner equal miner', async function () {
    expect(await this.token.owner()).to.equal(this.miner.address);
  });

  it('check miner', async function () {
    expect(await this.miner.isMiner(this.minerA)).to.equal(true);
    expect(await this.miner.isMiner(this.minerB)).to.equal(true);
    expect(await this.miner.isMiner(this.minerC)).to.equal(true);
  });

  it('mint token', async function () {
    const abiEncodedCall = web3.eth.abi.encodeFunctionCall(
      {
        name: 'mint',
        type: 'function',
        inputs: [
          {
            type: 'address',
            name: 'account',
          },
          {
            type: 'uint256',
            name: 'amount',
          },
        ],
      },
      [this.minerA, initialSupply],
    );

    await this.miner.call(this.token.address, abiEncodedCall, {
      from: this.minerA,
    });
    expect(await this.token.totalSupply()).to.be.bignumber.equal(initialSupply);
    expect(
      await this.token.methods['balanceOf(address)'](this.minerA),
    ).to.be.bignumber.equal(initialSupply);
  });

  it('transfer owner', async function () {
    const abiEncodedCall = web3.eth.abi.encodeFunctionCall(
      {
        name: 'transferOwnership',
        type: 'function',
        inputs: [
          {
            type: 'address',
            name: 'newOwner',
          },
        ],
      },
      [this.minerA],
    );

    await this.miner.call(this.token.address, abiEncodedCall, {
      from: this.minerA,
    });
    expect(await this.token.owner()).to.equal(this.minerA);
  });
});
