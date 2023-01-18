import { ethers } from "hardhat";
import { saveToJSON, getDeployment } from "./utils";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
    Acert, MogaMetaverseV3, MetaverseCore, MetaverseStorage, MonsterGalaxyV3, WorldCore, WorldStorage,
    MogaTokenV3, Asset20Core,  MogaNFTV3, Asset721Core, 
} from "../typechain-types/";
import {Asset20Storage,Asset721Storage} from "../typechain-types/contracts/token/";

interface AcertDeploymentInfo {
    deployer: SignerWithAddress;
    acertContract: Acert;
}

// deploy acert 
export async function deployAcert(deployer: SignerWithAddress): Promise<AcertDeploymentInfo> {
    const acert = (await ethers.getContractFactory("Acert")).connect(deployer);
    const acertContract = await acert.deploy() as Acert;
    console.log("Acert address:", acertContract.address);

    saveToJSON("Acert", {
        address: acertContract.address,
        deployer: deployer.address,
    });

    return { deployer, acertContract };
}

interface MetaverseDeploymentInfo {
    name: string;
    version: string;
    startId: bigint;
    deployer: SignerWithAddress;
    metaverseContract: MogaMetaverseV3;
    metaverseStorageContract: MetaverseStorage;
    metaverseCoreContract: MetaverseCore;
}


// deploy metaverse
export async function deployMetaverse(name: string, version: string, startId: bigint, deployer: SignerWithAddress): Promise<MetaverseDeploymentInfo> {
    const metaverse = (await ethers.getContractFactory("MogaMetaverseV3")).connect(deployer);
    //const metaverse = (await ethers.getContractFactory("Metaverse")).connect(deployer);
    const metaverseContract = await metaverse.deploy() as MogaMetaverseV3;

    const metaverseStorage = (await ethers.getContractFactory("contracts/acertV3/metaverse/MetaverseStorage.sol:MetaverseStorage")).connect(deployer);
    const metaverseStorageContract = await metaverseStorage.deploy() as MetaverseStorage;

    const metaverseCore = (await ethers.getContractFactory("MetaverseCore")).connect(deployer);
    const metaverseCoreContract = await metaverseCore.deploy(name, version, startId, metaverseStorageContract.address) as MetaverseCore;


    await metaverseStorageContract.updateMetaverse(metaverseCoreContract.address);

    await metaverseCoreContract.updateShell(metaverseContract.address);

    await metaverseContract.updateCore(metaverseCoreContract.address);

    console.log("Metaverse address:", metaverseContract.address);
    console.log("MetaverseStorage address:", metaverseStorageContract.address);
    console.log("MetaverseCore address:", metaverseCoreContract.address);

    saveToJSON("Metaverse", {
        metaverseAddress: metaverseContract.address,
        metaverseStorageAddress: metaverseStorageContract.address,
        metaverseCoreAddress: metaverseCoreContract.address,
        deployer: deployer.address,
    });

    return { name, version, startId, deployer, metaverseContract, metaverseStorageContract, metaverseCoreContract };

}

// deploy world

interface WorldDeploymentInfo {
    name: string;
    version: string;
    metaverseCoreContract: MetaverseCore;
    worldContract: MonsterGalaxyV3;
    worldStorageContract: WorldStorage;
    worldCoreContract: WorldCore;
}

export async function deployWorld(name: string, version: string, metaverseCoreContract: MetaverseCore, deployer: SignerWithAddress): Promise<WorldDeploymentInfo> {
    //const world = (await ethers.getContractFactory("World")).connect(deployer);
    const world = (await ethers.getContractFactory("MonsterGalaxyV3")).connect(deployer);
    const worldContract = await world.deploy() as MonsterGalaxyV3;

    const worldStorage = (await ethers.getContractFactory("contracts/acertV3/world/WorldStorage.sol:WorldStorage")).connect(deployer);
    const worldStorageContract = await worldStorage.deploy() as WorldStorage;

    const worldCore = (await ethers.getContractFactory("WorldCore")).connect(deployer);
    const worldCoreContract = await worldCore.deploy(name, version, await metaverseCoreContract.shellContract(), worldStorageContract.address) as WorldCore;

    await worldStorageContract.updateWorld(worldCoreContract.address);

    await worldCoreContract.updateShell(worldContract.address);

    await worldContract.updateCore(worldCoreContract.address);

    await metaverseCoreContract.registerWorld(worldContract.address);

    console.log("World address:", worldContract.address);
    console.log("WorldStorage address:", worldStorageContract.address);
    console.log("WorldCore address:", worldCoreContract.address);

    saveToJSON("World", {
        worldAddress: worldContract.address,
        worldStorageAddress: worldStorageContract.address,
        worldCoreAddress: worldCoreContract.address,
        deployer: deployer.address,
    });

    return { name, version, metaverseCoreContract, worldContract, worldStorageContract, worldCoreContract };

}

// deploy asset20

interface Asset20DeploymentInfo {
    name: string;
    version: string;
    symbol: string;
    worldCoreContract: WorldCore;
    asset20Contract: MogaTokenV3;
    asset20StorageContract: Asset20Storage;
    asset20CoreContract: Asset20Core;
}

export async function deployAsset20(name: string, version: string, symbol: string, worldCoreContract: WorldCore, deployer: SignerWithAddress): Promise<Asset20DeploymentInfo> {
    const asset20 = (await ethers.getContractFactory("MogaTokenV3")).connect(deployer);
    const asset20Contract = await asset20.deploy() as MogaTokenV3;

    const asset20Storage = (await ethers.getContractFactory("contracts/acertV3/token/Asset20Storage.sol:Asset20Storage")).connect(deployer);
    const asset20StorageContract = await asset20Storage.deploy() as Asset20Storage;

    const asset20Core = (await ethers.getContractFactory("Asset20Core")).connect(deployer);
    const asset20CoreContract = await asset20Core.deploy(name, version, symbol, await worldCoreContract.shellContract(), asset20StorageContract.address) as Asset20Core;

    await asset20StorageContract.updateAsset(asset20CoreContract.address);

    await asset20CoreContract.updateShell(asset20Contract.address);

    await asset20Contract.updateCore(asset20CoreContract.address);

    await worldCoreContract.registerAsset(asset20Contract.address);

    console.log("Asset20 address:", asset20Contract.address);
    console.log("Asset20Storage address:", asset20StorageContract.address);
    console.log("Asset20Core address:", asset20CoreContract.address);

    saveToJSON("Asset20_" + name, {
        asset20Address: asset20Contract.address,
        asset20StorageAddress: asset20StorageContract.address,
        asset20CoreAddress: asset20CoreContract.address,
        deployer: deployer.address,
    });

    return { name, version, symbol, worldCoreContract, asset20Contract, asset20StorageContract, asset20CoreContract };

}

// deploy asset721
interface Asset721DeploymentInfo {
    name: string;
    version: string;
    symbol: string;
    uri: string;
    worldCoreContract: WorldCore;
    asset721Contract: MogaNFTV3;
    asset721StorageContract: Asset721Storage;
    asset721CoreContract: Asset721Core;
}

export async function deployAsset721(name: string, version: string, symbol: string, uri:string,worldCoreContract: WorldCore, deployer: SignerWithAddress): Promise<Asset721DeploymentInfo> {
    const asset721 = (await ethers.getContractFactory("MogaNFTV3")).connect(deployer);
    const asset721Contract = await asset721.deploy() as MogaNFTV3;
    
    const asset721Storage = (await ethers.getContractFactory("contracts/acertV3/token/Asset721Storage.sol:Asset721Storage")).connect(deployer);
    const asset721StorageContract = await asset721Storage.deploy() as Asset721Storage;


    const asset721Core = (await ethers.getContractFactory("Asset721Core")).connect(deployer);
    const asset721CoreContract = await asset721Core.deploy(name, version, symbol,uri, await worldCoreContract.shellContract(), asset721StorageContract.address) as Asset721Core;

    await asset721StorageContract.updateAsset(asset721CoreContract.address);

    await asset721CoreContract.updateShell(asset721Contract.address);

    await asset721Contract.updateCore(asset721CoreContract.address);

    const library =  (await ethers.getContractFactory("contracts/acertV3/token/NFTMetadata.sol:Utils")).attach(getDeployment("Utils").address);

    const NFTMetadata =  (await ethers.getContractFactory("contracts/acertV3/token/NFTMetadata.sol:NFTMetadata",{
        libraries: {
          Utils: library.address
        }
      })).connect(deployer);
    const nftMetadata = await NFTMetadata.deploy(asset721StorageContract.address,await asset721StorageContract.owner())
    await nftMetadata.deployed();
    

    await asset721StorageContract.updateNFTMetadataContract(nftMetadata.address);


    await worldCoreContract.registerAsset(asset721Contract.address);

    console.log("Asset721 address:", asset721Contract.address);
    console.log("Asset721Storage address:", asset721StorageContract.address);
    console.log("Asset721Core address:", asset721CoreContract.address);
    console.log("NFTMetadata address:", nftMetadata.address);

    saveToJSON("Asset721_" + name, {
        asset721Address: asset721Contract.address,
        asset721StorageAddress: asset721StorageContract.address,
        asset721CoreAddress: asset721CoreContract.address,
        nftMetadataAddress: nftMetadata.address,
        deployer: deployer.address,
    });

    return { name, version, symbol,uri, worldCoreContract, asset721Contract, asset721StorageContract, asset721CoreContract };

}
