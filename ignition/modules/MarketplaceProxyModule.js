const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
// const escrowModule = require("./EscrowProxyModule");
// const usersModule = require("./UsersProxyModule");

const marketplaceProxyModule = buildModule("MarketplaceProxyModule", (m) => {
  const proxyAdminOwner = m.getAccount(0);
  const marketplace = m.contract("Marketplace");
  const initializeData = m.encodeFunctionCall(marketplace, "initialize", [proxyAdminOwner]);
  const proxy = m.contract("TransparentUpgradeableProxy", [marketplace, proxyAdminOwner, initializeData]);
  const proxyAdminAddress = m.readEventArgument(proxy, "AdminChanged", "newAdmin");

  const proxyAdmin = m.contractAt("ProxyAdmin", proxyAdminAddress);

  return { proxyAdmin, proxy };
});

const marketplaceModule = buildModule("MarketplaceModule", (m) => {
  // const { proxy: escrowProxy } = m.useModule(escrowModule);
  // const { proxy: usersProxy } = m.useModule(usersModule);

  const { proxy, proxyAdmin } = m.useModule(marketplaceProxyModule);
  const marketplace = m.contractAt("Marketplace", proxy);

  // m.call(marketplace, "setEscrowContractAddress", [escrowProxy]);
  // m.call(marketplace, "setUsersContractAddress", [usersProxy]);
  // m.call(marketplace, "addSupportedToken", ["USDC", "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238"]);
  // m.call(marketplace, "addSupportedToken", ["EURC", "0x08210F9170F89Ab7658F0B5E3fF39b0E03C594D4"]);

  return { marketplace, proxy, proxyAdmin };
});

module.exports = marketplaceModule;
