require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@nomicfoundation/hardhat-verify");
require("hardhat-interface-generator");
require("hardhat-gas-reporter");

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "https://eth-sepolia.g.alchemy.com/v2/YOUR-API-KEY";
const POLYGON_RPC_URL = process.env.POLYGON_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "Your etherscan API key";
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY || "Your etherscan API key";
const COIN_MARKET_CAP_API_KEY = process.env.COIN_MARKET_CAP_API_KEY || "Your coin market cap API key";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 500,
      },
    },
  },
  gasReporter: {
    enabled: true,
    currency: "EUR",
    coinmarketcap: COIN_MARKET_CAP_API_KEY,
    gasPriceApi: ETHERSCAN_API_KEY,
    currencyDisplayPrecision: 3,
    outputFile: "gas-report.txt",
    token: "MATIC",
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337,
    },
    localhost: {
      chainId: 31337,
    },
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
      saveDeployments: true,
      chainId: 11155111,
    },
    polygonAmoy: {
      url: POLYGON_RPC_URL,
      accounts: [PRIVATE_KEY],
      saveDeployments: true,
      chainId: 80002,
    },
  },
  etherscan: {
    apiKey: {
      sepolia: ETHERSCAN_API_KEY,
      polygonAmoy: POLYGONSCAN_API_KEY,
    },
    customChains: [
      // {
      //   network: "sepolia",
      //   chainId: 11155111,
      //   urls: {
      //     apiURL: "https://eth-sepolia.blockscout.com/api",
      //     browserURL: "https://eth-sepolia.blockscout.com",
      //   },
      // },
      {
        network: "polygonAmoy",
        chainId: 80002,
        urls: {
          apiURL: "https://api-amoy.polygonscan.com/api",
          browserURL: "https://amoy.polygonscan.com",
        },
      },
    ],
  },
  sourcify: {
    enabled: true,
  },
};
