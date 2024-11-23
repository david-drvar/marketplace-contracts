const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

// const MarketplaceModule = buildModule("MarketplaceModule", (m) => {
//   // const deployer = m.getAccount(0);

//   // const marketplace = m.contract("Marketplace", [deployer]);

//   // return { marketplace };

//   const { proxy, proxyAdmin } = m.useModule(proxyModule);

//   const marketplace = m.contractAt("Marketplace", proxy);

//   return { marketplace, proxy, proxyAdmin };
// });

// module.exports = MarketplaceModule;
