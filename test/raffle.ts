import { expectEventIn, expectRevert, expectToBe, getEventArg, getEventArgFromLogs, parseLogs } from "./utils";

import { BN, constants } from '@openzeppelin/test-helpers'
// import { setGameContext } from "./context";
import { sharedBeforeEach } from "./utils/shared-before-each";
import { revertAfter } from "./utils/revert-after";

const chai = require('chai');
chai.use(require('chai-bn')(BN));
const { expect } = chai;

import { artifacts, ethers, network } from "hardhat";
import { revert, takeSnapshot } from "./utils/utils";
import { Oracle, Raffle, IERC20 } from "../typechain";
import { OracleMock__factory } from "../typechain/factories/OracleMock__factory";
import { Raffle__factory } from "../typechain/factories/Raffle__factory"
import { VRFCoordinatorMock__factory } from "../typechain/factories/VRFCoordinatorMock__factory";
import { Fulfiller__factory } from "../typechain/factories/Fulfiller__factory";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { formatEther, HDNode, parseEther, randomBytes } from "ethers/lib/utils";
import { VRFCoordinatorMock } from "../typechain/VRFCoordinatorMock";
import { OracleMock } from "../typechain/OracleMock";
import { Fulfiller } from "../typechain/Fulfiller";
import { BigNumber, Contract, Signer, Wallet } from "ethers";


// const LINK_ADDRESS = '0xa36085F69e2889c224210F603D836748e7dC0088'
// const LINK_ADDRESS = '0x01BE23585060835E02B77ef475b0Cc51aA1e0709'
const BYTES32_ZEROS = '0x0000000000000000000000000000000000000000000000000000000000000000'

// Mumbai
// LINK Token
const LINK_ADDRESS = '0x326C977E6efc84E512bB9C30f76E30c160eD06FB'
// VRF Coordinator	0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
// Key Hash	0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
// Fee	0.0001 LINK

describe("Raffle", function () {

  revertAfter();
  let snapshotId
  let admin: SignerWithAddress
  let deployer: SignerWithAddress
  let user: SignerWithAddress
  let anotherUser: SignerWithAddress
  // contracts factories
  // let RLootNFT: RLoot__factory
  let Oracle: OracleMock__factory
  let Raffle: Raffle__factory
  let Coordinator: VRFCoordinatorMock__factory
  let Fulfiller: Fulfiller__factory
  // contracts
  let coordinator: VRFCoordinatorMock
  let fulfiller: Fulfiller
  let oracle: OracleMock
  let raffle: Raffle
  let link: IERC20

  before(async function () {
    const accounts = await ethers.getSigners()
    deployer = accounts[0]
    admin = accounts[1]
    user = accounts[2]
    anotherUser = accounts[3]
    // rndAccount = Wallet.createRandom().connect(ethers.provider)
    // await delegate.sendTransaction({
    //   to: owner.address,
    //   value: parseEther('300') //(await delegate.getBalance()).mul(9).div(10),
    // })
    snapshotId = await takeSnapshot(network.provider)
    // self.Loot = new RLoot__factory(self.deployer)
    Oracle = new OracleMock__factory(deployer)
    Raffle = new Raffle__factory(deployer)
    Coordinator = new VRFCoordinatorMock__factory(deployer)
    Fulfiller = new Fulfiller__factory(deployer)
  })
  revertAfter()
  sharedBeforeEach(async function () {
    const oracleFee = parseEther('0.0001')

    coordinator = await Coordinator.deploy(LINK_ADDRESS)
    await coordinator.deployed()
    console.log('Coordinator address', coordinator.address)

    fulfiller = await Fulfiller.deploy(coordinator.address)
    await fulfiller.deployed()
    console.log('Fulfiller address', fulfiller.address)

    link = await ethers.getContractAt('@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20', LINK_ADDRESS) as IERC20;

    oracle = await Oracle.deploy(oracleFee)
    await oracle.deployed()


    await link.connect(deployer).transfer(oracle.address, oracleFee.mul(10))
    // loot = await Loot.deploy();
    // await loot.deployed();
    console.log('deployer link balance:', formatEther(await link.balanceOf(deployer.address)))
    console.log('oracle link balance:', formatEther(await link.balanceOf(oracle.address)))
  });

  async function processBatch(contract: Raffle, signer: Signer): Promise<string> {
    const tx = await contract.connect(signer).processBatch()
    const receipt = await tx.wait()
    const requestId = getEventArgFromLogs(
      coordinator,
      receipt.logs,
      // receipt.logs.filter(l => l.address === contract.address),
      "RandomnessRequest",
      "requestId"
    );
    return requestId
  }

  async function newRaffle(): Promise<Raffle> {
    raffle = await Raffle.deploy(oracle.address, oracle.address)
    return await raffle.deployed()
  }

  async function processAndFulfill(contract: Raffle, signer: Signer) {
    const currentBatch = await contract.currentBatch()
    const batch = await contract.batches(currentBatch)
    const requestId = batch.requestId === BYTES32_ZEROS
      ? await processBatch(contract, signer)
      : batch.requestId
    await fulfill(contract, requestId)

  }

  async function fulfill(worker: Contract, requestId: string, randomness?: any) {
    function rand256() {
      // load cryptographically random bytes into array
      const bytes = randomBytes(32);
      // convert byte array to hexademical representation
      const bytesHex = bytes.reduce((o, v) => o + ('00' + v.toString(16)).slice(-2), '');
      return BigNumber.from(BigInt('0x' + bytesHex).toString(10));
    }

    if (randomness === undefined) {
      randomness = rand256();
    }
    const consumer = await worker.oracle()
    // console.log(requestId, randomness, consumer)
    const tx = await fulfiller.fulfill(requestId, randomness, consumer);
    const receipt = await tx.wait()
    // console.log(receipt)
    return receipt;
  }

  async function createWallets(amount: number): Promise<Wallet[]> {
    const accounts = await ethers.getSigners()
    const wallets = []
    const wallet = Wallet.createRandom().connect(ethers.provider)
    const mnemonic = wallet._mnemonic()
    const prefix = mnemonic.path.substr(0, mnemonic.path.length - 1)
    console.log(prefix)
    for (let i = 0; i < amount; i++) {
      const path = prefix + i.toString()
      // const hd = HDNode.fromMnemonic(mnemonic.phrase, null, mnemonic.locale).derivePath(path)
      const w = Wallet.fromMnemonic(mnemonic.phrase, path).connect(ethers.provider)
      await accounts[7].sendTransaction({
        to: w.address,
        value: parseEther('0.1') //(await delegate.getBalance()).mul(9).div(10),
      })
      wallets.push(w)
    }

    // for (let i = 0; i < amount; i++) {
    //   const wallet = Wallet.createRandom().connect(ethers.provider)
    //   await accounts[7].sendTransaction({
    //     to: wallet.address,
    //     value: parseEther('0.1') //(await delegate.getBalance()).mul(9).div(10),
    //   })
    //   wallets.push(wallet)
    // }

    return wallets
  }

  it("init raffle", async function () {
  })

  it("", async function () {
    // new raffle => batch 1
    const raffle = await newRaffle()
    // buy 1 ticket
    await raffle.buy(1)
    // process batch
    // console.log((await raffle.batches(0)).seed)
    // console.log((await raffle.batches(1)).seed)
    await processAndFulfill(raffle, deployer)
    // console.log((await raffle.batches(0)).seed)
    // console.log((await raffle.batches(1)).seed)
    // console.log((await raffle.batches(2)).seed)
    // find user index in batch
    const index = await raffle.findIndex(1, deployer.address)
    // claim
    await raffle.claim(1, index)

    // batch 2
    // // buy a ticket
    // await raffle.buy(1)
    // // buy more than one ticket should revert
    // await expect(raffle.buy(1)).to.be.reverted
    // // another user can buy a ticket
    // await raffle.connect(anotherUser).buy(1)

    // console.log(await raffle.isWinner(deployer.address, 1))
  })

  it("stress test", async function () {
    const accounts = await createWallets(100)

    // new raffle => batch 1
    const raffle = await newRaffle()
    // console.log(await raffle.getBatch(0));
    // console.log(await raffle.getBatch(1));

    await Promise.all(accounts.map(acc => raffle.connect(acc).buy(1)))

    // process batch
    await processAndFulfill(raffle, deployer)
    let winnerData = await raffle.getWinner(1)
    console.log(winnerData)
    // find user index in batch
    // const index = await raffle.findIndex(1, deployer.address)
    // claim
    let winner = accounts[winnerData.index.toNumber()]
    await raffle.connect(winner).claim(1, winnerData.index)
  }).timeout(1000*60*15)

  // it.only('self destruct', async function() {
  //   const accounts = await createWallets(500)
  //   const raffle = await newRaffle()
  //   const times = 100
    
  //   for (let i; i < times; i++) {
  //     // new raffle => batch 1
      
  //     // all the accounts buy one ticket
  //     await Promise.all(accounts.map(acc => raffle.connect(acc).buy(1)))
  //     // process batch
  //     await processAndFulfill(raffle, deployer)
  //   }
  //   const b = await deployer.getBalance()
  //   await raffle.connect(deployer).finalize()
  //   await raffle.connect(deployer).end()
  //   const ba = await deployer.getBalance()
  //   console.log(formatEther(b.sub(ba)))
  // }).timeout(1000*60*25)



})