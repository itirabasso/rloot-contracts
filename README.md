# rloot

a batch-based system to mint and distribute random loot tokens using VRF 

## install

`yarn`

## tests

First you need to run a local node forking the network mumbai/rinkeby

`yarn hardhat node`

### Chainlink setup

The local fork won't have the chainlink nodes fulfilling the VRF requests so we need to mock it. For that, we have the contract `OracleMock.sol` where you need to set the computed address for `VRFCoordinatorMock.sol` as the first param for `VRFConsumerBase`. Right now, the easiest way to do this is to start the test, copy the VRFCoordinator address that should appear before failing, set it in `Oracle.sol` and run the tests again (i have a small tool to facilitate all of this, but it's a WIP).
The deployer needs to have some LINK. [Chainlink faucets](https://faucets.chain.link) 

And then run the tests over the localhost

`yarn hardhat test --network localhost`


## the project

The idea is to generate pseudorandom numbers calculating keccak256 hashes of random inputs.

Combining a single random number with other inputs as seed, we can generate multiple pseudorandom numbers.


Users can submit their requests for a random token in a batch until the VRF call is made. There is a waiting time before VRF request is fulfilled and after that, users can mint their token generated by the following computation:

`uint256(keccak256(abi.encode(seed, owner)))`

`seed` is the random number, and `owner` is the user's address.


# raffle

The raffle contract follows the same idea but apply it also to select a single winner in the batch and this can be use to distribute content. 

In this reaffle there isn't a limit on how many times you can participate in the same batch but adding a filter on who can participate it's doable.

You could check if the requester has a particular NFT or more than X erc20 balance or if they have completed a quest in a on-chain game. 









