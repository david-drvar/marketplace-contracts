const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time, loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("Users", function () {
  async function deployUsersFixture() {
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
    const { users } = await loadFixture(deployUsersFixture);
    expect(await users.maxModeratorFee()).to.be.equal(20);
  });

  it("should allow profile update", async function () {
    const { users, otherAccount } = await loadFixture(deployUsersFixture);

    const mockProfileUpdate = {
      username: "otheracc123",
      firstName: "John",
      lastName: "Doe",
      country: "IT",
      description: "A passionate blockchain developer.",
      email: "johndoe@example.com",
      avatarHash: "QmTzQ1NcReB9kJc7FxjZyLg9mEsK9RJ7HnH7ZC8mG9R6xP",
      isModerator: false,
      moderatorFee: 5,
    };
    await users
      .connect(otherAccount)
      .createProfile(
        mockProfileUpdate.username,
        mockProfileUpdate.firstName,
        mockProfileUpdate.lastName,
        mockProfileUpdate.country,
        mockProfileUpdate.description,
        mockProfileUpdate.email,
        mockProfileUpdate.avatarHash,
        mockProfileUpdate.isModerator,
        mockProfileUpdate.moderatorFee
      );

    expect(
      await users
        .connect(otherAccount)
        .updateProfile(
          mockProfileUpdate.username,
          mockProfileUpdate.firstName,
          mockProfileUpdate.lastName,
          mockProfileUpdate.country,
          mockProfileUpdate.description,
          mockProfileUpdate.email,
          mockProfileUpdate.avatarHash,
          mockProfileUpdate.isModerator,
          mockProfileUpdate.moderatorFee
        )
    ).to.not.be.reverted;
  });

  it("should set moderator max fee only owner", async function () {
    const { users } = await loadFixture(deployUsersFixture);

    await users.setMaxModeratorFee(15);

    expect(await users.maxModeratorFee()).to.be.equal(15);
  });

  it("should check user registered", async function () {
    const { users, owner } = await loadFixture(deployUsersFixture);

    const ownerAddress = await owner.getAddress();
    expect(await users.isRegisteredUser(ownerAddress)).to.be.equal(true);
  });

  it("should check user moderator", async function () {
    const { users, owner } = await loadFixture(deployUsersFixture);

    const ownerAddress = await owner.getAddress();
    expect(await users.isModerator(ownerAddress)).to.be.equal(true);
  });

  it("should get user profile", async function () {
    const { users, owner } = await loadFixture(deployUsersFixture);

    const ownerAddress = await owner.getAddress();
    expect(await users.getProfile(ownerAddress)).to.not.be.reverted;
  });

  it("should create review", async function () {
    const { marketplace, owner, users, otherAccount } = await loadFixture(deployUsersFixture);
    const id = 1;
    const ownerAddress = await owner.getAddress();

    // steps
    // list item -owner
    // buy item without moderator - otherAcc
    // create review - otherAcc

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

    await marketplace.connect(otherAccount).buyItemWithoutModerator(ownerAddress, newItemId, { value: 1000000 });

    expect(await users.connect(otherAccount).createReview(ownerAddress, newItemId, 3, "good seller")).to.not.be.reverted;

    await expect(users.connect(otherAccount).createReview(ownerAddress, newItemId, 3, "good seller 2")).to.be.revertedWithCustomError(users, "AlreadyReviewed").withArgs();
  });
});
