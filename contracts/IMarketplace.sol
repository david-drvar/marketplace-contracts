// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

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

    event ItemListed(uint256 indexed id, address indexed seller, string title, string description, uint256 price, string[] photosIPFSHashes);
    event ItemUpdated(uint256 indexed id, address indexed seller, string title, string description, uint256 price, string[] photosIPFSHashes);
    event ItemBought(uint256 indexed id, address indexed seller, address indexed buyer);
    event ItemDeleted(uint256 indexed id, address indexed seller);

    function setUsersContractAddress(address _usersContractAddress) external;

    function setEscrowContractAddress(address _escrowContractAddress) external;

    function listNewItem(
        string memory _title, 
        string memory _description, 
        uint256 _price, 
        string[] memory photosIPFSHashes, 
        Condition _condition,
        string memory _category,
        string memory _subcategory,
        string memory _country,
        bool _isGift
    ) external;

    function updateItem(
        uint256 id, 
        string memory _title, 
        string memory _description, 
        uint256 _price, 
        string[] memory photosIPFSHashes,
        Condition _condition,
        string memory _category,
        string memory _subcategory,
        string memory _country,
        bool _isGift
    ) external;

    function deleteItem(uint256 id) external;

    function buyItem(address sellerAddress, uint256 id, address _moderator) external payable;

    function buyItemWithoutModerator(address sellerAddress, uint256 id) external payable;

    function getItemCount() external view returns (uint256);
}
