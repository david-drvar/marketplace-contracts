// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

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
