const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("MarketplaceModule", (m) => {
  const marketplace = m.contract("Marketplace");
  return { marketplace };
});
