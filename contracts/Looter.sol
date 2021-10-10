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
    mapping(address => mapping(uint256 => uint256)) public requests;

    RLoot public lootNFT;

    event RequestClaim(address owner, uint256 batchId, uint256 amount);
    event BatchRequest(address owner, uint256 batchId, uint256 amount);

    uint256 public MAX_REQUESTS_PER_BATCH = 5;

    constructor(
        address lootAddress,
        address oracleAddress
        // uint256 cooldown,
        // uint256 fee
    ) WorkerBatch(oracleAddress, 600) {
        lootNFT = RLoot(lootAddress);
    }

    /// user functions
    
    function buy(uint256 amount) external {
        uint256 batchId;
        require(amount > 0, "empty request");
        // add internal function
        if (batches[currentBatch].processing) {
            batchId = currentBatch + 1;
        } else {
            batchId = currentBatch;
        }
        require(
            requests[msg.sender][batchId] + amount <= MAX_REQUESTS_PER_BATCH,
            "batch limit reached"
        );
        // increment user's requests in the current batch
        requests[msg.sender][batchId] += amount;

        emit BatchRequest(msg.sender, batchId, amount);
    }

    function claim(uint256 batchId) external {
        batchClaim(batchId, 1);
    }

    // claim multiple stones at once
    function batchClaim(uint256 batchId, uint256 amount) public {
        // todo : test underflow
        require(amount > 0, "empty claim");
        require(
            requests[msg.sender][batchId] - amount >= 0,
            "no enough loots to claim"
        );

        BatchData storage batch = batches[batchId];

        // TODO : what if the random number is 0?
        require(batch.seed != 0, "batch not processed yet");

        uint256 preseed = batch.seed + requests[msg.sender][batchId];
        for (uint256 i = 0; i < amount; i++) {
            lootNFT.mintLoot(LootProperties.makeSeed(preseed - i, msg.sender), msg.sender);
        }
        requests[msg.sender][batchId] -= amount;

        emit RequestClaim(msg.sender, batchId, amount);
    }

    /// getters

    function canAsk() external view returns (uint256) {
        if (batches[currentBatch].processing) {
            return 0;
        }

        return MAX_REQUESTS_PER_BATCH - requests[msg.sender][currentBatch];
    }

    function getRequests(address account, uint256 batchId)
        external
        view
        returns (uint256)
    {
        require(batchId <= currentBatch, "invalid batch id");
        return requests[account][batchId];
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
