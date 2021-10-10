// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import {RLoot} from "./RLoot.sol";
import "./WorkerBatch.sol";

import "hardhat/console.sol";

contract Raffle is Ownable, WorkerBatch {

    struct WinnerData {
        address winner;
        uint88 index;
        bool claimed;
    }

    // batch id => participants addresses
    mapping(uint256 => address[]) public requests;
    // account => batch id
    mapping(address => uint256) public participated;
    // batch id => winner data
    mapping(uint256 => WinnerData) public winners;

    bool public finalized;

    RLoot public lootNFT;

    event Winner(address owner, uint256 batchId);
    event Claimed(address owner, uint256 batchId);
    event TicketSold(address owner, uint256 batchId, uint256 amount);

    uint256 public MAX_REQUESTS_PER_BATCH = 5;

    // uint256 fee
    constructor(
        address lootAddress,
        address oracleAddress,
        uint256 cooldown
    )
        WorkerBatch(oracleAddress, cooldown)
        Ownable()
    {
        lootNFT = RLoot(lootAddress);
        finalized = false;
    }

    /// user functions

    /// @notice sends pay ether to get one raffle's ticket.
    function buy() external {
        // add to batch requests.
        requests[currentBatch].push(msg.sender);
        // emit event 
        emit TicketSold(msg.sender, currentBatch, 1);
    }

    /// @notice claims batch's prize
    /// @param batchId numer of batch
    function claim(uint256 batchId) external {
        uint256 seed = batches[batchId].seed;
        // the batch hasnt been processed
        require(seed != 0, "batch not processed yet");
        // it's processed => fetch batch's winner
        WinnerData storage winner = winners[batchId];
        // check the batch's winner index is
        require(requests[batchId][winner.index] == msg.sender, "you are not the winner");
        // hasnt been claimed
        require(!winner.claimed, "already claimed");
        // set as claimed
        winner.claimed = true;

        // 
        // hash seed, batch and owner address.
        uint256 properties = uint256(
            keccak256(abi.encode(seed, batchId, msg.sender))
        );
        // define max rarity
        uint8 MAX_RARITY = 0xff;
        properties = properties | MAX_RARITY;
        // mint the loot
        lootNFT.mintLoot(properties, msg.sender);

        emit Claimed(msg.sender, batchId);
    }

    // this shouldnt be here - worker batch should be a separate contract
    function fullfilJob(bytes32 requestId, uint256 randomness)
        public
        override
        onlyOracle
    {
        uint256 previousBatch = currentBatch - 1;
        address winnerAddress = address(0);
        if (requests[previousBatch].length > 0) {
            WinnerData storage winner = winners[previousBatch];
            // index = seed % amount of participants 
            uint88 winnerIndex = uint88(randomness % requests[previousBatch].length);
            winner.index = winnerIndex;
            winner.winner = requests[previousBatch][winnerIndex];
            winnerAddress = winner.winner;
        } 

        super.fullfilJob(requestId, randomness);
        emit Winner(winnerAddress, previousBatch);
    }


    function findIndex(uint256 batchId, address account) external view returns (uint256 index) {
        address[] memory participants = requests[batchId];
        for (uint256 i = 0; i < participants.length; i++) {
            if (participants[i] == account) {
                return i;
             }
        }
        revert("not found");
    }

    function getWinner(uint256 batchId) external view returns (WinnerData memory) {
        return winners[batchId];
    }

    // admin functions 

    // finalize after next process?
    function finalize() external onlyOwner {
        finalized = true;
    }

    function end() external onlyOwner {
        require(finalized, "not finalized");
        selfdestruct(payable(msg.sender));
    }

}
