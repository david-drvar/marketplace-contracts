// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

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
