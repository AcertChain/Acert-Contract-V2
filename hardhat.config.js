require("@nomiclabs/hardhat-waffle");
require("solidity-docgen")
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

dotenv.config();
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

require('@nomiclabs/hardhat-truffle5');
require('hardhat-gas-reporter');

for (const f of fs.readdirSync(path.join(__dirname, 'hardhat'))) {
  require(path.join(__dirname, 'hardhat', f));
}

require('hardhat-contract-sizer');

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  docgen: {
    output: 'docs',
    pages: 'files',
  },
  solidity: {
    compilers: [{
      version: "0.8.4",
      // settings: {
      //   optimizer: {
      //     enabled: true,
      //     runs: 20000
      //   }
      // },
    }]
  },
  networks: {
    test: {
      url: process.env.URL,
      accounts: process.env.PRIVATE_KEY !== undefined ? process.env.PRIVATE_KEY.split(",") : [],
    },
  },
};