// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import {RLoot} from "./RLoot.sol";
import "./WorkerBatch.sol";
import "hardhat/console.sol";

contract Raffle is Ownable, WorkerBatch {
    struct WinnerData {
        uint256 index;
        address winner;
    }

    // batch id => participants addresses
    mapping(uint256 => address[]) public requests;
    // account => batch id
    mapping(address => uint256) public participated;
    // batch id => winner data
    mapping(uint256 => WinnerData) public winners;

    bool public finalized;

    RLoot public lootNFT;

    event WinnerClaim(address owner, uint256 batchId);
    event TicketSold(address owner, uint256 batchId, uint256 amount);

    uint256 public MAX_REQUESTS_PER_BATCH = 5;

        // uint256 cooldown,
        // uint256 fee
    constructor(address lootAddress, address oracleAddress)
        WorkerBatch(oracleAddress)
        Ownable()
    {
        lootNFT = RLoot(lootAddress);
        finalized = false;
    }

    /// user functions

    // revert when contract is finalizing?
    function buy(uint256 amount) external {
        // last participation is not current batch
        // require(participated[msg.sender] < currentBatch, "already participated");
        // set participation as current batch
        // participated[msg.sender] = currentBatch;
        // add to batch requests.
        requests[currentBatch].push(msg.sender);
        // emit event 
        emit TicketSold(msg.sender, currentBatch, 1);
    }

    // function isWinner(address account, uint256 batchId)
    //     external
    //     view
    //     returns (bool)
    // {
    //     // no winner for this batch yet.
    //     if (winners[batchId].winner == address(0)) {
    //         return false;
    //     }
    //     return winners[batchId].winner == account;
    // }

    function fullfilJob(bytes32 requestId, uint256 randomness)
        public
        override
        onlyOracle
    {
        // seed % amount of participants == index
        winners[currentBatch].index = randomness % requests[currentBatch].length;
        super.fullfilJob(requestId, randomness);
    }

    function claim(uint256 batchId, uint256 index) external {
        //
        // require(participated[msg.sender] == batchId, "you havent participated");
        // this index in this batch is the sender
        require(requests[batchId][index] == msg.sender, "wrong index");
        // the batch hasnt been 
        require(batches[batchId].seed != 0, "batch not processed yet");
        // it's processed => fetch batch winner
        WinnerData storage winner = winners[batchId];
        // winner index is correct
        require(winner.index == index, "you are not the winner");
        // winner is not set => hasnt been claimed
        require(winner.winner == address(0), "already claimed");
        // set the winner
        winner.winner = msg.sender;

        // we can skip this and just selfdestruct at some point in the future.
        // delete requests[batchId];
        // console.log("%d - %d", gasleft(), requests[batchId].length);

        emit WinnerClaim(msg.sender, batchId);
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
