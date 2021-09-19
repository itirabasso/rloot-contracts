// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Oracle.sol";

// import "hardhat/console.sol";

contract WorkerBatch is Ownable {
    struct BatchData {
        uint256 seed;
        bytes32 requestId;
        bool exists;
        bool processing;
    }

    BatchData[] public batches;
    uint256 public nextBatchId;
    uint256 public currentBatch;

    // uint256 internal _fee;
    // uint256 internal _cooldown;
    // uint256 internal _lastProcessTime;

    Oracle public oracle;

    event BatchProcessed(uint256 batchId);

    constructor(
        address oracleAddress
        // uint256 cooldown,
        // uint256 fee
    ) Ownable() {
        currentBatch = 0;
        nextBatchId = 0;
        newBatch();
        oracle = Oracle(oracleAddress);
        // _lastProcessTime = block.timestamp;
        // _cooldown = cooldown;
        // _fee = fee;
    }

    /// @notice process a batch
    function processBatch() external {
        // is batch already being processed?
        require(!batches[currentBatch].processing, "already processing");
        // is off cooldown?
        // require(block.timestamp - _lastProcessTime > _cooldown, "cooldown");
        
        // increase next batch id to handle incoming requests during processing
        nextBatchId += 1;
        // create a new empty batch
        newBatch();
        
        // batch is now processing
        batches[currentBatch].processing = true;
        // request random number
        // what if the oracle is down?
        // what if the oracle is hacked?
        batches[currentBatch].requestId = oracle.getRandomNumber();
        // now we wait until the chainlink's node fulfill our request
    }

    function fullfilJob(bytes32 requestId, uint256 randomness)
        public
        virtual
        onlyOracle
    {
        // what if the current batch is not right? maybe mapping requestId to batchId solves a pontential issue.
        require(
            batches[currentBatch].requestId == requestId,
            "requestId already set"
        );
        // set the random number for the current batch
        batches[currentBatch].seed = randomness;
        // batch is no longer processing
        batches[currentBatch].processing = false;
        // emit batch processed event
        emit BatchProcessed(currentBatch);
        // current batch
        currentBatch = nextBatchId;
        // update last process time
        // _lastProcessTime = block.timestamp;

    }

    // getters

    function getBatch(uint256 id) public view returns (BatchData memory) {
        require(id <= currentBatch, "invalid batch id");
        return batches[id];
    }

    /// @notice creates an empty bash and add it the state
    function newBatch() internal {
        BatchData memory batch = BatchData({
            seed: 0,
            requestId: 0x0,
            exists: true, // is this really necessary?
            processing: false
        });
        // add new batch to the state
        batches.push(batch);
    }

    // function isBatchClaimable(uint256 id) public view returns (bool) {
    //     require(id <= currentBatch, "");
    //     return batches[id].seed != 0;
    // }

    modifier onlyOracle() {
        require(msg.sender == address(oracle), "only oracle");
        _;
    }



    // getters

    // function getFee() external view returns (uint256) {
    //     return _fee;
    // }
    // function getLastProcessTime() external view returns (uint256) {
    //     return _lastProcessTime;
    // }

    // function getCooldown() external view returns (uint256) {
    //     return _cooldown;
    // }

    // function canProcess() public view returns (bool) {
    //     return block.timestamp > _lastProcessTime + _cooldown;
    // }

    // // admin functions

    // function setWorkerFee(uint256 value) external onlyOwner {
    //     _fee = value;
    // }

    // function setCooldown(uint256 time) external onlyOwner {
    //     _cooldown = time;
    // }
}
