import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.35",
    settings: {
      evmVersion: "osaka",
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  gasReporter: {
    enabled: true,
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    outputFile: "gas-report.txt",
    noColors: true,
    token: "ETH",
    gasPriceApi: `https://api.etherscan.io/v2/api?chainid=1&module=proxy&action=eth_gasPrice&apikey=${process.env.ETHERSCAN_API_KEY!}`
  },

  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY!
  },

  networks: {
    localhost: {
      url: 'http://127.0.0.1:8545',
      chainId: 31337
    },

    hardhat: {
      forking: {
        url: "https://ethereum-rpc.publicnode.com",
      }
    },

    sepolia: {
      url: "https://ethereum-sepolia-rpc.publicnode.com",
      accounts: [process.env.PRIVATE_KEY!]
    }
  },
};

export default config;