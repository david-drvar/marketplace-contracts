const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const marketplaceModule = require("./MarketplaceProxyModule");
const escrowModule = require("./EscrowProxyModule");
const usersModule = require("./UsersProxyModule");

const setAddressesModule = buildModule("SetAddressesModule", (m) => {
  const { marketplace } = m.useModule(marketplaceModule);
  const { escrow } = m.useModule(escrowModule);
  const { users } = m.useModule(usersModule);

  // Marketplace calls
  m.call(marketplace, "addSupportedToken", ["USDC", "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238"], { id: "Unique1" });
  m.call(marketplace, "addSupportedToken", ["EURC", "0x08210F9170F89Ab7658F0B5E3fF39b0E03C594D4"], { id: "Unique2" });
  m.call(marketplace, "setEscrowContractAddress", [escrow.address], { id: "Unique3" });
  m.call(marketplace, "setUsersContractAddress", [users.address], { id: "Unique4" });

  // Escrow calls
  m.call(escrow, "addSupportedToken", ["USDC", "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238"], { id: "Unique5" });
  m.call(escrow, "addSupportedToken", ["EURC", "0x08210F9170F89Ab7658F0B5E3fF39b0E03C594D4"], { id: "Unique6" });
  m.call(escrow, "setMarketplaceContractAddress", [marketplace.address], { id: "Unique7" });
  m.call(escrow, "setUsersContractAddress", [users.address], { id: "Unique8" });

  // Users calls
  m.call(users, "setEscrowContractAddress", [escrow.address], { id: "Unique9" });

  return {};
});

module.exports = setAddressesModule;
