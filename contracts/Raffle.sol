// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import {RLoot} from "./RLoot.sol";
import {LootProperties} from "./LootProperties.sol";
import "./WorkerBatch.sol";

contract Looter is WorkerBatch {
    using LootProperties for Looter;

    // owner => batchId => amount of requests
    // mapping(address => mapping(uint256 => uint256)) public requests;
    mapping(uint256 => address[]) public requests;
    mapping(address => bool) public participated;

    RLoot public lootNFT;

    event WinnerClaim(address owner, uint256 batchId);
    event TicketSold(address owner, uint256 batchId, uint256 amount);

    uint256 public MAX_REQUESTS_PER_BATCH = 5;

    constructor(
        address lootAddress,
        address oracleAddress
        // uint256 cooldown,
        // uint256 fee
    ) WorkerBatch(oracleAddress) {
        lootNFT = RLoot(lootAddress);
    }

    /// user functions
    
    function buy(uint256 amount) external {
        participated[msg.sender] = currentBatch;
        requests[currentBatch].push(msg.sender);
        emit TicketSold(msg.sender, currentBatch, 1);
    }

    function isWinner(address account, uint256 batchId, uint256 index) public view returns (bool) {
        // seed % participants == number of ticket => winner
        uint256 len = requests[batchId].length;
        return batches[batchId].seed % requests[batchId].length == index;
    }

    function claim(uint256 batchId, uint256 index) external {
        require(
            participated[msg.sender],
            "you havent participated"
        );
        require(
            requests[batchId][index] == msg.sender,
            "wrong index"
        );
        require(
            batches[batchId].seed != 0,
            "batch not processed yet"
        );
        require(
            isWinner(msg.sender, batchId, index),
            "you are not the winner"
        );

        delete participated;
        delete requests[batchId];

        emit WinnerClaim(msg.sender, batchId);
    }

 

    function batchGetRequests(address account, uint256[] memory batchIds)
        external
        view
        returns (uint256[] memory)
    {
        require(batchIds.length > 0, "at least one batchId");

        // allocate arrays memory
        uint256[] memory ret = new uint256[](batchIds.length);

        // get batches
        for (uint256 i = 0; i < batchIds.length; i++) {
            ret[i] = requests[account][batchIds[i]];
        }
        // return batches
        return ret;
    }
}
