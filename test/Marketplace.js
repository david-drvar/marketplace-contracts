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

    const Users = await ethers.getContractFactory("Users");
    const users = await Users.deploy();

    const ownerAddress = await owner.getAddress();
    await marketplace.initialize(ownerAddress);
    await users.initialize(ownerAddress);

    const usersAddress = await users.getAddress();
    await marketplace.setUsersContractAddress(usersAddress);

    // setup user
    const mockProfileData = {
      username: "johndoe123",
      firstName: "John",
      lastName: "Doe",
      country: "USA",
      description: "A passionate blockchain developer.",
      email: "johndoe@example.com",
      avatarHash: "QmTzQ1NcReB9kJc7FxjZyLg9mEsK9RJ7HnH7ZC8mG9R6xP",
      isModerator: true,
      moderatorFee: 5,
    };
    await users.createProfile(
      mockProfileData.username,
      mockProfileData.firstName,
      mockProfileData.lastName,
      mockProfileData.country,
      mockProfileData.description,
      mockProfileData.email,
      mockProfileData.avatarHash,
      mockProfileData.isModerator,
      mockProfileData.moderatorFee
    );

    return { marketplace, users, owner, otherAccount };
  }

  describe("ListingNewItem", function () {
    describe("Validations", function () {
      it("check deployment valid", async function () {
        const { marketplace } = await loadFixture(deployMarketplaceFixture);
        console.log("users contract", await marketplace.usersContract());
        expect(await marketplace.getItemCount()).to.be.equal(0);
      });

      it("Should revert with if photo hash not valid", async function () {
        const { marketplace, users, owner, otherAccount } = await loadFixture(deployMarketplaceFixture);

        const id = 0;
        const seller = "0xD5AeB51354c404861B6F1D07FDAC0482EaF1Bc46";
        const title = "Item title";
        const description = "item description";
        const price = 1000000; //0.5e18;
        const currency = "ETH";
        const condition = 0;
        const category = "Electronics";
        const itemStatus = 0;
        const subcategory = "Laptops";
        const country = "Italy";
        const isGift = false;
        const photosIPFSHashes = ["photo"]; // valid hash QmaHj5MvsAD1ytkuQKVvS5jHPBzREojpFCHwzSevdCapCn

        const item = { id, seller, price, currency, description, title, photosIPFSHashes, itemStatus, condition, category, subcategory, country, isGift };
        expect(await users.isRegisteredUser(owner)).to.equal(true);
        await expect(marketplace.listNewItem(item)).to.be.revertedWithCustomError(marketplace, "NotIPFSHash").withArgs(photosIPFSHashes[0]);
      });

      it("Should not revert with if photo hash is valid", async function () {
        const { marketplace, users, owner, otherAccount } = await loadFixture(deployMarketplaceFixture);

        const id = 0;
        const seller = "0x8D512c7D634F140FdfE1995790998066f5a795c2";
        const title = "Item title";
        const description = "item description";
        const price = 1000000; //0.5e18;
        const currency = "ETH";
        const condition = 0;
        const category = "Electronics";
        const itemStatus = 0;
        const subcategory = "Laptops";
        const country = "Italy";
        const isGift = false;
        const photosIPFSHashes = ["QmaHj5MvsAD1ytkuQKVvS5jHPBzREojpFCHwzSevdCapCn"];

        const item = { id, seller, price, currency, description, title, photosIPFSHashes, itemStatus, condition, category, subcategory, country, isGift };
        expect(await users.isRegisteredUser(owner)).to.equal(true);
        await expect(marketplace.listNewItem(item)).to.not.be.reverted;
      });

      it("Should be reverted when photo limit exceeded", async function () {
        const { marketplace } = await loadFixture(deployMarketplaceFixture);

        const id = 0;
        const seller = "0x8D512c7D634F140FdfE1995790998066f5a795c2";
        const title = "Item title";
        const description = "item description";
        const price = 1000000; //0.5e18;
        const currency = "ETH";
        const condition = 0;
        const category = "Electronics";
        const itemStatus = 0;
        const subcategory = "Laptops";
        const country = "Italy";
        const isGift = false;

        maxLimit = await marketplace.MAX_PHOTO_LIMIT();
        const photoHash = "QmPxKrJJ6DkoyiSZxcezwkjK4ygAnMWGyVVZiVUPMGnVD8";
        var photosIPFSHashes = [];
        for (i = 0; i <= maxLimit; i++) {
          photosIPFSHashes.push(photoHash);
        }

        const item = { id, seller, price, currency, description, title, photosIPFSHashes, itemStatus, condition, category, subcategory, country, isGift };

        await expect(marketplace.listNewItem(item)).to.be.revertedWithCustomError(marketplace, "PhotoLimitExceeded");
      });
    });
  });
});
