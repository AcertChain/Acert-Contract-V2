const {
  shouldBehaveLikeWorld,
  shouldBehaveLikeWorldOperator,
  shouldBehaveLikeWorldTrust,
  shouldBehaveLikeWorldAsset,
} = require('./World.behavior');

const Metaverse = artifacts.require('Metaverse');
const MetaverseCore = artifacts.require('MetaverseCore');
const MetaverseStorage = artifacts.require('MetaverseStorage');

const World = artifacts.require('World');
const WorldCore = artifacts.require('WorldCore');
const WorldStorage = artifacts.require('WorldStorage');

const Asset721 = artifacts.require('MogaNFT_V3');
const Asset721Core = artifacts.require('Asset721Core');
const Asset721Storage = artifacts.require('Asset721Storage');

const Asset20 = artifacts.require('MogaToken_V3');
const Asset20Core = artifacts.require('Asset20Core');
const Asset20Storage = artifacts.require('Asset20Storage');


contract('World', function (accounts) {
  const itemName = 'Non Fungible Token';
  const itemSymbol = 'NFT';
  const itemVersion = '1.0.0';

  const cashName = 'My Token';
  const cashSymbol = 'MTKN';
  const cashVersion = '1.0.0';

  const remark = 'remark';
  const version = '1.0.0';


  beforeEach(async function () {
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


    // deploy world
    this.worldName = 'world';
    this.worldVersion = version;

    this.WorldStorage = await WorldStorage.new();
    this.WorldCore = await WorldCore.new(
      this.worldName,
      this.worldVersion,
      this.Metaverse.address,
      this.WorldStorage.address,
    );
    this.World = await World.new();

    await this.WorldStorage.updateWorld(this.WorldCore.address);
    await this.WorldCore.updateShell(this.World.address);
    await this.World.updateCore(this.WorldCore.address);


    this.newWorldName = 'newWorld';

    this.newWorldStorage = await WorldStorage.new();
    this.newWorldCore = await WorldCore.new(
      this.newWorldName,
      this.worldVersion,
      this.Metaverse.address,
      this.WorldStorage.address,
    );
    this.newWorld = await World.new();

    await this.newWorldStorage.updateWorld(this.newWorldCore.address);
    await this.newWorldCore.updateShell(this.newWorld.address);
    await this.newWorld.updateCore(this.newWorldCore.address);

    this.chainId = await this.WorldCore.getChainId();

    // deploy token
    this.tokenStorage = await Asset20Storage.new();
    this.asset20tokenCore = await Asset20Core.new(
      cashName,
      cashSymbol,
      cashVersion,
      this.World.address,
      this.tokenStorage.address,
    );
    this.asset20 = await Asset20.new();

    await this.tokenStorage.updateAsset(this.asset20tokenCore.address);
    await this.asset20tokenCore.updateShell(this.asset20.address);
    await this.asset20.updateCore(this.asset20tokenCore.address);

    await this.asset20.updateMiner(await this.asset20.owner(), true);


    this.tokenStorage = await Asset721Storage.new();
    this.asset721tokenCore = await Asset721Core.new(
      itemName,
      itemSymbol,
      itemVersion,
      '',
      this.World.address,
      this.tokenStorage.address,
    );
    this.asset721 = await Asset721.new();

    await this.tokenStorage.updateAsset(this.asset721tokenCore.address);
    await this.asset721tokenCore.updateShell(this.asset721.address);
    await this.asset721.updateCore(this.asset721tokenCore.address);

    await this.asset721.updateMiner(await this.asset721.owner(), true);

    // register world
    await this.MetaverseCore.registerWorld(this.World.address);
  });

  shouldBehaveLikeWorld(...accounts);
  shouldBehaveLikeWorldOperator(...accounts);
  shouldBehaveLikeWorldTrust(...accounts);
  shouldBehaveLikeWorldAsset(...accounts);
});
