const { network } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const waitBlockConfirmations = 1;

  log("----------------------------------------------------");
  const arguments = [];
  const nftMarketplace = await deploy("Marketplace", {
    from: deployer,
    args: arguments,
    log: true,
    waitConfirmations: waitBlockConfirmations,
  });
};

module.exports.tags = ["all", "marketplace"];
