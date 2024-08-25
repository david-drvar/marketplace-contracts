// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IMarketplace {

    struct Item {
        uint256 id;
        address seller;
        uint256 price;
        string description;
        string title;
        string[] photosIPFSHashes;
    }

    function MAX_PHOTO_LIMIT() external pure returns (uint8);

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



error TxExists(uint256 id);
error OnlyMarketplaceContractCallCall();


contract Escrow is Ownable {

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

    IMarketplace public marketplaceContract;

    mapping(uint256 => Transaction) private transactions;

    event TransactionCreated(uint256 itemId, address buyer, address seller, uint256 price);
    event TransactionApproved(uint256 itemId, address approver);
    event TransactionCompleted(uint256 itemId);
    event TransactionDisputed(uint256 itemId);

    modifier txExists(uint256 id) {
        Transaction memory item = transactions[id];
        if (item.price > 0) {
            revert TxExists(id);
        }
        _;
    }

    modifier onlyMarketplaceCanCall() {
        if (msg.sender != address(marketplaceContract)) {
            revert OnlyMarketplaceContractCallCall();
        }
        _;
    }

    /**
     * Proces - seller, buyer, moderator
     * 
     * 1.
     * buyer kupi i funduje tx
     * seller shippuje item time ga approvovajuci
     * buyer dobija proizvod i approvuje
     * funds se salje na adresu sellera bez potrebe moderatora
     * 
     * 2.
     * buyer kupi i funduje tx
     * seller shippuje item tima ga approvovajuci
     * buyer dobija proizvod (ili ne dobija) i fajluje dispute
     * moderator se ukljucuje i trazi dokaze
     * nema veze vise tu ko je acceptovao (seller ili buyer) ili ne
     * moderator sam odlucuje sta ce da radi i kako ce da razdeli novac (kome i koliko procenata)
     * 
     * 3.
     * buyer dobija proizvoda i approvuje
     * seller medjutim nije approvovao (zaboravio)
     * moderator se ukljucuje
     * seller se i dalje ne javlja, i moderator odlucuje sta ce da radi
     * 
     * 4.
     * 
     * 
     */

    constructor(address initialOwner) Ownable(initialOwner) {}

    function setMarketplaceContractAddress(address _marketplaceContractAddress) external onlyOwner {
        marketplaceContract = IMarketplace(_marketplaceContractAddress);
    }

    function createTransaction(
        uint256 _itemId,
        address _seller,
        address _buyer,
        address _moderator,
        uint256 _price
    ) txExists(_itemId) onlyMarketplaceCanCall() external payable {

        transactions[_itemId] = Transaction({
            itemId: _itemId,
            seller: _seller,
            buyer: _buyer,
            moderator: _moderator,
            price: _price,
            transactionStatus: TransactionStatus.FUNDED,
            buyerApproved: false,
            sellerApproved: false,
            moderatorApproved: false,
            disputed: false,
            isCompleted: false,
            creationTime: block.timestamp
        });

        emit TransactionCreated(_itemId, _buyer, _seller, _price);
    }

    function approveByBuyer(uint256 _itemId) external {
        Transaction storage transaction = transactions[_itemId];
        require(msg.sender == transaction.buyer, "Only buyer can approve");
        require(!transaction.isCompleted, "Transaction is already completed");

        transaction.buyerApproved = true;
        emit TransactionApproved(_itemId, msg.sender);

        finalizeTransaction(_itemId);
    }

    function approveBySeller(uint256 _itemId) external {
        Transaction storage transaction = transactions[_itemId];
        require(msg.sender == transaction.seller, "Only seller can approve");
        require(!transaction.isCompleted, "Transaction is already completed");

        transaction.sellerApproved = true;
        emit TransactionApproved(_itemId, msg.sender);

        finalizeTransaction(_itemId);
    }

    function approveByModerator(uint256 _itemId) external {
        Transaction storage transaction = transactions[_itemId];
        require(msg.sender == transaction.moderator, "Only moderator can approve");
        require(!transaction.isCompleted, "Transaction is already completed");

        transaction.moderatorApproved = true;
        emit TransactionApproved(_itemId, msg.sender);

        finalizeTransaction(_itemId);
    }

    function raiseDispute(uint256 _itemId) external {
        Transaction storage transaction = transactions[_itemId];
        require(msg.sender == transaction.buyer || msg.sender == transaction.seller, "Only buyer or seller can raise a dispute");
        require(!transaction.isCompleted, "Transaction is already completed");

        transaction.disputed = true;
        emit TransactionDisputed(_itemId);
    }

    function finalizeTransaction(uint256 _itemId) internal {
        Transaction storage transaction = transactions[_itemId];

        if (transaction.buyerApproved && transaction.sellerApproved && (transaction.moderatorApproved || !transaction.disputed)) {
            transaction.isCompleted = true;

            // Transfer funds to the seller
            (bool success, ) = transaction.seller.call{value: transaction.price}(""); 
            //todo change - not always the seller gets the money
            //also moderator gets their fee

            //tell marketplaace to finish with the product
            
            require(success, "Transfer to seller failed");

            emit TransactionCompleted(_itemId);
        }
    }

}