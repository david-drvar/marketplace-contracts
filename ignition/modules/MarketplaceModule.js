const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const MarketplaceModule = buildModule("MarketplaceModule", (m) => {
  const deployer = m.getAccount(0);

  const marketplace = m.contract("Marketplace", [deployer]);

  return { marketplace };
});

module.exports = MarketplaceModule;
