// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title PartyRegistry
 * @notice Manages the registration of political parties.
 * @dev Utilizes role-based access control for enhanced security.
 */
contract PartyRegistry is AccessControl {
    bytes32 public constant SYSTEM_ADMIN_ROLE = keccak256("SYSTEM_ADMIN_ROLE");
    bytes32 public constant PARTY_ADMIN_ROLE = keccak256("PARTY_ADMIN_ROLE");

    /// @notice Struct representing a political party.
    struct Party {
        string name;
        string symbol;
        address admin;
        bool exists;
    }

    /// @notice Mapping from party ID to Party struct.
    mapping(uint256 => Party) public parties;

    /// @notice Counter for the number of registered parties.
    uint256 public partyCount;

    /// @notice Event emitted when a new party is registered.
    event PartyRegistered(uint256 indexed partyId, string name, string symbol, address indexed admin);

    /// @notice Initializes the contract by setting the deployer as the system admin.
    constructor() {
        _grantRole(SYSTEM_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(PARTY_ADMIN_ROLE, SYSTEM_ADMIN_ROLE);
    }

    /**
     * @notice Registers a new political party.
     * @dev Callable by accounts with the SYSTEM_ADMIN_ROLE.
     * @param name The name of the party.
     * @param symbol The symbol of the party.
     * @param admin The admin address of the party.
     */
    function registerParty(string calldata name, string calldata symbol, address admin)
        external
        onlyRole(SYSTEM_ADMIN_ROLE)
    {
        require(bytes(name).length > 0, "PartyRegistry: Party name cannot be empty.");
        require(bytes(symbol).length > 0, "PartyRegistry: Party symbol cannot be empty.");
        require(admin != address(0), "PartyRegistry: Invalid admin address.");

        parties[partyCount] = Party(name, symbol, admin, true);

        emit PartyRegistered(partyCount, name, symbol, admin);

        partyCount++;
    }

    /**
     * @notice Retrieves party information by ID.
     * @param partyId The ID of the party.
     * @return The party's details.
     */
    function getParty(uint256 partyId) external view returns (Party memory) {
        require(parties[partyId].exists, "PartyRegistry: Party does not exist.");
        return parties[partyId];
    }

    /**
     * @notice Assigns the PARTY_ADMIN_ROLE to an address.
     * @dev Callable by accounts with the SYSTEM_ADMIN_ROLE.
     * @param partyAdmin The address to assign as party admin.
     */
    function assignPartyAdmin(address partyAdmin) external onlyRole(SYSTEM_ADMIN_ROLE) {
        require(partyAdmin != address(0), "PartyRegistry: Invalid party admin address.");
        grantRole(PARTY_ADMIN_ROLE, partyAdmin);
    }
}
