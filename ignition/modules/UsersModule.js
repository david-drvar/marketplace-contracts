const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const UsersModule = buildModule("UsersModule", (m) => {
  const deployer = m.getAccount(0);

  const users = m.contract("Users", [deployer]);

  return { users };
});

module.exports = UsersModule;
