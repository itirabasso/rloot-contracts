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
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
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

