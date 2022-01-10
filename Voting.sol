// SPDX-License-Identifier: GPL-3.0


pragma experimental ABIEncoderV2;
pragma solidity >=0.7.0 <0.9.0;

// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot {
   
    struct Voter {
        uint token;
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
        address voterAddress;
    }

    struct Proposal {
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address private government;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;
    
    uint private winningVoteCount = 0;
    
    uint private tmpWinnerCount = 0;
    
    uint public totalVote;
    
    uint public voterCount;
    
    uint private voteFinishTime;
    
    uint private statViewFinishTime;

    modifier alreadyVoted() {
        require(!voters[msg.sender].voted, "Already voted.");
        _;
    }
    
    modifier multipleWinner() {
        _;
        require(winningVoteCount != 0, "No vote submitted.");
        require(tmpWinnerCount < 2, "Two or more candidate has been voted equally");
    }

    modifier onlyVoters() {
        require(msg.sender != government, "Government cannot check vote.");
        _;
    }
    
    modifier onlyValidVoters() {
        require(voters[msg.sender].voted == false && voters[msg.sender].token != 0, "Only valid voters can cast a vote!");
        _;
    }
    
    /** 
     * @dev Create a new ballot to choose one of 'proposalNames'.
     * @param proposalNames names of proposals
     */
    constructor(bytes32[] memory proposalNames, address[] memory voterArr, uint voteFinishTime_, uint  statViewFinishTime_) {
        government = msg.sender;

        for (uint i = 0; i < proposalNames.length; i++) {
            // 'Proposal({...})' creates a temporary
            // Proposal object and 'proposals.push(...)'
            // appends it to the end of 'proposals'.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
        totalVote = 0;
        voterCount = voterArr.length;
        
        voteFinishTime = voteFinishTime_;
        statViewFinishTime = statViewFinishTime_;
        
        for (uint i = 0; i < voterArr.length; i++) {
           voters[voterArr[i]].token = 1;
        }
    }
    
   /**
   
   Adaylar:
  ["0x63616e6469646174653100000000000000000000000000000000000000000000","0x6332000000000000000000000000000000000000000000000000000000000000","0x6333000000000000000000000000000000000000000000000000000000000000"]
   
   Seçmenler:
   ["0xdD870fA1b7C4700F2BD7f44238821C26f7392148", "0x583031D1113aD414F02576BD6afaBfb302140225", "0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB"]
   
   

   */
   
    function vote(uint proposal) public alreadyVoted() onlyValidVoters() {
        Voter storage sender = voters[msg.sender];
        
        require(sender.token != 0, "Has no right to vote");
        require(block.timestamp < voteFinishTime, "Election has been finished! You cannot vote.");
        
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.token;
        totalVote += sender.token;
        sender.token -= 1;
    }

    
    
    function winningProposal() private multipleWinner()
            returns (uint winningProposal_)   {
        
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
                tmpWinnerCount = 1;
            }
            if (proposals[p].voteCount == winningVoteCount) {
                tmpWinnerCount += 1;
            }
        }
    }

    /** 
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return winnerName_ the name of the winner
     */
    function winnerName() public 
            returns (bytes32 winnerName_)
    {
        require(block.timestamp > voteFinishTime, "Election has not been finished yet.");
        winnerName_ = proposals[winningProposal()].name;
    }
    
    function checkMyVote() public view onlyVoters() returns (bytes32 proposalName) {
        require(voters[msg.sender].voted, "You have not voted yet!");
        uint vote_index = voters[msg.sender].vote;
        
        return proposals[vote_index].name;
        
    }
    
    function getElectionResult() external view returns (bytes32[] memory names, uint[] memory voteCounts) {
        require( block.timestamp > statViewFinishTime, "Election has not been finished! You cannot view the results.");

        bytes32[] memory namesArr = new bytes32[](proposals.length);
        uint[] memory voteCountsArr = new uint[](proposals.length);

        for (uint i = 0; i < proposals.length; i++) {
            Proposal storage proposal = proposals[i];
            namesArr[i] = proposal.name;
            voteCountsArr[i] = proposal.voteCount;
        }

        return (namesArr, voteCountsArr);
    }
}
