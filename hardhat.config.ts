/* eslint-disable no-unused-vars */
/* eslint-disable node/no-missing-import */
/* eslint-disable prettier/prettier */

import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();
// runTasks();

declare global {
  namespace NodeJS {
    interface ProcessEnv {
      ETHERSCAN_API_KEY: string;
      ALCHEMY_KEY: string;
      METAMASK_PRIVATE_KEY: string;
      METAMASK_PUBLIC_KEY: string;
      COINMARKETCAP_API_KEY: string;
      RINKEBY_URL: string;
    }
  }
}

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const config: HardhatUserConfig = {
  solidity: "0.8.11",
  networks: {
    rinkeby: {
      url: process.env.RINKEBY_URL,
      accounts: [],
      gas: 2100000,
      gasPrice: 8000000000
    },
    // hardhat: {
    //   forking: {
    //     url: process.env.RINKEBY_URL,
    //     blockNumber: 10293822,
    //   }
    // }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
