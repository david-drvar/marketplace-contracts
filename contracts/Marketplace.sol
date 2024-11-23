// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


interface IUsers {

    struct UserProfile {
        address userAddress;
        string username;
        string firstName;
        string lastName;
        string country;
        string description;
        string email;
        string avatarHash;
        bool isModerator;
        bool exists;
        uint8 moderatorFee;
    }

    event UserRegistered(address indexed userAddress, string username, string firstName,
        string lastName, string country, string description, string email, string avatarHash, bool isModerator, uint8 moderatorFee);
    event UserUpdated(address indexed userAddress, string username, string firstName,
        string lastName, string country, string description, string email, string avatarHash, bool isModerator, uint8 moderatorFee);

    function createProfile(string memory _username, string memory _firstName, string memory _lastName, string memory _country,
        string memory _description, string memory _email, string memory _avatarHash, bool _isModerator, uint8 _moderatorFee) external;

    function updateProfile(string memory _username, string memory _firstName, string memory _lastName, string memory _country,
        string memory _description, string memory _email, string memory _avatarHash, bool _isModerator, uint8 _moderatorFee) external;

    function isRegisteredUser(address _user) external view returns (bool);

    function isModerator(address _user) external view returns (bool);

    function getProfile(address _user) external view returns (UserProfile memory);
}



interface IEscrow {

    struct Transaction {
        uint256 itemId;
        address seller;
        address moderator;
        address buyer;
        uint256 price;
        string currency;
        uint8 moderatorFee;
        bool buyerApproved;
        bool sellerApproved;
        bool disputed;
        bool disputedBySeller;
        bool disputedByBuyer;
        bool isCompleted;
        uint256 creationTime;
    }

    event TransactionCreated(uint256 indexed itemId, address indexed buyer, address indexed seller, 
        address moderator, uint256 price, string currency, uint8 moderatorFee, uint256 creationTime);
    event TransactionCreatedWithoutModerator(uint256 indexed itemId, address indexed buyer, address indexed seller, 
        uint256 price, string currency, uint256 creationTime);
    event TransactionApproved(uint256 indexed itemId, address approver);
    event TransactionCompleted(uint256 indexed itemId);
    event TransactionCompletedByModerator(uint256 indexed itemId, uint8 buyerPercentage, uint8 sellerPercentage);
    event TransactionDisputed(uint256 indexed itemId, address disputer);

    error OnlyModerator();
    error OnlySeller();
    error OnlyBuyer();
    error OnlyBuyerOrSeller();
    error TxCantBeCompleted();
    error ValueDistributionNotCorrect();
    error TxExists(uint256 id);
    error OnlyMarketplaceContractCanCall();
    error OnlyUsersContractCanCall();
    error MustBeDisputed();

    function addSupportedToken(string memory tokenName, address tokenAddress) external;

    function setMarketplaceContractAddress(address _marketplaceContractAddress) external;

    function setUsersContractAddress(address _usersContractAddress) external;

    function createTransaction(
        uint256 _itemId,
        address _seller,
        address _buyer,
        address _moderator,
        uint256 _price,
        string memory _currency,
        uint8 _moderatorFee
    ) external payable;

    function createTransactionWithoutModerator(
        uint256 _itemId,
        address _seller,
        address _buyer,
        uint256 _price,
        string memory _currency
    ) external payable;

    function approve(uint256 _itemId) external;

    function raiseDispute(uint256 _itemId) external;

    function finalizeTransactionByModerator(uint256 _itemId, uint8 percentageSeller, uint8 percentageBuyer) external payable;

    function isTransactionReadyForReview(uint256 _itemId, address from, address to) external view returns (bool);
}



error PriceMustBeAboveZero();
error ItemNotListed(address sellerAddress, uint256 id);
error ItemNotBelongsToSeller(address sellerAddress, uint256 id);
error SellerCannotBuyItsItem(address sellerAddress);
error PhotoLimitExceeded();
error NotIPFSHash(string hash);
error MustBeModerator(address moderator);
error ModeratorCantBeBuyerOrSeller();
error NotValidCategoryAndSubcategory();
error MustNotBeGift();
error TokenNotSupported();
error UserNotRegistered();


contract Marketplace is Initializable, OwnableUpgradeable {

    enum ItemStatus {
        LISTED,
        BOUGHT,
        DELETED
    }

    enum Condition {
        NEW,
        LIKE_NEW,
        EXCELLENT,
        GOOD,
        DAMAGED
    }

    struct Item {
        uint256 id;
        address seller;
        uint256 price;
        string currency;
        string description;
        string title;
        string[] photosIPFSHashes;
        ItemStatus itemStatus;
        Condition condition;
        string category;
        string subcategory;
        string country;
        bool isGift;
    }

    uint8 constant public MAX_PHOTO_LIMIT = 3;

    uint256 itemCount;
    mapping(address => mapping(uint256 => Item)) private items; //mapping seller address to mapping of id to Item
    mapping(string => string[]) private categories; // mapping category name to list of subcategories
    mapping(string => address) public supportedTokens; // mapping tokenName ("ETH", "USDC"...) to token contract address

    event ItemListed(uint256 indexed id, address indexed seller, string title, string description, uint256 price, string currency, string[] photosIPFSHashes, Condition condition,
        string category, string subcategory, string country, bool isGift);
    event ItemUpdated(uint256 indexed id, address indexed seller, string title, string description, uint256 price, string currency, string[] photosIPFSHashes, Condition condition,
        string category, string subcategory, string country, bool isGift);
    event ItemBought(uint256 indexed id, address indexed seller, address indexed buyer);
    event ItemDeleted(uint256 indexed id, address indexed seller);

    IEscrow public escrowContract;
    IUsers public usersContract;

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner); // Initialize OwnableUpgradeable
        transferOwnership(initialOwner); // Set the owner explicitly

        // Initialize categories
        categories["Electronics"] = ["Mobile Phones", "Laptops", "Cameras", "Headphones", "Smart Watches", "Other"];
        categories["Clothing"] = ["Men's Apparel", "Women's Apparel", "Kids' Apparel", "Accessories", "Man's shoes", "Women's shoes", "Other"];
        categories["Furniture"] = ["Living Room", "Bedroom", "Office", "Outdoor", "Other"];
        categories["Toys"] = ["Educational", "Outdoor", "Action Figures", "Building Sets", "Other"];
        categories["Books"] = ["Fiction", "Non-Fiction", "Children's Books", "Textbooks", "Other"];
        categories["Sports"] = ["Equipment", "Apparel", "Footwear", "Accessories", "Other"];
        categories["Home Appliances"] = ["Kitchen", "Laundry", "Heating & Cooling", "Other"];
        categories["Beauty"] = ["Skincare", "Makeup", "Fragrances", "Hair Care", "Other"];
        categories["Automotive"] = ["Parts", "Accessories", "Tools", "Other"];
        categories["Collectibles"] = ["Coins", "Stamps", "Trading Cards", "Art", "Other"];

        // Initialize supported tokens
        supportedTokens["ETH"] = address(this);
    }

    modifier isListed(address sellerAddress, uint256 id) {
        if (items[sellerAddress][id].price < 0) {
            revert ItemNotListed(sellerAddress, id);
        }
        else if (items[sellerAddress][id].itemStatus != ItemStatus.LISTED) {
            revert ItemNotListed(sellerAddress, id);
        }
        _;
    }

    modifier belongsToSeller(address sellerAddress, uint256 id) {
        if (items[sellerAddress][id].seller != sellerAddress) {
            revert ItemNotBelongsToSeller(sellerAddress, id);
        }
        _;
    }

    modifier notSeller(address sellerAddress, address buyerAddress) {
        if (buyerAddress == sellerAddress) {
            revert SellerCannotBuyItsItem(sellerAddress);
        }
        _;
    }

    modifier mustBeModerator(address moderator) {
        if (!usersContract.isModerator(moderator)) {
            revert MustBeModerator(moderator);
        }
        _;
    }

    modifier notGift(address sellerAddress, uint256 id) {
        if (items[sellerAddress][id].isGift) {
            revert MustNotBeGift();
        }
        _;
    }

    modifier priceMustBeAboveOrEqualZero(uint256 price) {
        if (price < 0) {
            revert PriceMustBeAboveZero();
        }
        _;
    }

    modifier numberOfPhotosMustBeBelowLimit(string[] memory photosIPFSHashes) {
        if (photosIPFSHashes.length > MAX_PHOTO_LIMIT) {
            revert PhotoLimitExceeded();
        }
        _;
    }

    modifier moderatorCantBeBuyerOrSeller(address _moderator, address sellerAddress) {
        if (_moderator == sellerAddress || _moderator == msg.sender) {
            revert ModeratorCantBeBuyerOrSeller();
        }
        _;
    }

    modifier isValidCategoryAndSubcategory(string memory category, string memory subcategory) {
        bool isOkay = false;
        for (uint i = 0; i < categories[category].length; i++) {
            if (keccak256(abi.encodePacked(categories[category][i])) == keccak256(abi.encodePacked(subcategory))) {
                isOkay =true;
            }
        }
        if (!isOkay) {
            revert NotValidCategoryAndSubcategory();
        }
        _;
    }


    modifier isValidIPFSHashes(string[] memory photosIPFSHashes) {
        for (uint i = 0; i < photosIPFSHashes.length; i++) {
            if (!isIPFSHash(photosIPFSHashes[i])) {
                revert NotIPFSHash(photosIPFSHashes[i]);
            }
        }
        _;
    }

    modifier supportedToken(string memory tokenName) {
        if (supportedTokens[tokenName] == address(0)) {
            revert TokenNotSupported();
        }
        _;
    }

    modifier userRegistered() {
        if (!usersContract.isRegisteredUser(msg.sender)) {
            revert UserNotRegistered();
        }
        _;
    }

    function setUsersContractAddress(address _usersContractAddress) external 
        onlyOwner {
        usersContract = IUsers(_usersContractAddress);
    }

    function setEscrowContractAddress(address _escrowContractAddress) external 
        onlyOwner {
        escrowContract = IEscrow(_escrowContractAddress);
    }

    function addSupportedToken(string memory tokenName, address tokenAddress) external onlyOwner {
        supportedTokens[tokenName] = tokenAddress;
    }

    function listNewItem(
        Item memory item
        ) 
        external 
        priceMustBeAboveOrEqualZero(item.price) 
        numberOfPhotosMustBeBelowLimit(item.photosIPFSHashes)    
        isValidCategoryAndSubcategory(item.category, item.subcategory)
        isValidIPFSHashes(item.photosIPFSHashes)
        supportedToken(item.currency)
        userRegistered()
        {

        finalizeListItem(item);
    }

    function finalizeListItem(
        Item memory item
    )   internal {
    
        itemCount++;
        uint256 id = createHash(itemCount, msg.sender);
        if (item.isGift)
            item.price = 0;

        items[msg.sender][id] = Item(id, msg.sender, item.price, item.currency,item.description, item.title, item.photosIPFSHashes, ItemStatus.LISTED, item.condition, item.category, item.subcategory, item.country, item.isGift);
        emit ItemListed(id, msg.sender, item.title, item.description, item.price, item.currency, item.photosIPFSHashes, item.condition, item.category, item.subcategory, item.country, item.isGift);
    }

    function updateItem(Item memory item) external
        belongsToSeller(msg.sender, item.id) 
        priceMustBeAboveOrEqualZero(item.price) 
        numberOfPhotosMustBeBelowLimit(item.photosIPFSHashes)
        isListed(msg.sender, item.id) 
        isValidIPFSHashes(item.photosIPFSHashes)
        isValidCategoryAndSubcategory(item.category, item.subcategory)
        supportedToken(item.currency)
        {
        if (item.isGift)
            item.price = 0;
            
        finalizeUpdateItem(item);
    }

    function finalizeUpdateItem(Item memory item) internal {
        items[msg.sender][item.id] = Item(item.id, msg.sender, item.price, item.currency,item.description, item.title, item.photosIPFSHashes,ItemStatus.LISTED, item.condition, item.category, item.subcategory, item.country, item.isGift);
        emit ItemUpdated(item.id, msg.sender, item.title, item.description, item.price, item.currency, item.photosIPFSHashes, item.condition, item.category, item.subcategory, item.country, item.isGift);
    }

    function isIPFSHash(string memory hash) private pure returns (bool) {
        bytes memory hashBytes = bytes(hash);
        if (hashBytes.length != 46) {
            return false;
        }
        if (hashBytes[0] != 0x51 || hashBytes[1] != 0x6D) {
            return false; // "Qm" prefix
        }
        for (uint i = 2; i < hashBytes.length; i++) {
            bytes1 char = hashBytes[i];
            if (!(char >= 0x30 && char <= 0x39) && // 0-9
                !(char >= 0x41 && char <= 0x5A) && // A-Z
                !(char >= 0x61 && char <= 0x7A)) { // a-z
                return false;
            }
        }
        return true;
    }

    function createHash(uint256 id, address addr) private pure returns (uint256) {
        bytes32 hashInput = keccak256(abi.encodePacked(id, addr));
        uint256 idHash = uint256(hashInput); // Convert the concatenated bytes32 hash to uint256
        return idHash;
    }

    function deleteItem(uint256 id) isListed(msg.sender, id) external 
        belongsToSeller(msg.sender, id)  {
        items[msg.sender][id].itemStatus = ItemStatus.DELETED;
        emit ItemDeleted(id, msg.sender);
    }

    function buyItem(address sellerAddress, uint256 id, address _moderator) external payable 
        isListed(sellerAddress, id) 
        belongsToSeller(sellerAddress, id) 
        notSeller(sellerAddress, msg.sender) 
        mustBeModerator(_moderator) 
        notGift(sellerAddress, id)
        userRegistered()
        {
        if (keccak256(abi.encodePacked(items[sellerAddress][id].currency)) == keccak256(abi.encodePacked("ETH"))) {
            require(msg.value >= items[sellerAddress][id].price, "Incorrect ETH amount");
        }
        else {
            // check if buyer(sender) has allowed marketplace contract to transfer funds
            require(IERC20(supportedTokens[items[sellerAddress][id].currency]).allowance(msg.sender, address(this)) >= items[sellerAddress][id].price, "Insufficient allowance for marketplace contract");
            
            // sender must have enough token balance on his address
            require(IERC20(supportedTokens[items[sellerAddress][id].currency]).balanceOf(msg.sender) >= items[sellerAddress][id].price, "Insufficient token balance");
        }
        finalizeBuyItem(sellerAddress, id, _moderator);
    }

    function finalizeBuyItem(address sellerAddress, uint256 id, address _moderator) private 
        moderatorCantBeBuyerOrSeller(_moderator, sellerAddress){
            
        // transfer tokens to escrow address
        if (keccak256(abi.encodePacked(items[sellerAddress][id].currency)) != keccak256(abi.encodePacked("ETH"))) {
            bool success = IERC20(supportedTokens[items[sellerAddress][id].currency]).transferFrom(msg.sender, address(escrowContract), items[sellerAddress][id].price);
            require(success, "Token transfer failed");
        }

        // create transaction
        try escrowContract.createTransaction{value: msg.value}(id, sellerAddress, msg.sender,_moderator,items[sellerAddress][id].price,  items[sellerAddress][id].currency, usersContract.getProfile(_moderator).moderatorFee) {
            items[sellerAddress][id].itemStatus = ItemStatus.BOUGHT;
            emit ItemBought(id, sellerAddress, msg.sender);
        }
        catch {
            revert("Transaction creation failed");
        }
    }

    function buyItemWithoutModerator(address sellerAddress, uint256 id) external payable 
        isListed(sellerAddress, id) 
        belongsToSeller(sellerAddress, id) 
        notSeller(sellerAddress, msg.sender) 
        userRegistered()
        {

        if (keccak256(abi.encodePacked(items[sellerAddress][id].currency)) == keccak256(abi.encodePacked("ETH"))) {
            require(msg.value >= items[sellerAddress][id].price, "Incorrect ETH amount");
        }
        else {
            // check if buyer(sender) has allowed escrow contract to transfer funds
            require(IERC20(supportedTokens[items[sellerAddress][id].currency]).allowance(msg.sender, address(escrowContract)) >= items[sellerAddress][id].price, "Insufficient allowance for escrow contract");
            
            // sender must have enough token balance on his address
            require(IERC20(supportedTokens[items[sellerAddress][id].currency]).balanceOf(msg.sender) >= items[sellerAddress][id].price, "Insufficient token balance");
        }

        finalizeBuyItemWithoutModerator(sellerAddress, id);
    }

    function finalizeBuyItemWithoutModerator(address sellerAddress, uint256 id) private {
        try escrowContract.createTransactionWithoutModerator{value: msg.value}(id, sellerAddress, msg.sender,items[sellerAddress][id].price, items[sellerAddress][id].currency) {
            items[sellerAddress][id].itemStatus = ItemStatus.BOUGHT;
            emit ItemBought(id, sellerAddress, msg.sender);
        }
        catch {
            revert("Transaction creation failed");
        }
    }

    function getItemCount() public view returns (uint256) {
        return itemCount;
    }
}