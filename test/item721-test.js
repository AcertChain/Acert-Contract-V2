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

const Item721 = artifacts.require('Item721Mock');
const World = artifacts.require('World');
const Metaverse = artifacts.require('Metaverse');

contract('Item721', function (accounts) {
  const name = 'Non Fungible Token';
  const symbol = 'NFT';
  const version = '1.0.0';


  const [op] = accounts;

  beforeEach(async function () {
    this.Metaverse = await Metaverse.new("metaverse", "1.0");
    this.world = await World.new(this.Metaverse.address, "world", "1.0");
    this.token = await Item721.new(name, symbol, version, "testURI", this.world.address);
    this.chainId = await this.token.getChainId();
    this.tokenName = name;
    this.tokenVersion = version;
    this.operator = op;

    await this.world.addOperator(op);
  });

  shouldBehaveLikeItem721BWO();
  shouldBehaveLikeItem721('Item', ...accounts);
  shouldBehaveLikeERC721('Item', ...accounts);
  shouldBehaveLikeERC721Metadata('Item', name, symbol, ...accounts);
});