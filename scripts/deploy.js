const hre = require("hardhat");

async function main() {
  // We get the contract to deploy
  const [deployer] = await ethers.getSigners();
  //deploy Metaverse 
  const Metaverse = (await ethers.getContractFactory("Metaverse")).connect(deployer);
  const Mcontract = await Metaverse.deploy("M", "1.0");
  await Mcontract.deployed();

  //deploy world
  const World = (await ethers.getContractFactory("World")).connect(deployer);
  const Wcontract = await World.deploy(Mcontract.address, "W", "1.0");
  await Wcontract.deployed();

  //deploy cash20
  const Cash20 = (await ethers.getContractFactory("Cash20Mock")).connect(deployer);
  const Ccontract = await Cash20.deploy("C", "C", "1.0", Ccontract.address);
  await Ccontract.deployed();

  //deploy Item721
  const Item721 = (await ethers.getContractFactory("Item721Mock")).connect(deployer);
  const Icontract = await Item721.deploy("I", "I", "1.0", "testURI", Ccontract.address);
  await Icontract.deployed();


  console.log("Metaverse deployed to", Mcontract.address);
  console.log("World deployed to", Wcontract.address);
  console.log("Cash20 deployed to", Ccontract.address);
  console.log("Item721 deployed to", Icontract.address);
  console.log(" deployer address:", deployer.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });