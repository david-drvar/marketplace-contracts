// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;


error UserAlreadyExists(address userAddress);
error UserDoesNotExist(address userAddress);
error UsernameExists(string username);
error NotIPFSHash(string hashString);


contract Users {

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
    }

    mapping(address => UserProfile) public userProfiles;

    mapping(string => bool) private usernameExists;


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
        string memory _description, string memory _email, string memory _avatarHash, bool _isModerator) 
        userMustNotExist(msg.sender) usernameMustNotExist(_username) external {

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
            exists: true
        });
        usernameExists[_username] = true;
    }

    function updateProfile(string memory _username, string memory _firstName, string memory _lastName, string memory _country,
        string memory _description, string memory _email, string memory _avatarHash, bool _isModerator) 
        userMustExist(msg.sender) external {

        UserProfile memory oldUser = userProfiles[msg.sender];
        if (!compareStrings(oldUser.username, _username)) { //username is updated
            if (usernameExists[_username]) 
                revert UsernameExists(_username);

            delete usernameExists[oldUser.username];
            usernameExists[_username] = true;
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
            exists: true
        });
    }

    function deleteProfile() userMustExist(msg.sender) external {
        require(userProfiles[msg.sender].exists, "Profile does not exist");

        UserProfile memory user = userProfiles[msg.sender];

        delete userProfiles[msg.sender];
        delete usernameExists[user.username];
    }

    function isRegisteredUser(address _user) external view returns (bool) {
        return userProfiles[_user].exists;
    }

    function getProfile(address _user) external view returns (UserProfile memory) {
        return userProfiles[_user];
    }


    function compareStrings(string memory _a, string memory _b) public pure returns(bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }
}
