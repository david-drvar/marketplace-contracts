const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("UsersModule", (m) => {
  const users = m.contract("Users");

  return { users };
});
