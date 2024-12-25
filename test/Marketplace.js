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
    const [owner, otherAccount, moderatorAcc] = await ethers.getSigners();

    const Marketplace = await ethers.getContractFactory("Marketplace");
    const marketplace = await Marketplace.deploy();

    const Users = await ethers.getContractFactory("Users");
    const users = await Users.deploy();

    const Escrow = await ethers.getContractFactory("Escrow");
    const escrow = await Escrow.deploy();

    const ownerAddress = await owner.getAddress();
    await marketplace.initialize(ownerAddress);
    await users.initialize(ownerAddress);
    await escrow.initialize(ownerAddress);

    const usersAddress = await users.getAddress();
    const escrowAddress = await escrow.getAddress();
    const marketplaceAddress = await marketplace.getAddress();
    await marketplace.setUsersContractAddress(usersAddress);
    await marketplace.setEscrowContractAddress(escrowAddress);

    await escrow.setMarketplaceContractAddress(marketplaceAddress);

    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const mockERC20 = await MockERC20.deploy("Mock Token", "MOCK", 1000000000000000);
    const mockERC20Address = await mockERC20.getAddress();

    await marketplace.addSupportedToken("MOCK", mockERC20Address);
    await escrow.addSupportedToken("MOCK", mockERC20Address);

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

    // setup user
    const mockModeratorProfileData = {
      username: "johnmoderator123",
      firstName: "John",
      lastName: "Doe",
      country: "USA",
      description: "A passionate blockchain developer.",
      email: "johndoe@example.com",
      avatarHash: "QmTzQ1NcReB9kJc7FxjZyLg9mEsK9RJ7HnH7ZC8mG9R6xP",
      isModerator: true,
      moderatorFee: 10,
    };
    await users
      .connect(moderatorAcc)
      .createProfile(
        mockModeratorProfileData.username,
        mockModeratorProfileData.firstName,
        mockModeratorProfileData.lastName,
        mockModeratorProfileData.country,
        mockModeratorProfileData.description,
        mockModeratorProfileData.email,
        mockModeratorProfileData.avatarHash,
        mockModeratorProfileData.isModerator,
        mockModeratorProfileData.moderatorFee
      );

    return { marketplace, users, owner, otherAccount, escrow, mockERC20, moderatorAcc };
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

      it("Should allow the owner to set the users contract address", async function () {
        const { marketplace, owner } = await loadFixture(deployMarketplaceFixture);
        const newUsersAddress = "0x8D512c7D634F140FdfE1995790998066f5a795c2";

        await expect(marketplace.connect(owner).setUsersContractAddress(newUsersAddress)).to.not.be.reverted;

        expect(await marketplace.usersContract()).to.equal(newUsersAddress);
      });

      it("Should not allow non-owner to set the users contract address", async function () {
        const { marketplace, otherAccount } = await loadFixture(deployMarketplaceFixture);
        const newUsersAddress = "0x000000000000000000000000000000000000dead";

        await expect(marketplace.connect(otherAccount).setUsersContractAddress(newUsersAddress)).to.be.reverted;
      });

      it("Should allow the owner to add a supported token", async function () {
        const { marketplace, owner } = await loadFixture(deployMarketplaceFixture);
        const tokenName = "USDT";
        const tokenAddress = "0x8D512c7D634F140FdfE1995790998066f5a795c2";

        await expect(marketplace.connect(owner).addSupportedToken(tokenName, tokenAddress)).to.not.be.reverted;

        expect(await marketplace.supportedTokens(tokenName)).to.equal(tokenAddress);
      });

      it("Should not allow non-owner to add a supported token", async function () {
        const { marketplace, otherAccount } = await loadFixture(deployMarketplaceFixture);
        const tokenName = "USDT";
        const tokenAddress = "0x000000000000000000000000000000000000dead";

        await expect(marketplace.connect(otherAccount).addSupportedToken(tokenName, tokenAddress)).to.be.reverted;
      });

      it("Should revert if buyer is the seller", async function () {
        const { marketplace, owner, otherAccount } = await loadFixture(deployMarketplaceFixture);
        const id = 1;
        const ownerAddress = await owner.getAddress();

        const item = {
          id,
          seller: ownerAddress,
          price: 1000000,
          currency: "ETH",
          description: "A test item",
          title: "Test Item",
          photosIPFSHashes: ["QmaHj5MvsAD1ytkuQKVvS5jHPBzREojpFCHwzSevdCapCn"],
          itemStatus: 0,
          condition: 0,
          category: "Electronics",
          subcategory: "Laptops",
          country: "USA",
          isGift: false,
        };

        const newItemId = await marketplace.connect(owner).listNewItem.staticCall(item);

        await marketplace.listNewItem(item);

        await expect(marketplace.connect(owner).buyItemWithoutModerator(ownerAddress, newItemId)).to.be.revertedWithCustomError(marketplace, "SellerCannotBuyItsItem");
      });

      it("Should not revert buy item without moderator", async function () {
        const { marketplace, owner, users, otherAccount } = await loadFixture(deployMarketplaceFixture);
        const id = 1;
        const ownerAddress = await owner.getAddress();

        // setup other acc
        const mockProfileData = {
          username: "joshdoe123",
          firstName: "Josh",
          lastName: "Doe",
          country: "USA",
          description: "A passionate blockchain developer.",
          email: "johndoe@example.com",
          avatarHash: "QmTzQ1NcReB9kJc7FxjZyLg9mEsK9RJ7HnH7ZC8mG9R6xP",
          isModerator: false,
          moderatorFee: 0,
        };
        await users
          .connect(otherAccount)
          .createProfile(
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

        const item = {
          id,
          seller: ownerAddress,
          price: 1000000,
          currency: "ETH",
          description: "A test item",
          title: "Test Item",
          photosIPFSHashes: ["QmaHj5MvsAD1ytkuQKVvS5jHPBzREojpFCHwzSevdCapCn"],
          itemStatus: 0,
          condition: 0,
          category: "Electronics",
          subcategory: "Laptops",
          country: "USA",
          isGift: false,
        };

        const newItemId = await marketplace.connect(owner).listNewItem.staticCall(item);

        await marketplace.listNewItem(item);

        await expect(marketplace.connect(otherAccount).buyItemWithoutModerator(ownerAddress, newItemId, { value: 1000000 })).to.not.be.reverted;
      });

      it("Should not revert buy item without moderator + check allowance", async function () {
        const { marketplace, owner, users, escrow, otherAccount, mockERC20 } = await loadFixture(deployMarketplaceFixture);
        const id = 1;
        const ownerAddress = await owner.getAddress();
        const otherAccountAddress = await otherAccount.getAddress();
        const marketplaceAddress = await marketplace.getAddress();
        const escrowAddress = await escrow.getAddress();

        // setup other acc
        const mockProfileData = {
          username: "joshdoe123",
          firstName: "Josh",
          lastName: "Doe",
          country: "USA",
          description: "A passionate blockchain developer.",
          email: "johndoe@example.com",
          avatarHash: "QmTzQ1NcReB9kJc7FxjZyLg9mEsK9RJ7HnH7ZC8mG9R6xP",
          isModerator: false,
          moderatorFee: 0,
        };
        await users
          .connect(otherAccount)
          .createProfile(
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

        const item = {
          id,
          seller: ownerAddress,
          price: 1000000,
          currency: "MOCK",
          description: "A test item",
          title: "Test Item",
          photosIPFSHashes: ["QmaHj5MvsAD1ytkuQKVvS5jHPBzREojpFCHwzSevdCapCn"],
          itemStatus: 0,
          condition: 0,
          category: "Electronics",
          subcategory: "Laptops",
          country: "USA",
          isGift: false,
        };

        const newItemId = await marketplace.connect(owner).listNewItem.staticCall(item);

        await marketplace.listNewItem(item);

        // transfer and approve mock tokens
        await mockERC20.transfer(otherAccountAddress, 1000000);
        await mockERC20.connect(otherAccount).approve(marketplaceAddress, 1000000);
        await mockERC20.connect(otherAccount).approve(escrowAddress, 1000000);

        await expect(marketplace.connect(otherAccount).buyItemWithoutModerator(ownerAddress, newItemId)).to.not.be.reverted;
      });

      it("Should not revert buy item without moderator", async function () {
        const { marketplace, owner, users, otherAccount, escrow } = await loadFixture(deployMarketplaceFixture);
        const id = 1;
        const ownerAddress = await owner.getAddress();

        await escrow.setMarketplaceContractAddress(ownerAddress);

        // setup other acc
        const mockProfileData = {
          username: "joshdoe123",
          firstName: "Josh",
          lastName: "Doe",
          country: "USA",
          description: "A passionate blockchain developer.",
          email: "johndoe@example.com",
          avatarHash: "QmTzQ1NcReB9kJc7FxjZyLg9mEsK9RJ7HnH7ZC8mG9R6xP",
          isModerator: false,
          moderatorFee: 0,
        };
        await users
          .connect(otherAccount)
          .createProfile(
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

        const item = {
          id,
          seller: ownerAddress,
          price: 1000000,
          currency: "ETH",
          description: "A test item",
          title: "Test Item",
          photosIPFSHashes: ["QmaHj5MvsAD1ytkuQKVvS5jHPBzREojpFCHwzSevdCapCn"],
          itemStatus: 0,
          condition: 0,
          category: "Electronics",
          subcategory: "Laptops",
          country: "USA",
          isGift: false,
        };

        const newItemId = await marketplace.connect(owner).listNewItem.staticCall(item);

        await marketplace.listNewItem(item);

        await expect(marketplace.connect(otherAccount).buyItemWithoutModerator(ownerAddress, newItemId, { value: 1000000 })).to.be.revertedWith("Transaction creation failed");
      });

      it("Should revert if moderator is not valid", async function () {
        const { marketplace, otherAccount, owner } = await loadFixture(deployMarketplaceFixture);
        const id = 1;
        const moderator = "0x000000000000000000000000000000000000beef";

        const ownerAddress = await owner.getAddress();

        const item = {
          id,
          seller: ownerAddress,
          price: 1000000,
          currency: "ETH",
          description: "A test item",
          title: "Test Item",
          photosIPFSHashes: ["QmaHj5MvsAD1ytkuQKVvS5jHPBzREojpFCHwzSevdCapCn"],
          itemStatus: 0,
          condition: 0,
          category: "Electronics",
          subcategory: "Laptops",
          country: "USA",
          isGift: false,
        };

        const newItemId = await marketplace.connect(owner).listNewItem.staticCall(item);

        await marketplace.listNewItem(item);

        await expect(marketplace.connect(otherAccount).buyItem(ownerAddress, newItemId, moderator)).to.be.revertedWithCustomError(marketplace, "MustBeModerator");
      });

      it("Should not revert buy item with moderator", async function () {
        const { marketplace, owner, users, otherAccount, escrow, moderatorAcc } = await loadFixture(deployMarketplaceFixture);
        const id = 1;
        const ownerAddress = await owner.getAddress();

        // setup other acc
        const mockProfileData = {
          username: "joshdoe123",
          firstName: "Josh",
          lastName: "Doe",
          country: "USA",
          description: "A passionate blockchain developer.",
          email: "johndoe@example.com",
          avatarHash: "QmTzQ1NcReB9kJc7FxjZyLg9mEsK9RJ7HnH7ZC8mG9R6xP",
          isModerator: false,
          moderatorFee: 0,
        };
        await users
          .connect(otherAccount)
          .createProfile(
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

        const item = {
          id,
          seller: ownerAddress,
          price: 1000000,
          currency: "ETH",
          description: "A test item",
          title: "Test Item",
          photosIPFSHashes: ["QmaHj5MvsAD1ytkuQKVvS5jHPBzREojpFCHwzSevdCapCn"],
          itemStatus: 0,
          condition: 0,
          category: "Electronics",
          subcategory: "Laptops",
          country: "USA",
          isGift: false,
        };

        const newItemId = await marketplace.connect(owner).listNewItem.staticCall(item);

        await marketplace.listNewItem(item);

        await expect(marketplace.connect(otherAccount).buyItem(ownerAddress, newItemId, moderatorAcc, { value: 1000000 })).to.not.be.reverted;
      });

      it("Should not revert buy item with moderator and stablecoins", async function () {
        const { marketplace, owner, users, otherAccount, escrow, moderatorAcc, mockERC20 } = await loadFixture(deployMarketplaceFixture);
        const id = 1;
        const ownerAddress = await owner.getAddress();

        const otherAccountAddress = await otherAccount.getAddress();
        const marketplaceAddress = await marketplace.getAddress();
        const escrowAddress = await escrow.getAddress();

        // setup other acc
        const mockProfileData = {
          username: "joshdoe123",
          firstName: "Josh",
          lastName: "Doe",
          country: "USA",
          description: "A passionate blockchain developer.",
          email: "johndoe@example.com",
          avatarHash: "QmTzQ1NcReB9kJc7FxjZyLg9mEsK9RJ7HnH7ZC8mG9R6xP",
          isModerator: false,
          moderatorFee: 0,
        };
        await users
          .connect(otherAccount)
          .createProfile(
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

        const item = {
          id,
          seller: ownerAddress,
          price: 1000000,
          currency: "MOCK",
          description: "A test item",
          title: "Test Item",
          photosIPFSHashes: ["QmaHj5MvsAD1ytkuQKVvS5jHPBzREojpFCHwzSevdCapCn"],
          itemStatus: 0,
          condition: 0,
          category: "Electronics",
          subcategory: "Laptops",
          country: "USA",
          isGift: false,
        };

        const newItemId = await marketplace.connect(owner).listNewItem.staticCall(item);

        await mockERC20.transfer(otherAccountAddress, 1000000);
        await mockERC20.connect(otherAccount).approve(marketplaceAddress, 1000000);
        await mockERC20.connect(otherAccount).approve(escrowAddress, 1000000);

        await marketplace.listNewItem(item);

        await expect(marketplace.connect(otherAccount).buyItem(ownerAddress, newItemId, moderatorAcc, { value: 1000000 })).to.not.be.reverted;
      });

      it("Should revert buy item with moderator and stablecoins", async function () {
        const { marketplace, owner, users, otherAccount, escrow, moderatorAcc, mockERC20 } = await loadFixture(deployMarketplaceFixture);
        const id = 1;
        const ownerAddress = await owner.getAddress();

        await escrow.setMarketplaceContractAddress(ownerAddress);

        const otherAccountAddress = await otherAccount.getAddress();
        const marketplaceAddress = await marketplace.getAddress();
        const escrowAddress = await escrow.getAddress();

        // setup other acc
        const mockProfileData = {
          username: "joshdoe123",
          firstName: "Josh",
          lastName: "Doe",
          country: "USA",
          description: "A passionate blockchain developer.",
          email: "johndoe@example.com",
          avatarHash: "QmTzQ1NcReB9kJc7FxjZyLg9mEsK9RJ7HnH7ZC8mG9R6xP",
          isModerator: false,
          moderatorFee: 0,
        };
        await users
          .connect(otherAccount)
          .createProfile(
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

        const item = {
          id,
          seller: ownerAddress,
          price: 1000000,
          currency: "MOCK",
          description: "A test item",
          title: "Test Item",
          photosIPFSHashes: ["QmaHj5MvsAD1ytkuQKVvS5jHPBzREojpFCHwzSevdCapCn"],
          itemStatus: 0,
          condition: 0,
          category: "Electronics",
          subcategory: "Laptops",
          country: "USA",
          isGift: false,
        };

        const newItemId = await marketplace.connect(owner).listNewItem.staticCall(item);

        await mockERC20.transfer(otherAccountAddress, 1000000);
        await mockERC20.connect(otherAccount).approve(marketplaceAddress, 1000000);
        await mockERC20.connect(otherAccount).approve(escrowAddress, 1000000);

        await marketplace.listNewItem(item);

        await expect(marketplace.connect(otherAccount).buyItem(ownerAddress, newItemId, moderatorAcc, { value: 1000000 })).to.be.revertedWith("Transaction creation failed");
      });

      it("Should not revert delete item", async function () {
        const { marketplace, owner } = await loadFixture(deployMarketplaceFixture);
        const id = 1;
        const ownerAddress = await owner.getAddress();

        const item = {
          id,
          seller: ownerAddress,
          price: 1000000,
          currency: "MOCK",
          description: "A test item",
          title: "Test Item",
          photosIPFSHashes: ["QmaHj5MvsAD1ytkuQKVvS5jHPBzREojpFCHwzSevdCapCn"],
          itemStatus: 0,
          condition: 0,
          category: "Electronics",
          subcategory: "Laptops",
          country: "USA",
          isGift: false,
        };

        const newItemId = await marketplace.connect(owner).listNewItem.staticCall(item);

        await marketplace.listNewItem(item);

        await expect(marketplace.deleteItem(newItemId)).to.not.be.reverted;
      });

      it("Should not revert update item", async function () {
        const { marketplace, owner } = await loadFixture(deployMarketplaceFixture);
        const id = 1;
        const ownerAddress = await owner.getAddress();

        const item = {
          id,
          seller: ownerAddress,
          price: 1000000,
          currency: "MOCK",
          description: "A test item",
          title: "Test Item",
          photosIPFSHashes: ["QmaHj5MvsAD1ytkuQKVvS5jHPBzREojpFCHwzSevdCapCn"],
          itemStatus: 0,
          condition: 0,
          category: "Electronics",
          subcategory: "Laptops",
          country: "USA",
          isGift: false,
        };

        const newItemId = await marketplace.connect(owner).listNewItem.staticCall(item);

        await marketplace.listNewItem(item);

        const itemUpdate = {
          id: newItemId,
          seller: ownerAddress,
          price: 1000001,
          currency: "ETH",
          description: "A test item update",
          title: "Test Item",
          photosIPFSHashes: ["QmaHj5MvsAD1ytkuQKVvS5jHPBzREojpFCHwzSevdCapCn"],
          itemStatus: 0,
          condition: 0,
          category: "Electronics",
          subcategory: "Laptops",
          country: "USA",
          isGift: false,
        };

        await expect(marketplace.connect(owner).updateItem(itemUpdate)).to.not.be.reverted;
      });
    });
  });
});
