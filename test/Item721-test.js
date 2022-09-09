const {
  shouldBehaveLikeERC721,
  shouldBehaveLikeERC721Metadata,
} = require('./ERC721.behavior');

const {
  shouldBehaveLikeItem721,
} = require('./Item721.behavior');

const {
  shouldBehaveLikeItem721BWO,
} = require('./Item721BWO.behavior');

const {
  shouldBehaveLikeItem721ProxyBWO,
} = require('./Item721BWO.proxy');

const Item721 = artifacts.require('Item721Mock');
const World = artifacts.require('MogaWorld');
const WorldStorage = artifacts.require('WorldStorage');
const Metaverse = artifacts.require('MogaMetaverse');
const MetaverseStorage = artifacts.require('MetaverseStorage');

contract('Item721', function (accounts) {
  const name = 'Non Fungible Token';
  const symbol = 'NFT';
  const version = '1.0.0';


  const [op] = accounts;

  beforeEach(async function () {
    this.MetaverseStorage = await MetaverseStorage.new();
    this.Metaverse = await Metaverse.new("metaverse", "1.0", 0,this.MetaverseStorage.address);
    await this.MetaverseStorage.updateMetaverse(this.Metaverse.address);

    this.WorldStorage = await WorldStorage.new();
    this.world = await World.new(this.Metaverse.address,this.WorldStorage.address, "world", "1.0");
    await this.WorldStorage.updateWorld(this.world.address);

    this.token = await Item721.new(name, symbol, version, "testURI", this.world.address);
    this.chainId = await this.token.getChainId();
    this.tokenName = name;
    this.tokenVersion = version;
    this.operator = op;

    // register world
    await this.Metaverse.registerWorld(this.world.address, "", "", "", "");

    // register token
    await this.world.registerAsset(this.token.address, "");

    await this.world.addOperator(op);
  });

  shouldBehaveLikeItem721BWO();
  shouldBehaveLikeItem721('Item', ...accounts);
  shouldBehaveLikeERC721('Item', ...accounts);
  shouldBehaveLikeERC721Metadata('Item', name, symbol, ...accounts);
  shouldBehaveLikeItem721ProxyBWO();
});