const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
// const escrowModule = require("./EscrowProxyModule");

const usersProxyModule = buildModule("UsersProxyModule", (m) => {
  const proxyAdminOwner = m.getAccount(0);
  const users = m.contract("Users");
  const initializeData = m.encodeFunctionCall(users, "initialize", [proxyAdminOwner]);
  const proxy = m.contract("TransparentUpgradeableProxy", [users, proxyAdminOwner, initializeData]);
  const proxyAdminAddress = m.readEventArgument(proxy, "AdminChanged", "newAdmin");
  const proxyAdmin = m.contractAt("ProxyAdmin", proxyAdminAddress);

  return { proxyAdmin, proxy };
});

const usersModule = buildModule("UsersModule", (m) => {
  // const { proxy: escrowProxy } = m.useModule(escrowModule);

  const { proxy, proxyAdmin } = m.useModule(usersProxyModule);
  const users = m.contractAt("Users", proxy);

  // m.call(users, "setEscrowContractAddress", [escrowProxy]);

  return { users, proxy, proxyAdmin };
});

module.exports = usersModule;
