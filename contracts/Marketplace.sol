// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

error PriceMustBeAboveZero();
error ItemNotListed(address sellerAddress, uint256 id);
error ItemNotBelongsToSeller(address sellerAddress, uint256 id);
error SellerCannotBuyItsItem(address sellerAddress);
error SentValueNotEnough(address sellerAddress, uint256 id, uint256 value);
error PhotoLimitExceeded(address sellerAddress, string title);
error NotIPFSHash(string hash);


contract Marketplace {
    struct Item {
        uint256 id;
        address seller;
        uint256 price;
        string description;
        string title;
        string[] photosIPFSHashes;
    }

    uint8 constant public MAX_PHOTO_LIMIT = 3;

    uint256 itemCount;
    mapping(address => mapping(uint256 => Item)) private items; //mapping seller address to mapping of id to Item

    event ItemListed(uint256 indexed id, address indexed seller, string title, string description, uint256 price, string[] photosIPFSHashes);
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

    function listNewItem(string memory _title, string memory _description, uint256 _price, string[] memory photosIPFSHashes) external {
        if (_price <= 0) {
            revert PriceMustBeAboveZero();
        }
        if (photosIPFSHashes.length > MAX_PHOTO_LIMIT) {
            revert PhotoLimitExceeded(msg.sender, _title);
        }
        for (uint i = 0; i < photosIPFSHashes.length; i++) {
            if (!isIPFSHash(photosIPFSHashes[i])) {
                revert NotIPFSHash(photosIPFSHashes[i]);
            }
        }
        
        itemCount++;
        uint256 id = createHash(itemCount, msg.sender);
        items[msg.sender][id] = Item(id, msg.sender, _price, _description, _title, photosIPFSHashes);
        emit ItemListed(id, msg.sender, _title, _description, _price, photosIPFSHashes);
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

    function createHash(uint256 id, address addr) internal pure returns (uint256) {
        bytes32 hashInput = keccak256(abi.encodePacked(id, addr));
        uint256 idHash = uint256(hashInput); // Convert the concatenated bytes32 hash to uint256
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

    function getItemCount() public view returns (uint256) {
        return itemCount;
    }
}