const hre = require("hardhat");

async function main() {
  // We get the contract to deploy
  const [deployer] = await ethers.getSigners();
  //deploy Metaverse 
  const Metaverse = (await ethers.getContractFactory("Metaverse")).connect(deployer);
  const Mcontract = await Metaverse.deploy("Metaverse", "1.0", 0);
  await Mcontract.deployed();

  //deploy world
  const World = (await ethers.getContractFactory("World")).connect(deployer);
  const Wcontract = await World.deploy(Mcontract.address, "World", "1.0");
  await Wcontract.deployed();

  // register world
  await Mcontract.addWorld(Wcontract.address, "", "", "", "");

  //deploy cash20
  //GGM(name : Galaxy Gem ; symbol GGM ; 精度：18位)
  const Cash20 = (await ethers.getContractFactory("Cash20Mock")).connect(deployer);
  const Ccontract = await Cash20.deploy("Galaxy Gem", "GGM", "1.0", Wcontract.address);
  await Ccontract.deployed();

  //deploy Item721
  //moga, equipment(name: MOGA ; symbol : MOGA ; tokenURI: https://moga.taobaozx.net/moga/，id起始号: 没有ID起始号根据moga信息组合成）
  const Item721M = (await ethers.getContractFactory("Item721Mock")).connect(deployer);
  const IMcontract = await Item721M.deploy("MOGA", "MOGA", "1.0", "https://moga.taobaozx.net/moga/", Wcontract.address);
  await IMcontract.deployed();


  // world register asset
  // moga, equipment(name: MOGA Equipment; symbol : eqpt ; tokenURI: https://moga.taobaozx.net/equipment/，id起始号: 没有ID起始号根据装备信息组合成）
  const Item721E = (await ethers.getContractFactory("Item721Mock")).connect(deployer);
  const IEcontract = await Item721E.deploy("MOGA Equipment", "eqpt", "1.0", "https://moga.taobaozx.net/equipment/", Wcontract.address);
  await IEcontract.deployed();


  await Wcontract.registerAsset(IMcontract.address, "");
  await Wcontract.registerAsset(IEcontract.address, "");
  await Wcontract.registerAsset(Ccontract.address, "");


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