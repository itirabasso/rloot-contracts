// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;
// pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "../WorkerBatch.sol";
import "hardhat/console.sol";

contract OracleMock is VRFConsumerBase, Ownable {
    bytes32 internal keyHash;
    uint256 internal _fee;

    mapping(bytes32 => address) public requestsToWorker;

    constructor(uint256 fee)
        Ownable()
        VRFConsumerBase(
            0xc8c21F4AF32c60cF4b2A3925fC492C6845323144, // VRF Coordinator Rinkeby
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token Rinkeby
        )
    {
        // RINKEBY
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        _fee = fee;
    }

     /** 
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber() public returns (bytes32) {
        require(LINK.balanceOf(address(this)) >= _fee, "not enough link");
        bytes32 requestId = requestRandomness(keyHash, _fee);
        requestsToWorker[requestId] = msg.sender;
        return requestId;
    }

    /// Callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // console.logBytes32(requestId);
        bytes memory workerFulfillCalldata = abi.encodeWithSelector(
            WorkerBatch.fullfilJob.selector,
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
