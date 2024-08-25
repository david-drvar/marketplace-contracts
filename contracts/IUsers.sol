// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IUsers {

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

    // Events
    event UserRegistered(
        address indexed userAddress, 
        string indexed username, 
        string firstName,
        string lastName, 
        string country, 
        string description, 
        string email, 
        string avatarHash, 
        bool isModerator, 
        uint8 moderatorFee
    );
    
    event UserUpdated(
        address indexed userAddress, 
        string indexed username, 
        string firstName,
        string lastName, 
        string country, 
        string description, 
        string email, 
        string avatarHash, 
        bool isModerator, 
        uint8 moderatorFee
    );
    
    event UserDeleted(address indexed userAddress, string indexed username);

    // Functions
    function createProfile(
        string memory _username,
        string memory _firstName,
        string memory _lastName,
        string memory _country,
        string memory _description,
        string memory _email,
        string memory _avatarHash,
        bool _isModerator,
        uint8 _moderatorFee
    ) external;

    function updateProfile(
        string memory _username,
        string memory _firstName,
        string memory _lastName,
        string memory _country,
        string memory _description,
        string memory _email,
        string memory _avatarHash,
        bool _isModerator,
        uint8 _moderatorFee
    ) external;

    function deleteProfile() external;

    function isRegisteredUser(address _user) external view returns (bool);

    function isModerator(address _user) external view returns (bool);

    function getProfile(address _user) external view returns (UserProfile memory);
}
