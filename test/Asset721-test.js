const {
  shouldBehaveLikeERC721,
  shouldBehaveLikeERC721Metadata,
} = require('./ERC721.behavior');

const {
  shouldBehaveLikeAsset721,
} = require('./Asset721.behavior');

const {
  shouldBehaveLikeAsset721BWO,
} = require('./Asset721BWO.behavior');

const {
  shouldBehaveLikeAsset721Proxy,
} = require('./Asset721BWO.proxy');

const Asset721 = artifacts.require('MogaNFT');
const Asset721Storage = artifacts.require('Asset721Storage');
const World = artifacts.require('MonsterGalaxy');
const WorldStorage = artifacts.require('WorldStorage');
const Metaverse = artifacts.require('MogaMetaverse');
const MetaverseStorage = artifacts.require('MetaverseStorage');

contract('Asset721', function (accounts) {
  const name = 'Non Fungible Token';
  const symbol = 'NFT';
  const version = '1.0.0';


  const [op] = accounts;

  beforeEach(async function () {
    this.MetaverseStorage = await MetaverseStorage.new();
    this.Metaverse = await Metaverse.new("metaverse", "1.0", 0, this.MetaverseStorage.address);
    await this.MetaverseStorage.updateMetaverse(this.Metaverse.address);

    this.WorldStorage = await WorldStorage.new();
    this.world = await World.new(this.Metaverse.address, this.WorldStorage.address, "world", "1.0");
    await this.WorldStorage.updateWorld(this.world.address);

    this.tokenStorage = await Asset721Storage.new();
    this.token = await Asset721.new(name, symbol, version, "testURI", this.world.address, this.tokenStorage.address);
    await this.tokenStorage.updateAsset(this.token.address);

    this.chainId = await this.token.getChainId();
    this.tokenName = name;
    this.tokenVersion = version;
    this.operator = op;

    // register world
    await this.Metaverse.registerWorld(this.world.address);
    // register token
    await this.world.registerAsset(this.token.address);

    await this.world.addOperator(op);
  });

  shouldBehaveLikeERC721('Asset721', ...accounts);
  shouldBehaveLikeERC721Metadata('Asset721', name, symbol, ...accounts);
  shouldBehaveLikeAsset721('Asset721', ...accounts);
  shouldBehaveLikeAsset721BWO(...accounts);
  shouldBehaveLikeAsset721Proxy(...accounts);
});