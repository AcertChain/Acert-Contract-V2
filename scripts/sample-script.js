
const hre = require("hardhat");

async function main() {
  // We get the contract to deploy
  const World = await hre.ethers.getContractFactory("World");
  const world = await World.deploy();

  await world.deployed();

  console.log("World deployed to:", world.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
