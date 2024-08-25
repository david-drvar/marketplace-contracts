const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const EscrowModule = buildModule("EscrowModule", (m) => {
  const deployer = m.getAccount(0);

  const escrow = m.contract("Escrow", [deployer]);

  return { escrow };
});

module.exports = EscrowModule;
