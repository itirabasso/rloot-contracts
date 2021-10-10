import { parseEther } from "ethers/lib/utils";
import { task } from "hardhat/config";
import { deploy } from "./utils";
import fs from "fs";
import { HardhatRuntimeEnvironment } from "hardhat/types";

task('add-worker')
  .addParam('worker')
  .addParam('lootAddress')
  .setAction(async ({ worker, lootAddress }, { ethers, config, artifacts, run }) => {
    const signers = await ethers.getSigners()
    const deployer = signers[0]
    console.log('Adding worker:', worker)
    const loot = await ethers.getContractAt('contracts/RLoot.sol:RLoot', lootAddress);
    const tx = await loot.connect(deployer).addWorker(worker)
    await tx.wait()
  })


// const LINK_ADDRESS = '0x326C977E6efc84E512bB9C30f76E30c160eD06FB'
const LINK_ADDRESS = '0x01BE23585060835E02B77ef475b0Cc51aA1e0709'
task('fund-link')
  .addParam('oracle')
  .addOptionalParam('amount', 'funding amount', '1')
  .setAction(async ({ oracle, amount }, { ethers, config, run }) => {
    const signers = await ethers.getSigners()
    const deployer = signers[0]
    console.log('Signing address:', deployer.address)
    console.log('Funding oracle:', oracle)
    const link = await ethers.getContractAt('IERC20', LINK_ADDRESS);
    let tx = await link.connect(deployer).transfer(oracle, parseEther(amount))
    console.log('tx at', tx.hash)
    await tx.wait()
  })

/**
yarn hardhat process-batch \
  --worker 0x7FDeE06AE1c53A018cDFD6fb80dA6bdE42d77aAE \
  --network mumbai
*/
task('process-batch')
  .addParam('worker')
  .setAction(async (args, { ethers, config, run }) => {
    const signers = await ethers.getSigners()
    const deployer = signers[0]
    // const link = await ethers.getContractAt('contracts/vendor/IERC20.sol:IERC20', '0xa36085F69e2889c224210F603D836748e7dC0088');

    const worker = await ethers.getContractAt('Raffle', args.worker);
    const tx = await worker.connect(deployer).processBatch()
    console.log('TxHash:', tx.hash)
    await tx.wait()
  })

task('set-worker-config')
  .addParam('worker')
  .addOptionalParam('fee')
  .addOptionalParam('cooldown')
  .setAction(async (args, { ethers, config, run }) => {
    const signers = await ethers.getSigners()
    const deployer = signers[0]
    // const link = await ethers.getContractAt('contracts/vendor/IERC20.sol:IERC20', '0xa36085F69e2889c224210F603D836748e7dC0088');

    const worker = await ethers.getContractAt('Raffle', args.worker);
    console.log('worker:', args.worker)
    if (args.fee) {
      console.log('Setting fee:', args.fee)
      const tx = await worker.connect(deployer).setFee(args.fee)
      console.log('  at', tx.hash)
      await tx.wait()
    }
    if (args.cooldown) {
      console.log('Setting cooldown:', args.cooldown)
      const tx = await worker.connect(deployer).setCooldown(args.cooldown)
      console.log('  at', tx.hash)

      await tx.wait()
    }
  })

task('deploy-libraries')
  .setAction(async (args, { ethers, config, run }) => {
    const signers = await ethers.getSigners()
    const deployer = signers[0]

    const stoneFactory = await ethers.getContractFactory('StoneMath', deployer)
    const lootFactory = await ethers.getContractFactory('LootMath', deployer)

    const stoneMath = await stoneFactory.deploy()
    await stoneMath.deployed()
    console.log('StoneMath deployed at', stoneMath.address)

    const lootMath = await lootFactory.deploy()
    await lootMath.deployed()
    console.log('LootMath deployed at', lootMath.address)

    return {
      stoneMath,
      lootMath
    }
})

task('deploy-worker')
  .addParam('workerName')
  .addParam('rloot')
  .addParam('oracle')
  .addOptionalParam('cooldown', '', '600')
  .addOptionalParam('fee', '', parseEther('0.1').toString())
  // .addParam('math')
  .setAction(async (args, { ethers, config, run }) => {
    const signers = await ethers.getSigners()
    const deployer = signers[0]
    // const factory = await ethers.getContractFactory(
    //   args.workerName,
    //   {
    //     libraries: {
    //       StoneMath: args.math
    //     }
    //   },
    // )
    const factory = await ethers.getContractFactory(args.workerName)
    console.log('Deploying', args.workerName)
    const worker = await factory.connect(deployer).deploy(
      args.rloot, args.oracle,
      args.cooldown, args.fee
    )
    console.log('Deployed at', worker.address)
    return worker.deployed()
  })

/*
yarn hardhat replace-worker \
  --rloot 0x624E04723C0DC1873bBf0938A1AC3A6909B7111D \
  --old-worker 0xbA75b49157F04E31BBAfb5F4CcFd2504FBb0c6e9 \
  --new-worker 0x8F4E29823Ee0c28894c0c66b188a745EE599E384 \
  --network rinkeby
*/
task('replace-worker')
  .addParam('rloot')
  .addParam('oldWorker')
  .addParam('newWorker')
  .setAction(async (args, { ethers, config, run }) => {
    const signers = await ethers.getSigners()
    const deployer = signers[0]
    const rloot = (await ethers.getContractAt('RLoot', args.rloot)).connect(deployer);
    console.log('Replacing', args.oldWorker, 'with', args.newWorker)
    await (await rloot.removeWorker(args.oldWorker)).wait()
    await (await rloot.addWorker(args.newWorker)).wait()
  })

  
/////////////////
/////////////////
/////////////////

task('get-abis')
  .setAction(async (args, { ethers, config, artifacts, run }: HardhatRuntimeEnvironment) => {
    const contracts = ['Oracle', 'RLoot', 'Miner', 'Breaker']
    let content = ''
    for (let name of contracts) {
      const { abi } = await artifacts.readArtifact(name)
      if (abi === undefined) continue
      content += 'const ' + name.toUpperCase() + '_ABI = ' + JSON.stringify(abi) + ';\n'
    }
    fs.writeFileSync(
      config.paths.cache + '/abis.js',
      content
    )
  })

