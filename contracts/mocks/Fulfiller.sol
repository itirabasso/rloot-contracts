// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "./VRFCoordinatorMock.sol";
import "hardhat/console.sol";

contract Fulfiller {

    VRFCoordinatorMock public coordinator;
    constructor(address vrfCoordinator) {
        coordinator = VRFCoordinatorMock(vrfCoordinator);
    }

    function fulfill(bytes32 requestId, uint256 randomness, address consumer) public {
        coordinator.callBackWithRandomness(requestId, randomness, consumer);
    }
}