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

task("mint", "Mints an NFT for sale and auction")
.addParam("tokenuri", "Token URI")
.addParam("owner", "The NFT will belong to this address")
.setAction(async (taskArguments, hre) => {
    const contractSchema = require("./artifacts/contracts/Marketplace.sol/Marketplace.json");

    const alchemyProvider = new hre.ethers.providers.AlchemyProvider("rinkeby", process.env.ALCHEMY_KEY);
    const walletOwner = new hre.ethers.Wallet(process.env.METAMASK_PRIVATE_KEY, alchemyProvider);
    const marketplaceContractInstance = new hre.ethers.Contract(taskArguments.staker, contractSchema.abi, walletOwner);

    const mintTx = await marketplaceContractInstance.createItem(taskArguments.tokenuri, taskArguments.owner);

    console.log("Receipt: ", mintTx);
})
;

const config: HardhatUserConfig = {
  solidity: "0.8.11",
  networks: {
    rinkeby: {
      url: process.env.RINKEBY_URL,
      accounts: [process.env.METAMASK_PRIVATE_KEY],
      gas: 2100000,
      gasPrice: 8000000000
    },
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
