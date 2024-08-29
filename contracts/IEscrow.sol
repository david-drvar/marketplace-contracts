// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMarketplace.sol";

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
        uint8 moderatorFee;
        TransactionStatus transactionStatus;
        bool buyerApproved;
        bool sellerApproved;
        bool disputed;
        address disputedBySeller;
        address disputedByBuyer;
        bool isCompleted;
        uint256 creationTime;
    }

    event TransactionCreated(uint256 indexed itemId, address indexed buyer, address indexed seller, address moderator, uint256 price, uint8 moderatorFee,
        TransactionStatus transactionStatus, bool buyerApproved, bool sellerApproved, bool moderatorApproved, bool disputed, address disputedBy,
        bool isCompleted, uint256 creationTime);

    event TransactionApproved(uint256 indexed itemId, address approver);
    event TransactionCompleted(uint256 indexed itemId);
    event TransactionDisputed(uint256 indexed itemId, address disputer);

    function setMarketplaceContractAddress(address _marketplaceContractAddress) external;

    function createTransaction(
        uint256 _itemId,
        address _seller,
        address _buyer,
        address _moderator,
        uint256 _price,
        uint8 _moderatorFee
    ) external payable;

    function approveByBuyer(uint256 _itemId) external;

    function approveBySeller(uint256 _itemId) external;

    function raiseDispute(uint256 _itemId, address disputer) external;

    function finalizeTransaction(uint256 _itemId) external;

    function finalizeTransactionByModerator(uint256 _itemId, uint8 percentageSeller, uint8 percentageBuyer) external payable;

    function transactions(uint256 _itemId) external view returns (
        address seller,
        address moderator,
        address buyer,
        uint256 price,
        uint8 moderatorFee,
        TransactionStatus transactionStatus,
        bool buyerApproved,
        bool sellerApproved,
        bool disputed,
        address disputedBySeller,
        address disputedByBuyer,
        bool isCompleted,
        uint256 creationTime
    );
}
