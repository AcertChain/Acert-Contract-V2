const hre = require("hardhat");
const dotenv = require('dotenv');
const { saveToJSON } = require("./utils");


dotenv.config();

const Asset20Name = "Galaxy Gem";
const Asset20Symbol = "GGM";

const Asset721Name = "MOGA";
const Asset721Symbol = "MOGA";
const Asset721URI = "https://mintinfo.playmonstergalaxy.com/json/moga/";

const Asset721NameE = "MOGA Equipment";
const Asset721SymbolE = "EQPT";
const Asset721URIE = "https://mintinfo.playmonstergalaxy.com/json/equipment/";


async function main() {
  // We get the contract to deploy
  const [deployer] = await ethers.getSigners();
  // deploy Metaverse Storage
  const MetaverseStorage = (await ethers.getContractFactory("MetaverseStorage")).connect(deployer);
  const MScontract = await MetaverseStorage.deploy();
  await MScontract.deployed();

  saveToJSON("MetaverseStorage", {
    address: MScontract.address,
    deployer: deployer.address
  })


  //deploy Metaverse 
  const Metaverse = (await ethers.getContractFactory("MogaMetaverse")).connect(deployer);
  const Mcontract = await Metaverse.deploy("Metaverse", "1.0", 0, MScontract.address);
  await Mcontract.deployed();

  saveToJSON("Metaverse", {
    address: Mcontract.address,
    deployer: deployer.address
  })

  await (await MScontract.updateMetaverse(Mcontract.address)).wait();

  //deploy world storage
  const WorldStorage = (await ethers.getContractFactory("WorldStorage")).connect(deployer);
  const WScontract = await WorldStorage.deploy();
  await WScontract.deployed();

  saveToJSON("WorldStorage", {
    address: WScontract.address,
    deployer: deployer.address
  })

  //deploy world
  const World = (await ethers.getContractFactory("MonsterGalaxy")).connect(deployer);
  const Wcontract = await World.deploy(Mcontract.address, WScontract.address, "World", "1.0");
  await Wcontract.deployed();

  saveToJSON("World", {
    address: Wcontract.address,
    deployer: deployer.address
  })


  await (await WScontract.updateWorld(Wcontract.address)).wait()
  // register world
  await (await Mcontract.registerWorld(Wcontract.address)).wait();

  // deploy Asset20 Storage
  const Asset20Storage = (await ethers.getContractFactory("Asset20Storage")).connect(deployer);

  const A20Scontract = await Asset20Storage.deploy();
  await A20Scontract.deployed();

  saveToJSON("Asset20Storage", {
    address: A20Scontract.address,
    deployer: deployer.address
  })

  //deploy Asset20
  const Asset20 = (await ethers.getContractFactory("MogaToken")).connect(deployer);
  const Ccontract = await Asset20.deploy(Asset20Name, Asset20Symbol, "1.0", Wcontract.address, A20Scontract.address);
  await Ccontract.deployed();

  saveToJSON(Asset20Name, {
    address: Ccontract.address,
    deployer: deployer.address
  })

  await (await A20Scontract.updateAsset(Ccontract.address)).wait();


  // deploy Asset721M Storage
  const Asset721MStorage = (await ethers.getContractFactory("Asset721Storage")).connect(deployer);

  const A721MScontract = await Asset721MStorage.deploy();
  await A721MScontract.deployed();

  saveToJSON("Asset721MStorage", {
    address: A721MScontract.address,
    deployer: deployer.address
  })

  //deploy Asset721
  const Asset721M = (await ethers.getContractFactory("MogaNFT")).connect(deployer);
  const IMcontract = await Asset721M.deploy(Asset721Name, Asset721Symbol, "1.0", Asset721URI, Wcontract.address, A721MScontract.address);
  await IMcontract.deployed();

  saveToJSON(Asset721Name, {
    address: IMcontract.address,
    deployer: deployer.address
  })

  await (await A721MScontract.updateAsset(IMcontract.address)).wait();

  // deploy Asset721E Storage
  const Asset721EStorage = (await ethers.getContractFactory("Asset721Storage")).connect(deployer);

  const A721EScontract = await Asset721EStorage.deploy();
  await A721EScontract.deployed();

  saveToJSON("Asset721EStorage", {
    address: A721EScontract.address,
    deployer: deployer.address
  })

  //deploy Asset721
  const Asset721E = (await ethers.getContractFactory("MogaNFT")).connect(deployer);
  const IEcontract = await Asset721E.deploy(Asset721NameE, Asset721SymbolE, "1.0", Asset721URIE, Wcontract.address, A721EScontract.address);
  await IEcontract.deployed();

  saveToJSON(Asset721NameE, {
    address: IEcontract.address,
    deployer: deployer.address
  })

  await (await A721EScontract.updateAsset(IEcontract.address)).wait();

  await (await Wcontract.registerAsset(IMcontract.address)).wait();
  await (await Wcontract.registerAsset(IEcontract.address)).wait();
  await (await Wcontract.registerAsset(Ccontract.address)).wait();


  console.log("Metaverse deployed to", Mcontract.address);
  console.log("World deployed to", Wcontract.address);
  console.log("Asset20 GGM deployed to", Ccontract.address);
  console.log("Asset721 MOGA deployed to", IMcontract.address);
  console.log("Asset721 MOGA Equipment deployed to", IEcontract.address);
  console.log("deployer address:", deployer.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });