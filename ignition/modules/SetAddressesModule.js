const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const marketplaceModule = require("./MarketplaceProxyModule");
const escrowModule = require("./EscrowProxyModule");
const usersModule = require("./UsersProxyModule");

const setAddressesModule = buildModule("SetAddressesModule", (m) => {
  const { marketplace } = m.useModule(marketplaceModule);
  const { escrow } = m.useModule(escrowModule);
  const { users } = m.useModule(usersModule);

  // Marketplace calls
  m.call(marketplace, "addSupportedToken", ["USDC", "0x41e94eb019c0762f9bfcf9fb1e58725bfb0e7582"], { id: "Unique1" });
  // m.call(marketplace, "addSupportedToken", ["EURC", "0x08210F9170F89Ab7658F0B5E3fF39b0E03C594D4"], { id: "Unique3" });
  m.call(marketplace, "setEscrowContractAddress", [escrow.address], { id: "Unique4" });
  m.call(marketplace, "setUsersContractAddress", [users.address], { id: "Unique5" });

  // Escrow calls
  m.call(escrow, "addSupportedToken", ["USDC", "0x41e94eb019c0762f9bfcf9fb1e58725bfb0e7582"], { id: "Unique6" });
  // m.call(escrow, "addSupportedToken", ["EURC", "0x08210F9170F89Ab7658F0B5E3fF39b0E03C594D4"], { id: "Unique8" });
  m.call(escrow, "setMarketplaceContractAddress", [marketplace.address], { id: "Unique9" });
  m.call(escrow, "setUsersContractAddress", [users.address], { id: "Unique10" });

  // Users calls
  m.call(users, "setEscrowContractAddress", [escrow.address], { id: "Unique11" });
  m.call(users, "setMaxModeratorFee", [10], { id: "Unique12" });

  return {};
});

module.exports = setAddressesModule;
