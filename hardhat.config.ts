import "@nomiclabs/hardhat-waffle";
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-truffle5';
import "solidity-docgen";
import 'hardhat-abi-exporter';
import 'hardhat-gas-reporter';
import 'hardhat-contract-sizer';
import "@typechain/hardhat";
import * as dotenv from "dotenv";
import { HardhatUserConfig, task } from "hardhat/config";

dotenv.config();
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(account.address);
  }
});


/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 const config: HardhatUserConfig =  {
  abiExporter: {
    path: './data/abi',
    runOnCompile: true,
    clear: true,
    spacing: 2,
    format: "json",
  },
  solidity: {
    compilers: [{
      version: "0.8.4",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      },
    }]
  },
  networks: {
    test: {
      url: process.env.URL,
      accounts: process.env.PRIVATE_KEY !== undefined ? process.env.PRIVATE_KEY.split(",") : [],
    },
  },
};

export default config;
