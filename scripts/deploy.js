const hre = require("hardhat");
const dotenv = require('dotenv');
const {saveToJSON} = require("./utils");


dotenv.config();

// bsc
// const cash20Name = "Galaxy Gem";
// const cash20Symbol = "GGM";

// const item721Name = "MOGA";
// const item721Symbol = "MOGA";
// const item721URI = "https://moga.taobaozx.net/moga/";

// const item721NameE = "MOGA Equipment";
// const item721SymbolE = "eqpt";
// const item721URIE = "https://moga.ggm.com/equipment";

// heco
const cash20Name = "Galaxy Gem";
const cash20Symbol = "GGM";

const item721Name = "MOGA";
const item721Symbol = "MOGA";
const item721URI = "https://moga.taobaozx.net/moga/";

const item721NameE = "MOGA Equipment";
const item721SymbolE = "EQPT";
const item721URIE = "https://moga.taobaozx.net/equipment/";

async function main() {
  // We get the contract to deploy
  const [deployer] = await ethers.getSigners();
  //deploy Metaverse 
  const Metaverse = (await ethers.getContractFactory("Metaverse")).connect(deployer);
  const Mcontract = await Metaverse.deploy("Metaverse", "1.0", 0);
  await Mcontract.deployed();

  saveToJSON("Metaverse", {
    address: Mcontract.address,
    deployer: deployer.address
  })

  //deploy world
  const World = (await ethers.getContractFactory("World")).connect(deployer);
  const Wcontract = await World.deploy(Mcontract.address, "World", "1.0");
  await Wcontract.deployed();

  saveToJSON("World", {
    address: Wcontract.address,
    deployer: deployer.address
  })

  // register world
  await Mcontract.registerWorld(Wcontract.address, "", "", "", "");

  //deploy cash20
  const Cash20 = (await ethers.getContractFactory("Cash20Mock")).connect(deployer);
  const Ccontract = await Cash20.deploy(cash20Name, cash20Symbol, "1.0", Wcontract.address);
  await Ccontract.deployed();

  saveToJSON(cash20Name, {
    address: Ccontract.address,
    deployer: deployer.address
  })

  //deploy Item721
  const Item721M = (await ethers.getContractFactory("Item721Mock")).connect(deployer);
  const IMcontract = await Item721M.deploy(item721Name, item721Symbol, "1.0", item721URI, Wcontract.address);
  await IMcontract.deployed();

  saveToJSON(item721Name, {
    address: IMcontract.address,
    deployer: deployer.address
  })


  // world register asset
  const Item721E = (await ethers.getContractFactory("Item721Mock")).connect(deployer);
  const IEcontract = await Item721E.deploy(item721NameE, item721SymbolE, "1.0", item721URIE, Wcontract.address);
  await IEcontract.deployed();

  saveToJSON(item721NameE, {
    address: IEcontract.address,
    deployer: deployer.address
  })

  await (await Wcontract.registerAsset(IMcontract.address, "")).wait();
  await (await Wcontract.registerAsset(IEcontract.address, "")).wait();
  await (await Wcontract.registerAsset(Ccontract.address, "")).wait();


  console.log("Metaverse deployed to", Mcontract.address);
  console.log("World deployed to", Wcontract.address);
  console.log("Cash20 GGM deployed to", Ccontract.address);
  console.log("Item721 MOGA deployed to", IMcontract.address);
  console.log("Item721 MOGA Equipment deployed to", IEcontract.address);
  console.log("deployer address:", deployer.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });