const {
    shouldBehaveLikeERC721,
    shouldBehaveLikeERC721Metadata,
  } = require('./ERC721.behavior');
  
const Item721 = artifacts.require('Item721');
const World = artifacts.require('World');

contract('Item721', function (accounts) {
    const name = 'Non Fungible Token';
    const symbol = 'NFT';
    const version = '1.0.0';

    const worldName = 'My World';
    const worldSymbol = 'MW';
    const worldSupply = 100;

    beforeEach(async function () {
        this.world = await World.new(worldName, worldSymbol,worldSupply);
        this.token = await Item721.new(name, symbol,version , this.world.address);
    });

    shouldBehaveLikeERC721('Item', ...accounts);
    shouldBehaveLikeERC721Metadata('Item', name, symbol, ...accounts);
});
  
