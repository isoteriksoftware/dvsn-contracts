// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title VoterRegistry
 * @notice Manages voter registration and validation using hashed NINs.
 * @dev Utilizes role-based access control and pausability for enhanced security.
 */
contract VoterRegistry is AccessControl, Pausable {
    bytes32 public constant SYSTEM_ADMIN_ROLE = keccak256("SYSTEM_ADMIN_ROLE");
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

    /// @notice Struct representing a voter.
    struct Voter {
        address voterAddress;
        bool isRegistered;
    }

    /// @notice Mapping from hashed NIN to Voter struct.
    mapping(bytes32 => Voter) private voters;

    /// @notice Event emitted when a voter is registered.
    event VoterRegistered(bytes32 indexed hashedNIN, address indexed voterAddress);

    /// @notice Initializes the contract by setting the deployer as the system admin.
    constructor() {
        _grantRole(SYSTEM_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(REGISTRAR_ROLE, SYSTEM_ADMIN_ROLE);
    }

    /**
     * @notice Registers a voter with their hashed NIN and Ethereum address.
     * @dev Callable by accounts with the REGISTRAR_ROLE.
     * @param hashedNIN The hashed NIN of the voter.
     * @param voterAddress The Ethereum address of the voter.
     */
    function registerVoter(bytes32 hashedNIN, address voterAddress) external whenNotPaused onlyRole(REGISTRAR_ROLE) {
        require(hashedNIN != bytes32(0), "VoterRegistry: hashedNIN cannot be zero.");
        require(voterAddress != address(0), "VoterRegistry: Invalid voter address.");
        require(!voters[hashedNIN].isRegistered, "VoterRegistry: Voter already registered.");

        voters[hashedNIN] = Voter(voterAddress, true);

        emit VoterRegistered(hashedNIN, voterAddress);
    }

    /**
     * @notice Validates a voter by their hashed NIN and Ethereum address.
     * @param hashedNIN The hashed NIN of the voter.
     * @param voterAddress The Ethereum address of the voter.
     * @return True if the voter is registered and addresses match.
     */
    function validateVoter(bytes32 hashedNIN, address voterAddress) external view returns (bool) {
        Voter memory voter = voters[hashedNIN];
        return voter.isRegistered && voter.voterAddress == voterAddress;
    }

    /**
     * @notice Retrieves a voter by hashed NIN.
     * @param hashedNIN The hashed NIN of the voter.
     * @return The voter's details.
     */
    function getVoter(bytes32 hashedNIN) external view returns (Voter memory) {
        require(voters[hashedNIN].isRegistered, "VoterRegistry: Voter is not registered.");
        return voters[hashedNIN];
    }

    /**
     * @notice Pauses the contract, preventing voter registration.
     * @dev Callable by accounts with the SYSTEM_ADMIN_ROLE.
     */
    function pause() external onlyRole(SYSTEM_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the contract, allowing voter registration.
     * @dev Callable by accounts with the SYSTEM_ADMIN_ROLE.
     */
    function unpause() external onlyRole(SYSTEM_ADMIN_ROLE) {
        _unpause();
    }
}
