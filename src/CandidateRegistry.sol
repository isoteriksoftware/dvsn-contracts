// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./PartyRegistry.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title CandidateRegistry
 * @notice Manages candidate registration associated with parties and campaigns.
 * @dev Utilizes role-based access control for enhanced security.
 */
contract CandidateRegistry is AccessControl {
    bytes32 public constant SYSTEM_ADMIN_ROLE = keccak256("SYSTEM_ADMIN_ROLE");

    /// @notice Struct representing a candidate.
    struct Candidate {
        uint256 candidateId;
        string name;
        uint256 partyId;
        uint256 campaignId;
        bool exists;
    }

    /// @notice Mapping from candidate ID to Candidate struct.
    mapping(uint256 => Candidate) public candidates;

    /// @notice Counter for the number of registered candidates.
    uint256 public candidateCount;

    /// @notice Mapping from campaign ID to array of candidate IDs.
    mapping(uint256 => uint256[]) public campaignCandidates;

    /// @notice Reference to the PartyRegistry contract.
    PartyRegistry public immutable partyRegistry;

    /// @notice Event emitted when a new candidate is registered.
    event CandidateRegistered(
        uint256 indexed candidateId, string name, uint256 indexed partyId, uint256 indexed campaignId
    );

    /**
     * @notice Initializes the contract by setting the PartyRegistry address.
     * @param _partyRegistry The address of the PartyRegistry contract.
     */
    constructor(address _partyRegistry) {
        require(_partyRegistry != address(0), "CandidateRegistry: Invalid PartyRegistry address.");
        partyRegistry = PartyRegistry(_partyRegistry);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SYSTEM_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Registers a new candidate.
     * @dev Callable by the party admin.
     * @param name The name of the candidate.
     * @param partyId The ID of the party the candidate belongs to.
     * @param campaignId The ID of the campaign the candidate is running in.
     */
    function registerCandidate(string calldata name, uint256 partyId, uint256 campaignId) external {
        require(bytes(name).length > 0, "CandidateRegistry: Candidate name cannot be empty.");

        PartyRegistry.Party memory party = partyRegistry.getParty(partyId);
        require(party.exists, "CandidateRegistry: Party does not exist.");
        require(msg.sender == party.admin, "CandidateRegistry: Only party admin can register candidates.");

        candidates[candidateCount] = Candidate(candidateCount, name, partyId, campaignId, true);
        campaignCandidates[campaignId].push(candidateCount);

        emit CandidateRegistered(candidateCount, name, partyId, campaignId);

        candidateCount++;
    }

    /**
     * @notice Retrieves candidate information by ID.
     * @param candidateId The ID of the candidate.
     * @return The candidate's details.
     */
    function getCandidate(uint256 candidateId) external view returns (Candidate memory) {
        require(candidates[candidateId].exists, "CandidateRegistry: Candidate does not exist.");
        return candidates[candidateId];
    }

    /**
     * @notice Retrieves all candidate IDs for a given campaign.
     * @param campaignId The ID of the campaign.
     * @return An array of candidate IDs.
     */
    function getCandidatesByCampaign(uint256 campaignId) external view returns (uint256[] memory) {
        return campaignCandidates[campaignId];
    }
}
