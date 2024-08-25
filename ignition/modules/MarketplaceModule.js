const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const UsersModule = require("./UsersModule");
const EscrowModule = require("./EscrowModule");

const MarketplaceModule = buildModule("MarketplaceModule", (m) => {
  const deployer = m.getAccount(0);

  const { users } = m.useModule(UsersModule);
  const { escrow } = m.useModule(EscrowModule);
  // const users = m.contract("Users", [deployer]);
  // const escrow = m.contract("Escrow", [deployer]);

  const marketplace = m.contract("Marketplace", [deployer, escrow, users]);

  m.call(escrow, "setMarketplaceContractAddress", [marketplace]);

  return { marketplace };
});

module.exports = MarketplaceModule;
