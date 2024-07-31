// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract IDChain {
    // Data hash contains:
    // string name;
    // string birthPlace;
    // string birthDate;
    // string gender;
    // string bloodType;
    // string country;
    // string province;
    // string city;
    // string subdistrict;
    // string vilage;
    // string rtRw;
    // string religion;
    // string maritalStatus;
    // string occupation;
    // string nationality;
    // string validUntil;
    // string createdAt;
    // string updatedAt;

    struct KTP {
        uint256 id;
        string NIK;
        string dataHash;
        string photoHash;
        string signatureHash;
        bool verified;
    }

    struct KTPInput {
        string dataHash;
        string photoHash;
        string signatureHash;
    }

    struct ImportKTPInput {
        string NIK;
        string dataHash;
        string photoHash;
        string signatureHash;
    }

    mapping(address => KTP) public ktps;
    mapping(address => bool) public admins;
    address[] public unverifiedAddresses;

    event KTPCreated(address indexed user, KTP ktp);
    event KTPImported(address indexed user, KTP ktp);
    event KTPUpdated(address indexed user, KTP ktp);
    event KTPVerified(address indexed user, KTP ktp);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    constructor() {
        admins[msg.sender] = true;
    }

    // Modifier to restrict access to admin-only functions
    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admin can perform this action");
        _;
    }

    // Function to add a new admin
    function addAdmin(address newAdmin) public onlyAdmin {
        require(!admins[newAdmin], "Address is already an admin");
        admins[newAdmin] = true;
        emit AdminAdded(newAdmin);
    }

    // Function to remove an admin
    function removeAdmin(address admin) public onlyAdmin {
        require(admin != msg.sender, "Admin cannot remove themselves");
        require(admins[admin], "Address is not an admin");
        delete admins[admin];
        emit AdminRemoved(admin);
    }

    // Function to create a new KTP for a user who does not yet have a real KTP card
    function createKTP(KTPInput memory input) public {
        require(bytes(ktps[msg.sender].NIK).length == 0, "KTP already exists");

        ktps[msg.sender] = KTP({
            id: uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))),
            NIK: "",
            dataHash: input.dataHash,
            photoHash: input.photoHash,
            signatureHash: input.signatureHash,
            verified: false
        });

        unverifiedAddresses.push(msg.sender);

        emit KTPCreated(msg.sender, ktps[msg.sender]);
    }

    // Function to import an existing KTP for a user who already has a real KTP card
    function importKTP(ImportKTPInput memory input) public {
        require(bytes(ktps[msg.sender].NIK).length == 0, "KTP already exists");

        ktps[msg.sender] = KTP({
            id: uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))),
            NIK: input.NIK,
            dataHash: input.dataHash,
            photoHash: input.photoHash,
            signatureHash: input.signatureHash,
            verified: false
        });

        unverifiedAddresses.push(msg.sender);

        emit KTPImported(msg.sender, ktps[msg.sender]);
    }

    // Function to update an existing KTP for a user
    function updateKTP(KTPInput memory input) public {
        require(bytes(ktps[msg.sender].NIK).length != 0, "KTP does not exist");

        KTP storage ktp = ktps[msg.sender];
        ktp.dataHash = input.dataHash;
        ktp.photoHash = input.photoHash;
        ktp.signatureHash = input.signatureHash;
        ktp.verified = false;

        if (!contains(unverifiedAddresses, msg.sender)) {
            unverifiedAddresses.push(msg.sender);
        }

        emit KTPUpdated(msg.sender, ktps[msg.sender]);
    }

    // Function for the admin to verify a newly created KTP and assign a NIK
    function verifyNewKTP(address user, string memory NIK) public onlyAdmin {
        require(bytes(ktps[user].NIK).length == 0, "KTP already verified");

        KTP storage ktp = ktps[user];
        ktp.NIK = NIK;
        ktp.verified = true;

        removeUnverifiedAddress(user);

        emit KTPVerified(user, ktp);
    }

    // Function for the admin to verify an imported or updated KTP
    function verifyKTP(address user) public onlyAdmin {
        require(bytes(ktps[user].NIK).length != 0, "KTP does not exist");
        require(!ktps[user].verified, "KTP already verified");

        ktps[user].verified = true;

        removeUnverifiedAddress(user);

        emit KTPVerified(user, ktps[user]);
    }

    // Function to get the KTP data for a specific user
    function getKTP(address user) public view returns (KTP memory) {
        return ktps[user];
    }

    // Function for the admin to get a list of all addresses with unverified KTPs
    function getUnverifiedAddresses() public view onlyAdmin returns (address[] memory) {
        return unverifiedAddresses;
    }

    // Internal function to check if an address is in the unverified addresses list
    function contains(address[] storage array, address value) internal view returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    // Internal function to remove an address from the unverified addresses list
    function removeUnverifiedAddress(address user) internal {
        for (uint i = 0; i < unverifiedAddresses.length; i++) {
            if (unverifiedAddresses[i] == user) {
                unverifiedAddresses[i] = unverifiedAddresses[unverifiedAddresses.length - 1];
                unverifiedAddresses.pop();
                break;
            }
        }
    }
}
