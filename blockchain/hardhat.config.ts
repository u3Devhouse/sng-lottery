import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter"
import "solidity-coverage"
import "dotenv/config"

const pkey = process.env.DEPLOYER_TEST
const sepolia_key = process.env.SEPOLIA_KEY

if (!pkey || !sepolia_key) {
  throw new Error("Please set your keys in a .env file");
}

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings:{
      optimizer:{
        enabled: true,
        runs: 200
      }
    }
  },
  networks:{
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/"+sepolia_key,
      accounts: [pkey]
    }
  },
  gasReporter:{
    currency: "USD",
    token: "ETH",
    excludeContracts: ["mock/", "VRFCoordinatorV2Mock", "ERC20"],
  }
};

export default config;
