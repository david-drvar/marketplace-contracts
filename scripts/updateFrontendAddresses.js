const { ethers } = require("hardhat");
const { frontEndAbiLocation, frontEndContractsFile } = require("../helper-hardhat-config");
require("dotenv").config();
const fs = require("fs");
const marketplaceAbiSource = require("../artifacts/contracts/Marketplace.sol/Marketplace.json");
const usersAbiSource = require("../artifacts/contracts/Users.sol/Users.json");
const escrowAbiSource = require("../artifacts/contracts/Escrow.sol/Escrow.json");
const deployedAddresses = require("../ignition/deployments/chain-80002/deployed_addresses.json");

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
  fs.writeFileSync(`${frontEndAbiLocation}Escrow.json`, JSON.stringify(escrowAbiSource["abi"]));
}

async function updateContractAddresses() {
  const sepolia_chainId = 11155111;
  const marketplaceContractAddress = deployedAddresses["MarketplaceModule#Marketplace"];
  const usersContractAddress = deployedAddresses["UsersModule#Users"];
  const escrowContractAddress = deployedAddresses["EscrowModule#Escrow"];
  const contractAddresses = JSON.parse(fs.readFileSync(frontEndContractsFile, "utf8"));

  contractAddresses[sepolia_chainId] = { Marketplace: [marketplaceContractAddress], Users: [usersContractAddress], Escrow: [escrowContractAddress] };

  fs.writeFileSync(frontEndContractsFile, JSON.stringify(contractAddresses));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
