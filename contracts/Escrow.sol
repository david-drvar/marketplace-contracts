// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";


interface IMarketplace {
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

    event ItemListed(uint256 indexed id, address indexed seller, string title, string description, uint256 price, string[] photosIPFSHashes);
    event ItemUpdated(uint256 indexed id, address indexed seller, string title, string description, uint256 price, string[] photosIPFSHashes);
    event ItemBought(uint256 indexed id, address indexed seller, address indexed buyer);
    event ItemDeleted(uint256 indexed id, address indexed seller);

    function setUsersContractAddress(address _usersContractAddress) external;
    function setEscrowContractAddress(address _escrowContractAddress) external;
    function listNewItem(string memory _title, string memory _description, uint256 _price, string[] memory photosIPFSHashes) external;
    function updateItem(uint256 id, string memory _title, string memory _description, uint256 _price, string[] memory photosIPFSHashes) external;
    function deleteItem(uint256 id) external;
    function buyItem(address sellerAddress, uint256 id, address _moderator) external payable;
    function getItemCount() external view returns (uint256);
}


error OnlyModerator();
error OnlySeller();
error OnlyBuyer();
error OnlyBuyerOrSeller();
error TxCantBeCompleted();
error ValueDistributionNotCorrect();
error TxExists(uint256 id);
error OnlyMarketplaceContractCanCall();
error MustBeDisputed();


contract Escrow is Ownable {

    struct Moderator {
        address moderator;
        uint256 fee;
    }

    // enum TransactionStatus {   //DO I NEED THIS??
    //     FUNDED,
    //     SHIPPED,
    //     RECEIVED
    // }

    struct Transaction {
        uint256 itemId;
        address seller;
        address moderator;
        address buyer;
        uint256 price;
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

    mapping(uint256 => Transaction) private transactions; // item id to transaction mapping -> 1:1 itemId Transaction

    event TransactionCreated(uint256 indexed itemId, address indexed buyer, address indexed seller, 
        address moderator, uint256 price, uint8 moderatorFee, uint256 creationTime);
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

    constructor(address initialOwner) Ownable(initialOwner) {}

    function setMarketplaceContractAddress(address _marketplaceContractAddress) external onlyOwner {
        marketplaceContract = IMarketplace(_marketplaceContractAddress);
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
        if (transactions[itemId].moderatorFee + percentageSeller + percentageBuyer != 100) {
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
        uint8 _moderatorFee
    ) txExists(_itemId) onlyMarketplaceCanCall() external payable {

        transactions[_itemId] = Transaction({
            itemId: _itemId,
            seller: _seller,
            buyer: _buyer,
            moderator: _moderator,
            price: _price,
            moderatorFee: _moderatorFee,
            buyerApproved: false,
            sellerApproved: false,
            disputed: false,
            disputedBySeller: false,
            disputedByBuyer: false,
            isCompleted: false,
            creationTime: block.timestamp
        });

        emit TransactionCreated(_itemId, _buyer, _seller, _moderator, _price, _moderatorFee, block.timestamp);
    }

    function approveByBuyer(uint256 _itemId) external 
        onlyBuyer(_itemId) 
        notCompleted(_itemId) {

        Transaction storage transaction = transactions[_itemId];
        transaction.buyerApproved = true;
        emit TransactionApproved(_itemId, msg.sender);

        finalizeTransaction(_itemId);
    }

    function approveBySeller(uint256 _itemId) external 
        onlySeller(_itemId) 
        notCompleted(_itemId) {

        Transaction storage transaction = transactions[_itemId];
        transaction.sellerApproved = true;
        emit TransactionApproved(_itemId, msg.sender);

        finalizeTransaction(_itemId);
    }

    function raiseDispute(uint256 _itemId, address disputer) external 
        onlyBuyerOrSeller(_itemId) 
        notCompleted(_itemId) {

        Transaction storage transaction = transactions[_itemId];
        transaction.disputed = true;
        if (msg.sender == transaction.seller) 
            transaction.disputedBySeller = true;
        else 
            transaction.disputedByBuyer = true;

        emit TransactionDisputed(_itemId, disputer);
    }

    function finalizeTransaction(uint256 _itemId) internal {
        Transaction storage transaction = transactions[_itemId];

        if (transaction.buyerApproved && transaction.sellerApproved) {
            transaction.isCompleted = true;

            uint256 moderatorFeeAmount = (transaction.price * transaction.moderatorFee) / 100;
            uint256 sellerAmount = transaction.price - moderatorFeeAmount;

            // Transfer to moderator their cut
            (bool successModerator, ) = transaction.moderator.call{value: moderatorFeeAmount}(""); 
            require(successModerator, "Transfer to moderator failed");

            // Transfer remaining amount to seller
            (bool successSeller, ) = transaction.seller.call{value: sellerAmount}(""); 
            require(successSeller, "Transfer to seller failed");


            //should I inform marketplace to finish with the product ???
            
            emit TransactionCompleted(_itemId);
        }
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
        uint256 remainingAmount = transaction.price - moderatorFeeAmount;
        uint256 sellerAmount = (remainingAmount * percentageSeller) / 100;
        uint256 buyerAmount = (remainingAmount * percentageBuyer) / 100;

        (bool successModerator, ) = transaction.moderator.call{value: moderatorFeeAmount}(""); 
        require(successModerator, "Transfer to moderator failed");

        (bool successSeller, ) = transaction.seller.call{value: sellerAmount}("");
        require(successSeller, "Transfer to seller failed");

        (bool successBuyer, ) = transaction.buyer.call{value: buyerAmount}("");
        require(successBuyer, "Transfer to buyer failed");

        emit TransactionCompletedByModerator(_itemId, percentageBuyer, percentageSeller);
    }

}