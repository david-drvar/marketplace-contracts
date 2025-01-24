const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("Escrow", function () {
  async function deployEscrowFixture() {
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
    await escrow.setUsersContractAddress(usersAddress);

    await users.setEscrowContractAddress(escrowAddress);

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

  it("check deployment valid", async function () {
    const { escrow } = await loadFixture(deployEscrowFixture);
    expect(await escrow.usersContract()).to.not.be.reverted;
  });

  it("should finalize transaction after two approvals", async function () {
    // steps
    // list item
    // buy item with moderator
    // approve 2 times

    const { marketplace, owner, users, otherAccount, escrow, moderatorAcc } = await loadFixture(deployEscrowFixture);
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
      currency: "POL",
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

    await marketplace.connect(otherAccount).buyItem(newItemId, moderatorAcc, { value: 1100000 });

    await expect(escrow.connect(otherAccount).approve(newItemId)).to.not.be.reverted;
    await expect(escrow.connect(owner).approve(newItemId)).to.not.be.reverted;
  });

  it("should finalize transaction with stablecoins after two approvals", async function () {
    const { marketplace, owner, users, otherAccount, escrow, moderatorAcc, mockERC20 } = await loadFixture(deployEscrowFixture);
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

    // approve stablecoin spendings
    await mockERC20.transfer(otherAccountAddress, 1100000);
    await mockERC20.connect(otherAccount).approve(marketplaceAddress, 1100000);
    await mockERC20.connect(otherAccount).approve(escrowAddress, 1100000);

    await expect(marketplace.connect(otherAccount).buyItem(newItemId, moderatorAcc)).to.not.be.reverted;

    await expect(escrow.connect(otherAccount).approve(newItemId)).to.not.be.reverted;
    await expect(escrow.connect(owner).approve(newItemId)).to.not.be.reverted;
  });

  it("should finalize transaction by moderator after approval and dispute", async function () {
    // steps
    // list item
    // buy item with moderator
    // approve
    // dispute
    // finalize by moderator

    const { marketplace, owner, users, otherAccount, escrow, moderatorAcc } = await loadFixture(deployEscrowFixture);
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
      currency: "POL",
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

    await marketplace.connect(otherAccount).buyItem(newItemId, moderatorAcc, { value: 1100000 });

    await expect(escrow.connect(otherAccount).approve(newItemId)).to.not.be.reverted;
    await expect(escrow.connect(owner).raiseDispute(newItemId)).to.not.be.reverted;

    // finalize by moderator
    await expect(escrow.connect(moderatorAcc).finalizeTransactionByModerator(newItemId, 20, 30)).to.be.revertedWithCustomError(escrow, "ValueDistributionNotCorrect");
    await expect(escrow.connect(moderatorAcc).finalizeTransactionByModerator(newItemId, 80, 20)).to.not.be.reverted;
  });

  it("should finalize transaction by moderator after approval and dispute with stablecoins", async function () {
    // steps
    // list item
    // buy item with moderator
    // approve
    // dispute
    // finalize by moderator

    const { marketplace, owner, users, otherAccount, escrow, moderatorAcc, mockERC20 } = await loadFixture(deployEscrowFixture);
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

    // approve stablecoin spendings
    await mockERC20.transfer(otherAccountAddress, 1100000);
    await mockERC20.connect(otherAccount).approve(marketplaceAddress, 1100000);
    await mockERC20.connect(otherAccount).approve(escrowAddress, 1100000);

    await marketplace.connect(otherAccount).buyItem(newItemId, moderatorAcc);

    await expect(escrow.connect(otherAccount).approve(newItemId)).to.not.be.reverted;
    await expect(escrow.connect(owner).raiseDispute(newItemId)).to.not.be.reverted;

    // finalize by moderator
    await expect(escrow.connect(moderatorAcc).finalizeTransactionByModerator(newItemId, 20, 30)).to.be.revertedWithCustomError(escrow, "ValueDistributionNotCorrect");
    await expect(escrow.connect(moderatorAcc).finalizeTransactionByModerator(newItemId, 80, 20)).to.not.be.reverted;
  });
});
