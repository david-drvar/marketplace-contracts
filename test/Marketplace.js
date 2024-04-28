const { time, loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Marketplace", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployMarketplaceFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Marketplace = await ethers.getContractFactory("Marketplace");
    const marketplace = await Marketplace.deploy();

    return { marketplace, owner, otherAccount };
  }

  describe("ListingNewItem", function () {
    describe("Validations", function () {
      it("check deployment valid", async function () {
        const { marketplace } = await loadFixture(deployMarketplaceFixture);
        expect(await marketplace.getItemCount()).to.be.equal(0);
      });

      it("Should revert with if photo hash not valid", async function () {
        const { marketplace } = await loadFixture(deployMarketplaceFixture);

        const title = "Item title";
        const description = "item description";
        const price = 1000000; //0.5e18;
        const photoHashes = ["photo hash wrong"];

        await expect(marketplace.listNewItem(title, description, price, photoHashes)).to.be.revertedWithCustomError(marketplace, "NotIPFSHash").withArgs(photoHashes[0]);
      });

      it("Should not revert with if photo hash is valid", async function () {
        const { marketplace } = await loadFixture(deployMarketplaceFixture);

        const title = "Item title";
        const description = "item description";
        const price = 1000000;
        const photoHashes = ["QmPxKrJJ6DkoyiSZxcezwkjK4ygAnMWGyVVZiVUPMGnVD8"];

        await expect(marketplace.listNewItem(title, description, price, photoHashes)).to.not.be.reverted;
      });

      it("Should be reverted when photo limit exceeded", async function () {
        const { marketplace } = await loadFixture(deployMarketplaceFixture);

        const title = "Item title";
        const description = "item description";
        const price = 1000000;

        maxLimit = await marketplace.MAX_PHOTO_LIMIT();
        const photoHash = "QmPxKrJJ6DkoyiSZxcezwkjK4ygAnMWGyVVZiVUPMGnVD8";
        var photoHashes = [];
        for (i = 0; i <= maxLimit; i++) {
          photoHashes.push(photoHash);
        }

        await expect(marketplace.listNewItem(title, description, price, photoHashes)).to.be.revertedWithCustomError(marketplace, "PhotoLimitExceeded");
      });
    });
  });
});
