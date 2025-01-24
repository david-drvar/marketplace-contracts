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


interface IMarketplace {

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

    event ItemListed(
        uint256 indexed id,
        address indexed seller,
        string title,
        string description,
        uint256 price,
        string currency,
        string[] photosIPFSHashes,
        Condition condition,
        string category,
        string subcategory,
        string country,
        bool isGift
    );

    event ItemUpdated(
        uint256 indexed id,
        address indexed seller,
        string title,
        string description,
        uint256 price,
        string currency,
        string[] photosIPFSHashes,
        Condition condition,
        string category,
        string subcategory,
        string country,
        bool isGift
    );

    event ItemBought(uint256 indexed id, address indexed seller, address indexed buyer);
    event ItemDeleted(uint256 indexed id, address indexed seller);

    function setUsersContractAddress(address _usersContractAddress) external;

    function setEscrowContractAddress(address _escrowContractAddress) external;

    function addSupportedToken(string memory tokenName, address tokenAddress) external;

    function listNewItem(Item memory item) external;

    function updateItem(Item memory item) external;

    function deleteItem(uint256 id) external;

    function buyItem(address sellerAddress, uint256 id, address _moderator) external payable;
}


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


contract Escrow is Initializable, OwnableUpgradeable {

    struct Moderator {
        address moderator;
        uint256 fee;
    }

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

    IMarketplace public marketplaceContract;
    IUsers public usersContract;

    mapping(uint256 => Transaction) private transactions; // item id to transaction mapping -> 1:1 itemId Transaction
    mapping(string => address) public supportedTokens;

    event TransactionCreated(uint256 indexed itemId, address indexed buyer, address indexed seller, 
        address moderator, uint256 price, string currency, uint8 moderatorFee, uint256 creationTime);
    event TransactionCreatedWithoutModerator(uint256 indexed itemId, address indexed buyer, address indexed seller, 
        uint256 price, string currency, uint256 creationTime);
    event TransactionApproved(uint256 indexed itemId, address approver);
    event TransactionCompleted(uint256 indexed itemId);
    event TransactionCompletedByModerator(uint256 indexed itemId, uint8 buyerPercentage, uint8 sellerPercentage);
    event TransactionDisputed(uint256 indexed itemId, address disputer);

    modifier txExists(uint256 id) {
        Transaction memory item = transactions[id];
        if (item.price > 0) {
            revert TxExists(id);
        }
        _;
    }

    modifier onlyMarketplaceCanCall() {
        if (msg.sender != address(marketplaceContract)) {
            revert OnlyMarketplaceContractCanCall();
        }
        _;
    }

    modifier onlyUsersCanCall() {
        if (msg.sender != address(usersContract)) {
            revert OnlyUsersContractCanCall();
        }
        _;
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner); // Initialize OwnableUpgradeable
        transferOwnership(initialOwner); // Set the owner explicitly

        // Initialize supported tokens
        supportedTokens["POL"] = address(this);
    }

    function addSupportedToken(string memory tokenName, address tokenAddress) external onlyOwner {
        supportedTokens[tokenName] = tokenAddress;
    }

    function setMarketplaceContractAddress(address _marketplaceContractAddress) external onlyOwner {
        marketplaceContract = IMarketplace(_marketplaceContractAddress);
    }

    function setUsersContractAddress(address _usersContractAddress) external onlyOwner {
        usersContract = IUsers(_usersContractAddress);
    }

    modifier onlyModerator(uint256 itemId) {
        if (msg.sender != transactions[itemId].moderator) {
            revert OnlyModerator();
        }
        _;
    }

    modifier onlySeller(uint256 itemId) {
        if (msg.sender != transactions[itemId].seller) {
            revert OnlySeller();
        }
        _;
    }

    modifier onlyBuyer(uint256 itemId) {
        if (msg.sender != transactions[itemId].buyer) {
            revert OnlyBuyer();
        }
        _;
    }

    modifier onlyBuyerOrSeller(uint256 itemId) {
        if (msg.sender != transactions[itemId].seller && msg.sender != transactions[itemId].buyer) {
            revert OnlyBuyerOrSeller();
        }
        _;
    }

    modifier notCompleted(uint256 itemId) {
        if (transactions[itemId].isCompleted) {
            revert TxCantBeCompleted();
        }
        _;
    }

    modifier correctValueDistribution(uint256 itemId, uint8 percentageSeller, uint8 percentageBuyer) {
        if (percentageSeller + percentageBuyer != 100) {
            revert ValueDistributionNotCorrect();
        }
        _;
    }

    modifier mustBeDisputed(uint256 itemId) {
        if (!transactions[itemId].disputed) {
            revert MustBeDisputed();
        }
        _;
    }

    function createTransaction(
        uint256 _itemId,
        address _seller,
        address _buyer,
        address _moderator,
        uint256 _price,
        string memory _currency,
        uint8 _moderatorFee
    ) txExists(_itemId) onlyMarketplaceCanCall() external payable {

        transactions[_itemId] = Transaction({
            itemId: _itemId,
            seller: _seller,
            buyer: _buyer,
            moderator: _moderator,
            price: _price,
            currency: _currency,
            moderatorFee: _moderatorFee,
            buyerApproved: false,
            sellerApproved: false,
            disputed: false,
            disputedBySeller: false,
            disputedByBuyer: false,
            isCompleted: false,
            creationTime: block.timestamp
        });

        emit TransactionCreated(_itemId, _buyer, _seller, _moderator, _price, _currency, _moderatorFee, block.timestamp);
    }

    function createTransactionWithoutModerator(
        uint256 _itemId,
        address _seller,
        address _buyer,
        uint256 _price,
        string memory _currency
    ) txExists(_itemId) onlyMarketplaceCanCall() external payable {

        transactions[_itemId] = Transaction({
            itemId: _itemId,
            seller: _seller,
            buyer: _buyer,
            moderator: address(0),
            price: _price,
            currency: _currency,
            moderatorFee: 0,
            buyerApproved: true,
            sellerApproved: true,
            disputed: false,
            disputedBySeller: false,
            disputedByBuyer: false,
            isCompleted: true,
            creationTime: block.timestamp
        });
        emit TransactionCreatedWithoutModerator(_itemId, _buyer, _seller, _price, _currency, block.timestamp);

        finalizeTransactionWithoutModerator(_itemId);
    }

    function approve(uint256 _itemId) external 
        onlyBuyerOrSeller(_itemId) 
        notCompleted(_itemId) {

        Transaction storage transaction = transactions[_itemId];

        if (msg.sender == transaction.seller) 
            transaction.sellerApproved = true;
        else 
            transaction.buyerApproved = true;

        emit TransactionApproved(_itemId, msg.sender);

        finalizeTransaction(_itemId);
    }

    function raiseDispute(uint256 _itemId) external 
        onlyBuyerOrSeller(_itemId) 
        notCompleted(_itemId) {

        Transaction storage transaction = transactions[_itemId];
        transaction.disputed = true;
        if (msg.sender == transaction.seller) 
            transaction.disputedBySeller = true;
        else 
            transaction.disputedByBuyer = true;

        emit TransactionDisputed(_itemId, msg.sender);
    }

    function finalizeTransaction(uint256 _itemId) internal {
        Transaction storage transaction = transactions[_itemId];

        require(!transaction.isCompleted, "Transaction already completed");

        if (transaction.buyerApproved && transaction.sellerApproved) {
            transaction.isCompleted = true;

            uint256 moderatorFeeAmount = (transaction.price * transaction.moderatorFee) / 100;
            uint256 sellerAmount = transaction.price;

            if (keccak256(abi.encodePacked(transaction.currency)) == keccak256(abi.encodePacked("POL"))) {
                // Transfer to moderator their cut
                (bool successModerator, ) = transaction.moderator.call{value: moderatorFeeAmount}(""); 
                require(successModerator, "Transfer to moderator failed");

                // Transfer remaining amount to seller
                (bool successSeller, ) = transaction.seller.call{value: sellerAmount}(""); 
                require(successSeller, "Transfer to seller failed");
            }
            else {
                address tokenAddress = supportedTokens[transaction.currency];

                IERC20 token = IERC20(tokenAddress);

                bool successModerator = token.transfer(transaction.moderator, moderatorFeeAmount);
                require(successModerator, "Token transfer to moderator failed");

                bool successSeller = token.transfer(transaction.seller, sellerAmount);
                require(successSeller, "Token transfer to seller failed");
            }
            
            emit TransactionCompleted(_itemId);
        }
    }

    function finalizeTransactionWithoutModerator(uint256 _itemId) internal 
    {
        Transaction storage transaction = transactions[_itemId];

        // Transfer remaining amount to seller
        if (keccak256(abi.encodePacked(transaction.currency)) == keccak256(abi.encodePacked("POL"))) {
            (bool successSeller, ) = transaction.seller.call{value: transaction.price}(""); 
            require(successSeller, "Transfer to seller failed");
        } else {
            address tokenAddress = supportedTokens[transaction.currency];

            IERC20 token = IERC20(tokenAddress);

            bool successSeller = token.transferFrom(transaction.buyer, transaction.seller, transaction.price);
            require(successSeller, "Token transfer to seller failed");
        }

        emit TransactionCompleted(_itemId);
    }


    function finalizeTransactionByModerator(uint256 _itemId, uint8 percentageSeller, uint8 percentageBuyer) external payable 
        onlyModerator(_itemId)
        notCompleted(_itemId) 
        correctValueDistribution(_itemId, percentageBuyer, percentageSeller) 
        mustBeDisputed(_itemId) {

        finalizePaymentsByModerator(_itemId, percentageSeller, percentageBuyer);
    }

    function finalizePaymentsByModerator(uint256 _itemId, uint8 percentageSeller, uint8 percentageBuyer) internal {
        Transaction storage transaction = transactions[_itemId];

        transaction.isCompleted = true;

        uint256 moderatorFeeAmount = (transaction.price * transaction.moderatorFee) / 100;

        // full item price is distributed between seller and buyer
        uint256 sellerAmount = (transaction.price * percentageSeller) / 100;
        uint256 buyerAmount = (transaction.price * percentageBuyer) / 100;

        if (keccak256(abi.encodePacked(transaction.currency)) == keccak256(abi.encodePacked("POL"))) {
            (bool successModerator, ) = transaction.moderator.call{value: moderatorFeeAmount}(""); 
            require(successModerator, "Transfer to moderator failed");

            (bool successSeller, ) = transaction.seller.call{value: sellerAmount}("");
            require(successSeller, "Transfer to seller failed");

            (bool successBuyer, ) = transaction.buyer.call{value: buyerAmount}("");
            require(successBuyer, "Transfer to buyer failed");
        } else {
            address tokenAddress = supportedTokens[transaction.currency];

            IERC20 token = IERC20(tokenAddress);

            bool successModerator = token.transfer(transaction.moderator, moderatorFeeAmount);
            require(successModerator, "Token transfer to moderator failed");

            bool successSeller = token.transfer(transaction.seller, sellerAmount);
            require(successSeller, "Token transfer to seller failed");

            bool successBuyer = token.transfer(transaction.buyer, buyerAmount);
            require(successBuyer, "Token transfer to buyer failed");
        }

        emit TransactionCompletedByModerator(_itemId, percentageBuyer, percentageSeller);
    }

    function isTransactionReadyForReview(uint256 _itemId, address from, address to) external view onlyUsersCanCall() returns (bool) {
        Transaction storage transaction = transactions[_itemId];

        if ((from == transaction.seller || from == transaction.buyer || from == transaction.moderator) && 
            (to == transaction.seller || to == transaction.buyer || to == transaction.moderator) && (from != to) &&
            transaction.isCompleted)
            return true;

        return false;
    }


}