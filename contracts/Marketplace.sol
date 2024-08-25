// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

error PriceMustBeAboveZero();
error ItemNotListed(address sellerAddress, uint256 id);
error ItemNotBelongsToSeller(address sellerAddress, uint256 id);
error SellerCannotBuyItsItem(address sellerAddress);
error SentValueDifferentThanItemPrice(address sellerAddress, uint256 id, uint256 value);
error PhotoLimitExceeded();
error NotIPFSHash(string hash);
error MustBeModerator(address moderator);


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
        uint256 moderatorFee;
    }

    // Events
    event UserRegistered(
        address indexed userAddress, 
        string indexed username, 
        string firstName,
        string lastName, 
        string country, 
        string description, 
        string email, 
        string avatarHash, 
        bool isModerator, 
        uint8 moderatorFee
    );
    
    event UserUpdated(
        address indexed userAddress, 
        string indexed username, 
        string firstName,
        string lastName, 
        string country, 
        string description, 
        string email, 
        string avatarHash, 
        bool isModerator, 
        uint8 moderatorFee
    );
    
    event UserDeleted(address indexed userAddress, string indexed username);

    // Functions
    function createProfile(
        string memory _username,
        string memory _firstName,
        string memory _lastName,
        string memory _country,
        string memory _description,
        string memory _email,
        string memory _avatarHash,
        bool _isModerator,
        uint8 _moderatorFee
    ) external;

    function updateProfile(
        string memory _username,
        string memory _firstName,
        string memory _lastName,
        string memory _country,
        string memory _description,
        string memory _email,
        string memory _avatarHash,
        bool _isModerator,
        uint8 _moderatorFee
    ) external;

    function deleteProfile() external;

    function isRegisteredUser(address _user) external view returns (bool);

    function isModerator(address _user) external view returns (bool);

    function getProfile(address _user) external view returns (UserProfile memory);
}




interface IEscrow {

    struct Moderator {
        address moderator;
        uint256 fee;
    }

    enum TransactionStatus {
        FUNDED,
        SHIPPED,
        RECEIVED
    }

    struct Transaction {
        uint256 itemId;
        address seller;
        address moderator;
        address buyer;
        uint256 price;
        TransactionStatus transactionStatus;
        bool buyerApproved;
        bool sellerApproved;
        bool moderatorApproved;
        bool disputed;
        bool isCompleted;
        uint256 creationTime;
    }

    // Getter for the marketplaceContract
    function marketplaceContract() external view returns (address);

    // Events
    event TransactionCreated(uint256 itemId, address buyer, address seller, uint256 price);
    event TransactionApproved(uint256 itemId, address approver);
    event TransactionCompleted(uint256 itemId);
    event TransactionDisputed(uint256 itemId);

    // Functions
    function setMarketplaceContractAddress(address _marketplaceContractAddress) external;

    function createTransaction(
        uint256 _itemId,
        address _seller,
        address _buyer,
        address _moderator,
        uint256 _price
    ) external payable;

    function approveByBuyer(uint256 _itemId) external;

    function approveBySeller(uint256 _itemId) external;

    function approveByModerator(uint256 _itemId) external;

    function raiseDispute(uint256 _itemId) external;
}




contract Marketplace is Ownable {

    enum ItemStatus {
        LISTED,
        BOUGHT,
        DELETED
    }

    struct Item {
        uint256 id;
        address seller;
        uint256 price;
        string description;
        string title;
        string[] photosIPFSHashes;
        ItemStatus itemStatus;
    }

    uint8 constant public MAX_PHOTO_LIMIT = 3;

    uint256 itemCount;
    mapping(address => mapping(uint256 => Item)) private items; //mapping seller address to mapping of id to Item

    event ItemListed(uint256 indexed id, address indexed seller, string title, string description, uint256 price, string[] photosIPFSHashes);
    event ItemUpdated(uint256 indexed id, address indexed seller, string title, string description, uint256 price, string[] photosIPFSHashes);
    event ItemBought(uint256 indexed id, address indexed seller, address indexed buyer);
    event ItemDeleted(uint256 indexed id, address indexed seller);

    IEscrow public escrowContract;
    IUsers public usersContract;

    constructor(address initialOwner, address _escrowContractAddress, address _usersContractAddress) Ownable(initialOwner) {
        escrowContract = IEscrow(_escrowContractAddress);
        usersContract = IUsers(_usersContractAddress);
    }


    modifier isListed(address sellerAddress, uint256 id) {
        Item memory listing = items[sellerAddress][id];
        if (listing.price <= 0) {
            revert ItemNotListed(sellerAddress, id);
        }
        else if (listing.itemStatus != ItemStatus.LISTED) {
            revert ItemNotListed(sellerAddress, id);
        }
        _;
    }

    modifier belongsToSeller(address sellerAddress, uint256 id) {
        Item memory listing = items[sellerAddress][id];
        if (listing.seller != sellerAddress) {
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

    modifier correctAmountSent(address sellerAddress, uint256 id) {
        if (items[sellerAddress][id].price != msg.value) {
            revert SentValueDifferentThanItemPrice(sellerAddress, id, msg.value);
        }
        _;
    }

    modifier priceMustBeAboveZero(uint256 price) {
        if (price <= 0) {
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

    function setUsersContractAddress(address _usersContractAddress) external 
        onlyOwner {
        usersContract = IUsers(_usersContractAddress);
    }

    function setEscrowContractAddress(address _escrowContractAddress) external 
        onlyOwner {
        escrowContract = IEscrow(_escrowContractAddress);
    }

    function listNewItem(string memory _title, string memory _description, uint256 _price, string[] memory photosIPFSHashes) external 
        priceMustBeAboveZero(_price) 
        numberOfPhotosMustBeBelowLimit(photosIPFSHashes) {

        for (uint i = 0; i < photosIPFSHashes.length; i++) {
            if (!isIPFSHash(photosIPFSHashes[i])) {
                revert NotIPFSHash(photosIPFSHashes[i]);
            }
        }
        
        itemCount++;
        uint256 id = createHash(itemCount, msg.sender);
        items[msg.sender][id] = Item(id, msg.sender, _price, _description, _title, photosIPFSHashes, ItemStatus.LISTED);
        emit ItemListed(id, msg.sender, _title, _description, _price, photosIPFSHashes);
    }

    function updateItem(uint256 id, string memory _title, string memory _description, uint256 _price, string[] memory photosIPFSHashes) external
        belongsToSeller(msg.sender, id) 
        isListed(msg.sender, id) 
        priceMustBeAboveZero(_price) 
        numberOfPhotosMustBeBelowLimit(photosIPFSHashes) {

        for (uint i = 0; i < photosIPFSHashes.length; i++) {
            if (!isIPFSHash(photosIPFSHashes[i])) {
                revert NotIPFSHash(photosIPFSHashes[i]);
            }
        }
        
        items[msg.sender][id] = Item(id, msg.sender, _price, _description, _title, photosIPFSHashes,ItemStatus.LISTED);
        emit ItemUpdated(id, msg.sender, _title, _description, _price, photosIPFSHashes);
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
        correctAmountSent(sellerAddress, id) {

        finalizeBuyItem(sellerAddress, id, _moderator); //had to move because stack was too deep
    }

    function finalizeBuyItem(address sellerAddress, uint256 id, address _moderator) private {
        try escrowContract.createTransaction{value: msg.value}(id, sellerAddress, msg.sender,_moderator,items[sellerAddress][id].price) {
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