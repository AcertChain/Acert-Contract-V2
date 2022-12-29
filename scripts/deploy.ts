import { ethers } from "hardhat";
import { saveToJSON, getDeployment } from "./utils";
import { deployAcert, deployMetaverse, deployWorld, deployAsset20, deployAsset721 } from "./contract"
import { isTokenKind } from "typescript";

async function main() {

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // deploy acert
  const acertInfo = await deployAcert(deployer);

  // deploy metaverse
  let name = "Moga Metaverse";
  let version = "v4.0.0";
  const startId = 0n;
  const metaverseInfo = await deployMetaverse(name, version, startId, deployer);

  // todo acert remark

  // deploy world
  name = "MonsterGalaxy";
  version = "v4.0.0";
  const worldInfo = await deployWorld(name, version, metaverseInfo.metaverseCoreContract, deployer);

  // todo acert remark

  // deploy asset20
  const Asset20Name = "Galaxy Gem";
  const Asset20Symbol = "GGM";
  const Asset20Version = "1.0";

  const asset20Info = await deployAsset20(Asset20Name, Asset20Symbol, Asset20Version, worldInfo.worldCoreContract, deployer);

  // todo acert remark

  const Asset721Name = "MOGA";
  const Asset721Symbol = "MOGA";
  const Asset721URI = "https://mintinfo.playmonstergalaxy.com/json/moga/";
  const Asset721Version = "1.0";

  const asset721Info = await deployAsset721(Asset721Name, Asset721Symbol, Asset721URI, Asset721Version, worldInfo.worldCoreContract, deployer);

  // todo acert remark

  const Asset721NameE = "MOGA Equipment";
  const Asset721SymbolE = "EQPT";
  const Asset721URIE = "https://mintinfo.playmonstergalaxy.com/json/equipment/";
  const Asset721VersionE = "1.0";

  const asset721InfoE = await deployAsset721(Asset721NameE, Asset721SymbolE, Asset721URIE, Asset721VersionE, worldInfo.worldCoreContract, deployer);

  // todo acert remark
  
  console.log("Done deploying contracts");
}



// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
