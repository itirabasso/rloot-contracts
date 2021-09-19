import { expectEventIn, expectRevert, expectToBe, getEventArg, getEventArgFromLogs, parseLogs } from "./utils";

import { BN, constants } from '@openzeppelin/test-helpers'
// import { setGameContext } from "./context";
import { sharedBeforeEach } from "./utils/shared-before-each";
import { revertAfter } from "./utils/revert-after";

const chai = require('chai');
chai.use(require('chai-bn')(BN));
const { expect } = chai

import { ethers, network } from "hardhat";
import { revert, takeSnapshot } from "./utils/utils";
import { Oracle, Raffle, IERC20 } from "../typechain";
import { OracleMock__factory } from "../typechain/factories/OracleMock__factory";
import { Raffle__factory } from "../typechain/factories/Raffle__factory"
import { VRFCoordinatorMock__factory } from "../typechain/factories/VRFCoordinatorMock__factory";
import { Fulfiller__factory } from "../typechain/factories/Fulfiller__factory";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { parseEther } from "ethers/lib/utils";
import { VRFCoordinatorMock } from "../typechain/VRFCoordinatorMock";
import { OracleMock } from "../typechain/OracleMock";
import { Fulfiller } from "../typechain/Fulfiller";


// const LINK_ADDRESS = '0xa36085F69e2889c224210F603D836748e7dC0088'
const LINK_ADDRESS = '0x01BE23585060835E02B77ef475b0Cc51aA1e0709'

describe.skip("Breaker", function () {

  revertAfter();
  let snapshotId
  let admin: SignerWithAddress
  let deployer: SignerWithAddress
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
  // after(async function () {
  //   await revert(network.provider, snapshotId)

  // })
  sharedBeforeEach(async function () {
    const oracleFee = parseEther('0.1')
    
    Oracle.deploy(oracleFee)
    coordinator = await Coordinator.deploy(LINK_ADDRESS)
    console.log('Coordinator address', coordinator.address)

    fulfiller = await Fulfiller.deploy(coordinator.address)
    console.log('Fulfiller address', fulfiller.address)

    link = await ethers.getContractAt('@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20', LINK_ADDRESS) as IERC20;

    oracle = await Oracle.deploy(oracleFee)

    await oracle.deployed()

    // loot = await Loot.deploy();
    // await loot.deployed();
  });


  it("init raffle", async function () {
  })

  describe("user have 5 loots", async function () {
    
  })


})