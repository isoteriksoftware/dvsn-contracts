// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./VoterRegistry.sol";
import "./CandidateRegistry.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title CampaignFactory
 * @notice Manages campaigns and voting process.
 * @dev Utilizes role-based access control, reentrancy protection, and pausability.
 */
contract CampaignFactory is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant SYSTEM_ADMIN_ROLE = keccak256("SYSTEM_ADMIN_ROLE");

    /// @notice Enumeration representing the status of a campaign.
    enum CampaignStatus {
        Active,
        Ended,
        Cancelled
    }

    /// @notice Struct representing a campaign.
    struct Campaign {
        uint256 campaignId;
        string name;
        uint256 startTime;
        uint256 endTime;
        CampaignStatus status;
        uint256 totalVotes;
    }

    /// @notice Counter for the campaign IDs.
    uint256 private campaignIdCounter;

    /// @notice Mapping from campaign ID to Campaign struct.
    mapping(uint256 => Campaign) public campaigns;

    /// @notice Reference to the VoterRegistry contract.
    VoterRegistry public immutable voterRegistry;

    /// @notice Reference to the CandidateRegistry contract.
    CandidateRegistry public immutable candidateRegistry;

    /// @notice Mapping from campaign ID to candidate ID to votes.
    mapping(uint256 => mapping(uint256 => uint256)) public campaignCandidateVotes;

    /// @notice Mapping from campaign ID to hashed NIN to bool (to prevent double voting).
    mapping(uint256 => mapping(bytes32 => bool)) private campaignVoted;

    /// @notice Event emitted when a new campaign is created.
    event CampaignCreated(uint256 indexed campaignId, string name, uint256 startTime, uint256 endTime);

    /// @notice Event emitted when a vote is cast.
    event VoteCast(uint256 indexed campaignId, uint256 indexed candidateId);

    /// @notice Initializes the contract by setting the VoterRegistry and CandidateRegistry addresses.
    /// @param _voterRegistry The address of the VoterRegistry contract.
    /// @param _candidateRegistry The address of the CandidateRegistry contract.
    constructor(address _voterRegistry, address _candidateRegistry) {
        require(_voterRegistry != address(0), "CampaignFactory: Invalid VoterRegistry address.");
        require(_candidateRegistry != address(0), "CampaignFactory: Invalid CandidateRegistry address.");
        voterRegistry = VoterRegistry(_voterRegistry);
        candidateRegistry = CandidateRegistry(_candidateRegistry);
        _grantRole(SYSTEM_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Modifier to check if a campaign is active.
     * @param campaignId The ID of the campaign.
     */
    modifier onlyDuringCampaign(uint256 campaignId) {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.status == CampaignStatus.Active, "CampaignFactory: Campaign is not active.");
        require(block.timestamp >= campaign.startTime, "CampaignFactory: Campaign has not started yet.");
        require(block.timestamp <= campaign.endTime, "CampaignFactory: Campaign has already ended.");
        _;
    }

    /**
     * @notice Creates a new campaign.
     * @dev Callable by accounts with the SYSTEM_ADMIN_ROLE.
     * @param name The name of the campaign.
     * @param startTime The start time of the campaign (as Unix timestamp).
     * @param endTime The end time of the campaign (as Unix timestamp).
     */
    function createCampaign(string calldata name, uint256 startTime, uint256 endTime)
        external
        onlyRole(SYSTEM_ADMIN_ROLE)
        whenNotPaused
    {
        require(bytes(name).length > 0, "CampaignFactory: Campaign name cannot be empty.");
        require(endTime > startTime, "CampaignFactory: End time must be after start time.");

        campaignIdCounter++;
        uint256 campaignId = campaignIdCounter;

        campaigns[campaignId] = Campaign(campaignId, name, startTime, endTime, CampaignStatus.Active, 0);

        emit CampaignCreated(campaignId, name, startTime, endTime);
    }

    /**
     * @notice Allows a voter to cast a vote for a candidate in an active campaign.
     * @param campaignId The ID of the campaign.
     * @param candidateId The ID of the candidate.
     * @param hashedNIN The hashed NIN of the voter.
     */
    function castVote(uint256 campaignId, uint256 candidateId, bytes32 hashedNIN)
        external
        nonReentrant
        whenNotPaused
        onlyDuringCampaign(campaignId)
    {
        require(hashedNIN != bytes32(0), "CampaignFactory: hashedNIN cannot be zero.");
        require(!campaignVoted[campaignId][hashedNIN], "CampaignFactory: Voter has already voted in this campaign.");

        // Validate voter
        VoterRegistry.Voter memory voter = voterRegistry.getVoter(hashedNIN);
        require(voter.isRegistered, "CampaignFactory: Voter is not registered.");
        require(voter.voterAddress == msg.sender, "CampaignFactory: Invalid voter address.");

        // Validate candidate
        CandidateRegistry.Candidate memory candidate = candidateRegistry.getCandidate(candidateId);
        require(candidate.exists, "CampaignFactory: Candidate does not exist.");
        require(candidate.campaignId == campaignId, "CampaignFactory: Candidate is not part of this campaign.");

        // Record the vote (Checks-Effects-Interactions pattern)
        campaignCandidateVotes[campaignId][candidateId]++;
        campaigns[campaignId].totalVotes++;
        campaignVoted[campaignId][hashedNIN] = true;

        emit VoteCast(campaignId, candidateId);
    }

    /**
     * @notice Retrieves the total votes for a candidate in a campaign.
     * @param campaignId The ID of the campaign.
     * @param candidateId The ID of the candidate.
     * @return The number of votes the candidate has received.
     */
    function getCandidateVotes(uint256 campaignId, uint256 candidateId) external view returns (uint256) {
        return campaignCandidateVotes[campaignId][candidateId];
    }

    /**
     * @notice Ends a campaign, making it inactive.
     * @dev Callable by accounts with the SYSTEM_ADMIN_ROLE.
     * @param campaignId The ID of the campaign to end.
     */
    function endCampaign(uint256 campaignId) external onlyRole(SYSTEM_ADMIN_ROLE) whenNotPaused {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.status == CampaignStatus.Active, "CampaignFactory: Campaign is not active.");
        campaign.status = CampaignStatus.Ended;
    }

    /**
     * @notice Retrieves campaign results.
     * @param campaignId The ID of the campaign.
     * @return candidateIds An array of candidate IDs.
     * @return votes An array of votes corresponding to each candidate ID.
     */
    function getCampaignResults(uint256 campaignId)
        external
        view
        returns (uint256[] memory candidateIds, uint256[] memory votes)
    {
        uint256[] memory candidates = candidateRegistry.getCandidatesByCampaign(campaignId);
        uint256[] memory votesCount = new uint256[](candidates.length);

        for (uint256 i = 0; i < candidates.length; i++) {
            votesCount[i] = campaignCandidateVotes[campaignId][candidates[i]];
        }

        return (candidates, votesCount);
    }

    /**
     * @notice Pauses the contract, preventing voting and campaign creation.
     * @dev Callable by accounts with the SYSTEM_ADMIN_ROLE.
     */
    function pause() external onlyRole(SYSTEM_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the contract, allowing voting and campaign creation.
     * @dev Callable by accounts with the SYSTEM_ADMIN_ROLE.
     */
    function unpause() external onlyRole(SYSTEM_ADMIN_ROLE) {
        _unpause();
    }
}
