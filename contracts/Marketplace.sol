// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

error PriceMustBeAboveZero();
error ItemNotListed(address sellerAddress, uint256 id);
error ItemNotBelongsToSeller(address sellerAddress, uint256 id);
error SellerCannotBuyItsItem(address sellerAddress);
error SentValueNotEnough(address sellerAddress, uint256 id, uint256 value);


contract Marketplace {
    struct Item {
        uint256 id;
        address seller;
        uint256 price;
        string description;
        string title;
        uint256 datePosted;
        // string[] photos;
    }

    uint256 itemCount;
    mapping(address => mapping(uint256 => Item)) private items; //mapping seller address to mapping of id to Item

    event ItemListed(uint256 indexed id, address indexed seller, string title, string description, uint256 price);
    event ItemBought(uint256 indexed id, address indexed seller, address indexed buyer);
    event ItemDeleted(uint256 indexed id, address indexed seller);


    modifier isListed(address sellerAddress, uint256 id) {
        Item memory listing = items[sellerAddress][id];
        if (listing.price <= 0) {
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

    function listNewItem(string memory _title, string memory _description, uint256 _price, uint256 _date) external {
        if (_price <= 0) {
            revert PriceMustBeAboveZero();
        }
        itemCount++;
        uint256 id = createHash(itemCount, msg.sender);
        items[msg.sender][id] = Item(id, msg.sender, _price, _description, _title, _date);
        emit ItemListed(id, msg.sender, _title, _description, _price);
    }

    function createHash(uint256 id, address addr) internal pure returns (uint256) {
        // Concatenate the uint256 ID and the address
        bytes32 hashInput = keccak256(abi.encodePacked(id, addr));

        // Convert the concatenated bytes32 hash to uint256
        uint256 idHash = uint256(hashInput);
    
        return idHash;
    }

    function deleteItem(uint256 id) isListed(msg.sender, id) belongsToSeller(msg.sender, id) external {
        delete (items[msg.sender][id]);
        emit ItemDeleted(id, msg.sender);
    }

    function buyItem(address sellerAddress, uint256 id) external payable isListed(sellerAddress, id) 
        belongsToSeller(sellerAddress, id) notSeller(sellerAddress, msg.sender) {
        Item memory listedItem = items[sellerAddress][id];
        if (msg.value < listedItem.price) {
            revert SentValueNotEnough(sellerAddress, id, msg.value);
        }
        delete (items[sellerAddress][id]);
        (bool success, ) = payable(sellerAddress).call{value: msg.value}("");
        require(success, "Transfer to seller failed");
        emit ItemBought(id, sellerAddress, msg.sender);
    }
}