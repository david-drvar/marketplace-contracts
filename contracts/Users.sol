// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

error UserAlreadyExists(address userAddress);
error UserDoesNotExist(address userAddress);
error UsernameExists(string username);
error NotIPFSHash(string hashString);


contract Users is Ownable{

    constructor(address initialOwner) Ownable(initialOwner) {}

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
        uint256 moderatorFee;
    }

    mapping(address => UserProfile) public userProfiles;

    mapping(string => bool) private usernameExists;


    event UserRegistered(address indexed userAddress, string indexed username, string firstName,
        string lastName, string country, string description, string email, string avatarHash, bool isModerator, uint8 moderatorFee);
    event UserUpdated(address indexed userAddress, string indexed username, string firstName,
        string lastName, string country, string description, string email, string avatarHash, bool isModerator, uint8 moderatorFee);
    event UserDeleted(address indexed userAddress, string indexed username);


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

    function createProfile(string memory _username, string memory _firstName, string memory _lastName, string memory _country,
        string memory _description, string memory _email, string memory _avatarHash, bool _isModerator, uint8 _moderatorFee) 
        userMustNotExist(msg.sender) usernameMustNotExist(_username) external {

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
}
