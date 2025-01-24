const { ethers } = require("hardhat");

async function main() {
  const contractAddress = "0xB4b7589073025f14057fe0d07616eC0e9ca99B50"; // sepolia contract address

  // Marketplace contract instance
  const MarketplaceContract = await ethers.getContractFactory("Marketplace");
  const marketplace = MarketplaceContract.attach(contractAddress);

  //   const marketplace = await ethers.getContractAt(contractAddress, Marketplace.abi, signer);

  // Item details
  const title = "My Awesome Item";
  const description = "This is a very cool and unique item";
  const price = 30; // 1 ETH in Wei
  const date = Math.floor(Date.now() / 1000); // Current timestamp in seconds

  // Function call to list the new item
  const tx = await marketplace.listNewItem(title, description, price, date);
  await tx.wait();

  console.log("Item listed successfully!");
  console.log("Transaction hash:", tx.hash);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
