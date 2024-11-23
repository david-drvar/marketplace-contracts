const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
// const marketplaceModule = require("./MarketplaceProxyModule");
// const usersModule = require("./UsersProxyModule");

const escrowProxyModule = buildModule("EscrowProxyModule", (m) => {
  const proxyAdminOwner = m.getAccount(0);
  const escrow = m.contract("Escrow");
  const initializeData = m.encodeFunctionCall(escrow, "initialize", [proxyAdminOwner]);
  const proxy = m.contract("TransparentUpgradeableProxy", [escrow, proxyAdminOwner, initializeData]);
  const proxyAdminAddress = m.readEventArgument(proxy, "AdminChanged", "newAdmin");
  const proxyAdmin = m.contractAt("ProxyAdmin", proxyAdminAddress);

  return { proxyAdmin, proxy };
});

const escrowModule = buildModule("EscrowModule", (m) => {
  // const { proxy: marketplaceProxy } = m.useModule(marketplaceModule);
  // const { proxy: usersProxy } = m.useModule(usersModule);

  const { proxy, proxyAdmin } = m.useModule(escrowProxyModule);
  const escrow = m.contractAt("Escrow", proxy);

  // m.call(escrow, "setMarketplaceContractAddress", [marketplaceProxy]);
  // m.call(escrow, "setUsersContractAddress", [usersProxy]);
  // m.call(escrow, "addSupportedToken", ["USDC", "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238"]);
  // m.call(escrow, "addSupportedToken", ["EURC", "0x08210F9170F89Ab7658F0B5E3fF39b0E03C594D4"]);

  return { escrow, proxy, proxyAdmin };
});

module.exports = escrowModule;
