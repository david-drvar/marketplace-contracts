const { ethers } = require("hardhat");
const { frontEndAbiLocation, frontEndContractsFile } = require("../helper-hardhat-config");
require("dotenv").config();
const fs = require("fs");
const marketplaceAbiSource = require("../artifacts/contracts/Marketplace.sol/Marketplace.json");
const usersAbiSource = require("../artifacts/contracts/Users.sol/Users.json");
const deployedAddresses = require("../ignition/deployments/chain-11155111/deployed_addresses.json");

const contractAddress = "0xB4b7589073025f14057fe0d07616eC0e9ca99B50"; // sepolia contract address

async function main() {
  if (process.env.UPDATE_FRONT_END) {
    console.log("updating frontend...");
    await updateAbi();
    await updateContractAddresses();
    console.log("done");
  }
}

async function updateAbi() {
  fs.writeFileSync(`${frontEndAbiLocation}Marketplace.json`, JSON.stringify(marketplaceAbiSource["abi"]));
  fs.writeFileSync(`${frontEndAbiLocation}Users.json`, JSON.stringify(usersAbiSource["abi"]));
}

async function updateContractAddresses() {
  const sepolia_chainId = 11155111;
  const marketplaceContractAddress = deployedAddresses["MarketplaceModule#Marketplace"];
  const usersContractAddress = deployedAddresses["UsersModule#Users"];
  const contractAddresses = JSON.parse(fs.readFileSync(frontEndContractsFile, "utf8"));

  contractAddresses[sepolia_chainId] = { Marketplace: [marketplaceContractAddress], Users: [usersContractAddress] };

  fs.writeFileSync(frontEndContractsFile, JSON.stringify(contractAddresses));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
