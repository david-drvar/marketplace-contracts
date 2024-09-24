// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";



interface IEscrow {

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

    event TransactionCreated(uint256 indexed itemId, address indexed buyer, address indexed seller, 
        address moderator, uint256 price, uint8 moderatorFee, uint256 creationTime);
    event TransactionCreatedWithoutModerator(uint256 indexed itemId, address indexed buyer, address indexed seller, 
        uint256 price, uint256 creationTime);
    event TransactionApproved(uint256 indexed itemId, address approver);
    event TransactionCompleted(uint256 indexed itemId);
    event TransactionCompletedByModerator(uint256 indexed itemId, uint8 buyerPercentage, uint8 sellerPercentage);
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

    function createTransactionWithoutModerator(
        uint256 _itemId,
        address _seller,
        address _buyer,
        uint256 _price
    ) external payable;

    function approve(uint256 _itemId) external;

    function raiseDispute(uint256 _itemId) external;

    function finalizeTransactionByModerator(uint256 _itemId, uint8 percentageSeller, uint8 percentageBuyer) external payable;

    function isTransactionReadyForReview(
        uint256 _itemId,
        address from,
        address to
    ) external view returns (bool);
}



error UserAlreadyExists(address userAddress);
error UserDoesNotExist(address userAddress);
error UsernameExists(string username);
error NotIPFSHash(string hashString);
error ModeratorFeeLimitsNotRespected(uint8 moderatorFee);
error AlreadyReviewed();


contract Users is Ownable{

    constructor(address initialOwner) Ownable(initialOwner) {}

    struct Review {
        string content;
        uint8 rating; //1-5
        uint256 itemId;
        address from;
    }

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

    mapping(address => UserProfile) public userProfiles;
    mapping(address => Review[]) public reviews;

    mapping(string => bool) private usernameExists;

    IEscrow public escrowContract;


    uint8 constant public MAX_MODERATOR_FEE = 20;

    event UserRegistered(address indexed userAddress, string username, string firstName,
        string lastName, string country, string description, string email, string avatarHash, bool isModerator, uint8 moderatorFee);
    event UserUpdated(address indexed userAddress, string username, string firstName,
        string lastName, string country, string description, string email, string avatarHash, bool isModerator, uint8 moderatorFee);
    event UserDeleted(address indexed userAddress, string username);
    event ReviewCreated(address indexed from, address indexed to, string content, uint8 rating, uint256 itemId);


    modifier userMustExist(address userAddress) {
        if (!userProfiles[userAddress].exists) {
            revert UserDoesNotExist(userAddress);
        }
        _;
    }

    modifier userMustNotExist(address userAddress) {
        if (userProfiles[userAddress].exists) {
            revert UserAlreadyExists(userAddress);
        }
        _;
    }

    modifier usernameMustNotExist(string memory username) {
        if (usernameExists[username]) {
            revert UsernameExists(username);
        }
        _;
    }

    function setEscrowContractAddress(address _escrowContractAddress) external 
        onlyOwner {
        escrowContract = IEscrow(_escrowContractAddress);
    }

    function createProfile(string memory _username, string memory _firstName, string memory _lastName, string memory _country,
        string memory _description, string memory _email, string memory _avatarHash, bool _isModerator, uint8 _moderatorFee) 
        userMustNotExist(msg.sender) usernameMustNotExist(_username) external {

        uint8 fee;
        if (!_isModerator) {
            fee = 0;
        }
        else {
            if (_moderatorFee < 0 || _moderatorFee > MAX_MODERATOR_FEE)
                revert ModeratorFeeLimitsNotRespected(_moderatorFee);
                
            fee = _moderatorFee;
        }

        userProfiles[msg.sender] = UserProfile({
            userAddress: msg.sender,
            username: _username,
            firstName: _firstName,
            lastName: _lastName,
            country: _country,
            description: _description,
            email: _email,
            avatarHash: _avatarHash,
            isModerator: _isModerator,
            exists: true,
            moderatorFee: fee
        });
        usernameExists[_username] = true;

        emit UserRegistered(msg.sender, _username, _firstName, _lastName, _country, _description, _email, _avatarHash, _isModerator, fee);
    }

    function updateProfile(string memory _username, string memory _firstName, string memory _lastName, string memory _country,
        string memory _description, string memory _email, string memory _avatarHash, bool _isModerator, uint8 _moderatorFee) 
        userMustExist(msg.sender) external {

        UserProfile memory oldUser = userProfiles[msg.sender];
        if (!compareStrings(oldUser.username, _username)) { //username is updated
            if (usernameExists[_username]) 
                revert UsernameExists(_username);

            delete usernameExists[oldUser.username];
            usernameExists[_username] = true;
        }

        uint8 fee;
        if (!_isModerator) {
            fee = 0;
        }
        else {
            fee = _moderatorFee;
        }

        userProfiles[msg.sender] = UserProfile({
            userAddress: msg.sender,
            username: _username,
            firstName: _firstName,
            lastName: _lastName,
            country: _country,
            description: _description,
            email: _email,
            avatarHash: _avatarHash,
            isModerator: _isModerator,
            exists: true,
            moderatorFee: fee
        });

        emit UserUpdated(msg.sender, _username, _firstName, _lastName, _country, _description, _email, _avatarHash, _isModerator, fee);
    }

    function deleteProfile() userMustExist(msg.sender) external {
        require(userProfiles[msg.sender].exists, "Profile does not exist");

        UserProfile memory user = userProfiles[msg.sender];

        delete userProfiles[msg.sender];
        delete usernameExists[user.username];

        emit UserDeleted(msg.sender, user.username);
    }

    function isRegisteredUser(address _user) external view returns (bool) {
        return userProfiles[_user].exists;
    }

    function isModerator(address _user) external view returns (bool) {
        return userProfiles[_user].exists && userProfiles[_user].isModerator;
    }

    function getProfile(address _user) external view returns (UserProfile memory) {
        return userProfiles[_user];
    }


    function compareStrings(string memory _a, string memory _b) private pure returns(bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    function isAlreadyReviewed(Review[] storage userReviews, uint256 itemId) internal view returns (bool) {
        for (uint256 i = 0; i < userReviews.length; i++) {
            if (userReviews[i].itemId == itemId && userReviews[i].from == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function createReview(address toWhom, uint256 itemId, uint8 rating, string memory content) external {
        if (userProfiles[msg.sender].exists && userProfiles[toWhom].exists && 
            escrowContract.isTransactionReadyForReview(itemId, msg.sender, toWhom)) {
            Review[] storage userReviews = reviews[toWhom];
            if (!isAlreadyReviewed(userReviews, itemId) && rating >= 1 && rating <= 5) {
                userReviews.push(Review(content, rating, itemId, msg.sender));
                emit ReviewCreated(msg.sender, toWhom, content, rating, itemId);
            }
            else
                revert AlreadyReviewed();
        }
    }
}
