const {
  shouldBehaveLikeERC721,
  shouldBehaveLikeERC721Metadata,
} = require('./ERC721.behavior');

const { shouldBehaveLikeAsset721 } = require('./Asset721.behavior');

const { shouldBehaveLikeAsset721BWO } = require('./Asset721BWO.behavior');

const { shouldBehaveLikeAsset721Proxy } = require('./Asset721BWO.proxy');

const Acert = artifacts.require('Acert');

const Metaverse = artifacts.require('Metaverse');
const MetaverseCore = artifacts.require('MetaverseCore');
const MetaverseStorage = artifacts.require('MetaverseStorage');

const World = artifacts.require('World');
const WorldCore = artifacts.require('WorldCore');
const WorldStorage = artifacts.require('WorldStorage');

const Asset721 = artifacts.require('MogaNFT_V3');
const Asset721Core = artifacts.require('Asset721Core');
const Asset721Storage = artifacts.require('Asset721Storage');

contract('Asset721', function (accounts) {
  const name = 'Non Fungible Token';
  const symbol = 'NFT';
  const version = '1.0.0';
  const remark = 'remark';

  const [op] = accounts;

  beforeEach(async function () {
    // deploy acert
    this.Acert = await Acert.new();

    // deploy metaverse
    this.Metaverse = await Metaverse.new();
    this.MetaverseStorage = await MetaverseStorage.new();
    this.MetaverseCore = await MetaverseCore.new(
      'metaverse',
      version,
      0,
      this.MetaverseStorage.address,
    );
    await this.MetaverseStorage.updateMetaverse(this.MetaverseCore.address);
    await this.MetaverseCore.updateShell(this.Metaverse.address);
    await this.Metaverse.updateCore(this.MetaverseCore.address);

    await this.Acert.setMetaverse(this.Metaverse.address, true);
    await this.Acert.remark(this.Metaverse.address, remark, '');
    await this.Acert.remark(this.MetaverseCore.address, remark, '');
    await this.Acert.remark(this.MetaverseStorage.address, remark, '');

    // deploy world
    this.WorldStorage = await WorldStorage.new();
    this.WorldCore = await WorldCore.new(
      'wold',
      version,
      this.Metaverse.address,
      this.WorldStorage.address,
    );
    this.World = await World.new();

    await this.WorldStorage.updateWorld(this.WorldCore.address);
    await this.WorldCore.updateShell(this.World.address);
    await this.World.updateCore(this.WorldCore.address);

    await this.Acert.remark(this.World.address, remark, '');
    await this.Acert.remark(this.WorldCore.address, remark, '');
    await this.Acert.remark(this.WorldStorage.address, remark, '');

    this.tokenStorage = await Asset721Storage.new();
    this.tokenCore = await Asset721Core.new(
      name,
      symbol,
      version,
      'testURI',
      this.World.address,
      this.tokenStorage.address,
    );
    this.token = await Asset721.new();

    await this.tokenStorage.updateAsset(this.tokenCore.address);
    await this.tokenCore.updateShell(this.token.address);
    await this.token.updateCore(this.tokenCore.address);

    await this.token.updateMiner(await this.token.owner(), true);

    await this.Acert.remark(this.token.address, remark, '');
    await this.Acert.remark(this.tokenCore.address, remark, '');
    await this.Acert.remark(this.tokenStorage.address, remark, '');

    this.chainId = await this.token.getChainId();
    this.tokenName = name;
    this.tokenVersion = version;
    this.operator = op;

    // register world
    await this.MetaverseCore.registerWorld(this.World.address);

    // register token
    await this.WorldCore.registerAsset(this.token.address);

    await this.WorldCore.addOperator(op);
  });

  shouldBehaveLikeERC721('Asset721', ...accounts);
  shouldBehaveLikeERC721Metadata('Asset721', name, symbol, ...accounts);
  shouldBehaveLikeAsset721('Asset721', ...accounts);
  shouldBehaveLikeAsset721BWO(...accounts);
  shouldBehaveLikeAsset721Proxy(...accounts);
});
