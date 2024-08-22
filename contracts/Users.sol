// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

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

    function createProfile(string memory _username, string memory _firstName, string memory _lastName, string memory _country,
    string memory _description, string memory _email, string memory _avatarHash, bool _isModerator) external {
        require(!userProfiles[msg.sender].exists, "Profile already exists");

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

    function updateProfile(string memory _username, string memory _firstName, string memory _lastName, string memory _country,
    string memory _description, string memory _email, string memory _avatarHash, bool _isModerator) external {
        require(userProfiles[msg.sender].exists, "Profile does not exist");

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

    function deleteProfile() external {
        require(userProfiles[msg.sender].exists, "Profile does not exist");

        delete userProfiles[msg.sender];
    }

    function isRegisteredUser(address _user) external view returns (bool) {
        return userProfiles[_user].exists;
    }

    function getProfile(address _user) external view returns (UserProfile memory) {
        return userProfiles[_user];
    }
}
