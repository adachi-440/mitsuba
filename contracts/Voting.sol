// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICrossChainRouter.sol";
import "./interfaces/IReceiver.sol";

/**
 * @title QVVoting
 * @dev the manager for proposals / votes
 */
contract Voting is Ownable, IReceiver {
    using SafeMath for uint256;

    IERC20 public immutable stakingToken;
    uint256 private _totalSupply;
    string public symbol;
    string public name;
    uint32[] private chainIds;
    mapping(address => mapping(uint32 => uint256)) private _balancesOfEachChain;

    event VoteCasted(address voter, uint ProposalID, uint256 weight);

    event ProposalCreated(
        address creator,
        uint256 ProposalID,
        string title,
        string description,
        uint votingTimeInHours
    );

    enum ProposalStatus {
        IN_PROGRESS,
        TALLY,
        ENDED
    }

    struct Proposal {
        address creator;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        string title;
        string description;
        address[] voters;
        uint expirationTime;
        mapping(address => Voter) voterInfo;
    }

    struct Voter {
        bool hasVoted;
        bool vote;
        uint256 weight;
    }

    mapping(uint256 => Proposal) public Proposals;
    uint public ProposalCount;

    constructor(address token) {
        stakingToken = IERC20(token);
    }

    function receiveMessage(
        bytes32,
        uint32 originChainId,
        address,
        bytes memory callData
    ) external {
        (uint256 flag, bytes memory payload) = abi.decode(
            callData,
            (uint256, bytes)
        );

        if (flag == 1) {
            // vote
            (bool vote, address voter, uint256 proposalId) = abi.decode(
                payload,
                (bool, address, uint256)
            );

            uint256 numTokens;
            for (uint i = 0; i < chainIds.length; i++) {
                uint256 amount = _balancesOfEachChain[voter][chainIds[i]];
                numTokens += amount;
            }

            _castVote(proposalId, numTokens, vote, voter);
        } else if (flag == 2) {
            // stake
            (uint256 amount, address voter) = abi.decode(
                payload,
                (uint256, address)
            );

            _balancesOfEachChain[voter][originChainId] += amount;
        } else if (flag == 3) {
            // withdraw
            (uint256 amount, address voter) = abi.decode(
                payload,
                (uint256, address)
            );

            _balancesOfEachChain[voter][originChainId] -= amount;
        }
    }

    /**
     * @dev Creates a new proposal.
     * @param _description the text of the proposal
     * @param _voteExpirationTime expiration time in minutes
     */
    function createProposal(
        string calldata _title,
        string calldata _description,
        uint _voteExpirationTime
    ) external onlyOwner returns (uint) {
        require(_voteExpirationTime > 0, "The voting period cannot be 0");
        ProposalCount++;

        Proposal storage curProposal = Proposals[ProposalCount];
        curProposal.creator = msg.sender;
        curProposal.status = ProposalStatus.IN_PROGRESS;
        curProposal.expirationTime =
            block.timestamp +
            60 *
            _voteExpirationTime *
            1 seconds;
        curProposal.description = _description;
        curProposal.title = _title;

        emit ProposalCreated(
            msg.sender,
            ProposalCount,
            _title,
            _description,
            _voteExpirationTime
        );
        return ProposalCount;
    }

    /**
     * @dev sets a proposal to TALLY.
     * @param _ProposalID the proposal id
     */
    function setProposalToTally(
        uint _ProposalID
    ) external validProposal(_ProposalID) onlyOwner {
        require(
            Proposals[_ProposalID].status == ProposalStatus.IN_PROGRESS,
            "Vote is not in progress"
        );
        require(
            block.timestamp >= getProposalExpirationTime(_ProposalID),
            "voting period has not expired"
        );
        Proposals[_ProposalID].status = ProposalStatus.TALLY;
    }

    /**
     * @dev sets a proposal to ENDED.
     * @param _ProposalID the proposal id
     */
    function setProposalToEnded(
        uint _ProposalID
    ) external validProposal(_ProposalID) onlyOwner {
        require(
            Proposals[_ProposalID].status == ProposalStatus.TALLY,
            "Proposal should be in tally"
        );
        require(
            block.timestamp >= getProposalExpirationTime(_ProposalID),
            "voting period has not expired"
        );
        Proposals[_ProposalID].status = ProposalStatus.ENDED;
    }

    /**
     * @dev returns the status of a proposal
     * @param _ProposalID the proposal id
     */
    function getProposalStatus(
        uint _ProposalID
    ) public view validProposal(_ProposalID) returns (ProposalStatus) {
        return Proposals[_ProposalID].status;
    }

    /**
     * @dev returns a proposal expiration time
     * @param _ProposalID the proposal id
     */
    function getProposalExpirationTime(
        uint _ProposalID
    ) public view validProposal(_ProposalID) returns (uint) {
        return Proposals[_ProposalID].expirationTime;
    }

    /**
     * @dev counts the votes for a proposal. Returns (yeays, nays)
     * @param _ProposalID the proposal id
     */
    function countVotes(uint256 _ProposalID) public view returns (uint, uint) {
        uint yesVotes = 0;
        uint noVotes = 0;

        address[] memory voters = Proposals[_ProposalID].voters;
        for (uint i = 0; i < voters.length; i++) {
            address voter = voters[i];
            bool vote = Proposals[_ProposalID].voterInfo[voter].vote;
            uint256 weight = Proposals[_ProposalID].voterInfo[voter].weight;
            if (vote == true) {
                yesVotes += weight;
            } else {
                noVotes += weight;
            }
        }

        return (yesVotes, noVotes);
    }

    function castVote(uint _ProposalID, bool _vote) external {
        uint256 numTokens;
        for (uint i = 0; i < chainIds.length; i++) {
            uint256 amount = _balancesOfEachChain[msg.sender][chainIds[i]];
            numTokens += amount;
        }
        _castVote(_ProposalID, numTokens, _vote, msg.sender);
    }

    /**
     * @dev casts a vote.
     * @param _ProposalID the proposal id
     * @param numTokens number of voice credits
     * @param _vote true for yes, false for no
     */
    function _castVote(
        uint _ProposalID,
        uint numTokens,
        bool _vote,
        address _voter
    ) internal validProposal(_ProposalID) {
        require(
            getProposalStatus(_ProposalID) == ProposalStatus.IN_PROGRESS,
            "proposal has expired."
        );
        require(
            !userHasVoted(_ProposalID, _voter),
            "user already voted on this proposal"
        );
        require(
            getProposalExpirationTime(_ProposalID) > block.timestamp,
            "for this proposal, the voting time expired"
        );

        // _balances[msg.sender] = _balances[msg.sender].sub(numTokens);

        uint256 weight = sqrt(numTokens); // QV Vote

        Proposal storage curproposal = Proposals[_ProposalID];

        curproposal.voterInfo[_voter] = Voter({
            hasVoted: true,
            vote: _vote,
            weight: weight
        });

        curproposal.voters.push(_voter);

        emit VoteCasted(_voter, _ProposalID, weight);
    }

    function stake(uint _amount) external payable {
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        _balancesOfEachChain[msg.sender][uint32(block.chainid)] += _amount;
        _totalSupply += _amount;
    }

    function withdraw(uint _amount) external payable {
        require(_amount > 0, "amount = 0");
        _balancesOfEachChain[msg.sender][uint32(block.chainid)] -= _amount;
        _totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function addChainId(uint32 chainId) external onlyOwner {
        chainIds.push(chainId);
    }

    function deleteChainId(uint32 chainId) external onlyOwner {
        for (uint i = 0; i < chainIds.length; i++) {
            uint32 id = chainIds[i];
            if (id == chainId) {
                delete chainIds[i];
            }
        }
    }

    function getChainIds() external view returns (uint32[] memory) {
        return chainIds;
    }

    function getBalanceOfEachChain(
        uint32 chainId
    ) external view returns (uint256) {
        return _balancesOfEachChain[msg.sender][chainId];
    }

    function getTotalBalance() external view returns (uint256) {
        uint256 total;
        for (uint i = 0; i < chainIds.length; i++) {
            total += _balancesOfEachChain[msg.sender][chainIds[i]];
        }

        return total;
    }

    /**
     * @dev checks if a user has voted
     * @param _ProposalID the proposal id
     * @param _user the address of a voter
     */
    function userHasVoted(
        uint _ProposalID,
        address _user
    ) internal view validProposal(_ProposalID) returns (bool) {
        return (Proposals[_ProposalID].voterInfo[_user].hasVoted);
    }

    /**
     * @dev checks if a proposal id is valid
     * @param _ProposalID the proposal id
     */
    modifier validProposal(uint _ProposalID) {
        require(
            _ProposalID > 0 && _ProposalID <= ProposalCount,
            "Not a valid Proposal Id"
        );
        _;
    }

    /**
     * @dev returns the square root (in int) of a number
     * @param x the number (int)
     */
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
