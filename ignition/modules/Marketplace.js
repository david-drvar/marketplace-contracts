const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("MarketplaceModule", (m) => {
  const marketplace = m.contract("Marketplace");

  // const marketplaceV2 = m.contract("Marketplace", require("../../artifacts/contracts/Marketplace.sol/Marketplace.json"), [], { id: "v2" });
  return { marketplace };
});
