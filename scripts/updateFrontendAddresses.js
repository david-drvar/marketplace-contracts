const { ethers } = require("hardhat");
const { frontEndAbiLocation, frontEndContractsFile } = require("../helper-hardhat-config");
require("dotenv").config();
const fs = require("fs");
const marketplaceAbiSource = require("../artifacts/contracts/Marketplace.sol/Marketplace.json");

const contractAddress = "0xB4b7589073025f14057fe0d07616eC0e9ca99B50"; // sepolia contract address

async function main() {
  if (process.env.UPDATE_FRONT_END) {
    console.log("updating frontend...");
    await updateAbi();
    // await updateContractAddresses();
    console.log("done");
  }
}

async function updateAbi() {
  fs.writeFileSync(`${frontEndAbiLocation}Marketplace.json`, JSON.stringify(marketplaceAbiSource["abi"]));
}

// async function updateContractAddresses() {
//   const chainId = network.config.chainId.toString();
//   const marketplace = await ethers.getContractFactory("Marketplace");
//   const marketplace2 = marketplace.attach(contractAddress);

//   const contractAddresses = JSON.parse(fs.readFileSync(frontEndContractsFile, "utf8"));
//   if (chainId in contractAddresses) {
//     if (!contractAddresses[chainId]["Marketplace"].includes(marketplace.target)) {
//       contractAddresses[chainId]["Marketplace"].push(marketplace.target);
//     }
//   } else {
//     contractAddresses[chainId] = { Marketplace: [marketplace.target] };
//   }
//   fs.writeFileSync(frontEndContractsFile, JSON.stringify(contractAddresses));
// }

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
