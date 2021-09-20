// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./WorkerBatch.sol";

// import "hardhat/console.sol";

contract Oracle is VRFConsumerBase, Ownable {
    
    bytes32 internal keyHash;
    uint256 internal _fee;

    mapping(bytes32 => address) public requestsToWorker;

    constructor(uint256 fee)
        Ownable()
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
        )
    {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        _fee = fee; // 0.1 * 10 ** 18; // 0.1 LINK        
    }

    /** 
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber() public returns (bytes32) {
        require(LINK.balanceOf(address(this)) >= _fee, "not enough link");
        // get request id from VRF coordinator
        bytes32 requestId = requestRandomness(keyHash, _fee);
        // map request to sender/worker
        requestsToWorker[requestId] = msg.sender;
        return requestId;
    }

    /// Callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        WorkerBatch w;

        // console.logBytes32(requestId);
        bytes memory workerFulfillCalldata = abi.encodeWithSelector(
            w.fullfilJob.selector,
            requestId, 
            randomness 
        );
        
        // fulfillRandomness must not revert so we dont care about the return
        requestsToWorker[requestId].call(workerFulfillCalldata);
    }

    function setLinkFee(uint256 fee) external onlyOwner {
        _fee = fee;
    }

}

