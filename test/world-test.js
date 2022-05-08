// const {
//   shouldBehaveLikeERC721,
//   shouldBehaveLikeItem721,
//   shouldBehaveLikeERC721Metadata,
//   shouldBehaveLikeWorldAsset,
// } = require('./World.behavior');

// const Cash20 = artifacts.require('Cash20');
// const Item721 = artifacts.require('Item721');
// const World = artifacts.require('World');

// contract('World', function (accounts) {
//   const itemName = 'Non Fungible Token';
//   const itemSymbol = 'NFT';
//   const itemVersion = '1.0.0';

//   const cashName = 'My Token';
//   const cashSymbol = 'MTKN';
//   const cashVersion = '1.0.0';
//   const cashInitialSupply = new BN(100);

//   const worldName = 'My World';
//   const worldSymbol = 'MW';
//   const worldSupply = 100;
  
//   const [ initialHolder] = accounts;
  
//   const initialHolderId = new BN(1);

//   beforeEach(async function () {
//     this.token = await World.new(worldName, worldSymbol, worldSupply);
//     this.item = await Item721.new(itemName, itemSymbol, itemVersion, this.world.address);
//     this.cash = await Cash20.new(cashName, cashSymbol, cashVersion);
//     await this.token.mint(initialHolder, cashInitialSupply);
//     await this.token.getOrCreateAccountId(initialHolder);
//   });

//   shouldBehaveLikeERC721(accounts);
//   shouldBehaveLikeItem721(accounts);
//   shouldBehaveLikeERC721Metadata(name, symbol, ...accounts);
//   shouldBehaveLikeWorldAsset();
// });