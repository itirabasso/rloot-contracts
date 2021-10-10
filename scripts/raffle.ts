/* eslint no-use-before-define: "warn" */
import fs from "fs";
import chalk from "chalk";
import { parseEther } from '@ethersproject/units'
import { internalTask, task } from 'hardhat/config'
import { Wallet } from '@ethersproject/wallet'
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { BigNumberish, Contract, ContractFactory, Signer } from 'ethers'
import { formatEther, randomBytes, splitSignature } from "ethers/lib/utils";

// const publishDir = "../react-app/src/contracts";
// const graphDir = "../subgraph"

// Mumbai - LINK Token
// const LINK_ADDRESS = '0x326C977E6efc84E512bB9C30f76E30c160eD06FB'
// rinkeby - LINK token
const LINK_ADDRESS = '0x01BE23585060835E02B77ef475b0Cc51aA1e0709'
const contracts = {}
task('raffle-deploy')
  .setAction(async ({ publish }, { ethers, config, network, run }: HardhatRuntimeEnvironment) => {
    const [deployer] = await ethers.getSigners()

    await run('compile')

    console.log("Deploying with", await deployer.getAddress(), "\n");

    const properties = await deploy('LootProperties')
    await properties.deployed()
    console.log('LootProperties address', properties.address)
    const oracleFee = parseEther(
      network.name === 'mumbai' ? '0.0001' : '0.1'
    )
    const oracle = await deploy(
      network.name === 'localhost' ? 'OracleMock' : 'Oracle',
      [oracleFee]
    )
    console.log(oracle.address)
    const loot = await deploy('RLoot')
    const cooldown = 60
    const raffle = await deploy('Raffle', [loot.address, oracle.address, cooldown])
    console.log(JSON.stringify({
      'LootProperties': properties.address,
      'Oracle': oracle.address,
      'RLoot': loot.address,
      'Raffle': raffle.address
    }))
    // const combiner = await deploy('Combiner', [stone.address, oracle.address])
    /**
     yarn hardhat add-worker
       --loot-address 0x6dDEca038e601F7D835b221ef84D06E35f52Dc7b
       --worker 0x582C8DC0799888203303bcBF3AfD328D4E8779a8
   
    */
    await run('add-worker', {
      lootAddress: loot.address,
      worker: raffle.address,
    })

    await run('fund-link', { oracle: oracle.address })


    let addresses = {}
    const content = fs.readFileSync(`${config.paths.cache}/addresses.json`)
    if (content === undefined || content.length == 0) {
      addresses[network.name] = contracts
    } else {
      addresses = JSON.parse(content.toString())
      addresses[network.name] = contracts
    }
    fs.writeFileSync(`${config.paths.cache}/addresses.json`, JSON.stringify(addresses, null, 2));

    // if (fs.existsSync(`${publishDir}/addresses.json`)) {
    //   addresses = JSON.parse(fs.readFileSync(`${publishDir}/addresses.json`).toString())
    //   addresses[network.name] = contracts
    // } else {
    //   addresses[network.name] = contracts
    // }
    let subgraphConfig = {}
    // if (fs.existsSync(`${graphDir}/config/config.${network.name}.json`)) {
    //   // subgraphConfig = JSON.parse(fs.readFileSync(`${graphDir}/config/config.${network.name}.json`).toString())
    //   subgraphConfig = Object.assign(subgraphConfig, addresses[network.name])
    //   subgraphConfig['network'] = network.name
    //   subgraphConfig['startBlock'] = blockNumber
    // } else {
    //   subgraphConfig = Object.assign(subgraphConfig, addresses[network.name])
    //   subgraphConfig['network'] = network.name
    //   subgraphConfig['startBlock'] = blockNumber
    // }
    // fs.writeFileSync(`${publishDir}/addresses.json`, JSON.stringify(addresses, null, 2));
    // fs.writeFileSync(`${graphDir}/config/config.${network.name}.json`, JSON.stringify(subgraphConfig, null, 2));


    async function deploy(contractName, _args = [], overrides = {}, libraries = {}) {
      console.log(`Deploying: ${contractName}`);
      // overrides['gasPrice'] = (await ethers.provider.getGasPrice()).mul(3)
      const contractArgs = _args || [];
      const factory = await ethers.getContractFactory(contractName, { libraries: libraries });
      const deployed = await factory.deploy(...contractArgs, overrides);
      // fs.writeFileSync(`artifacts/${contractName}.address`, deployed.address);
      contracts[contractName] = deployed.address
      console.log(chalk.cyan(contractName), "deployed to:", chalk.magenta(deployed.address));
      return await deployed.deployed();
    };
  })


task('get-abis')
  .setAction(async ({ publish }, { ethers, config, artifacts, run }: HardhatRuntimeEnvironment) => {
    const contracts = ['Oracle', 'RLoot', 'Raffle', 'LootProperties']
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

task('deploy-piedras-aludel', 'Deploy Crucible factory contracts')
  .addPositionalParam('vaultFactoryAddress')
  .addPositionalParam('stakingTokenAddress')
  .addPositionalParam('rewardTokenAddress')
  .addFlag('verify', 'verify contracts on etherscan')
  .setAction(async (
    { vaultFactoryAddress, stakingTokenAddress }: any,
    { ethers, run, network }: any
  ) => {

    async function deployContract(
      name: string,
      factory: ContractFactory,
      signer: Signer,
      args: Array<any> = [],
    ): Promise<Contract> {
      const contract = await factory.connect(signer).deploy(...args)
      console.log('Deploying', name)
      console.log('  to', contract.address)
      console.log('  in', contract.deployTransaction.hash)
      return contract.deployed()
    }

    const signers = await ethers.getSigners()
    const admin = signers[0]
    console.log('Owner address', admin.address)
    const powerSwitchFactory = await deployContract(
      'PowerSwitchFactory',
      await ethers.getContractFactory('PowerSwitchFactory'),
      admin
    )
    const rewardPoolFactory = await deployContract(
      'RewardPoolFactory',
      await ethers.getContractFactory('RewardPoolFactory'),
      admin
    )

    // const transmuter = await deployContract(
    //   'TransmuterV2',
    //   await ethers.getContractFactory('TransmuterV2'),
    //   admin
    // )

    // const rewardTokenAddress = '0xDb435816E41eADa055750369Bc2662EFbD465D72'
    // load contracts
    // const rewardToken = await ethers.getContractAt(
    //   'IERC20Detailed',
    //   rewardTokenAddress,
    //   admin,
    // )
    const dustToken = await deployContract(
      'DustToken',
      await ethers.getContractFactory('DustToken'),
      admin,
      [
        'DUST-TOKEN',
        'DUST'
      ]
    )

    const DAY = 60 * 60 * 24
    const rewardScaling = { floor: 33, ceiling: 100, time: 60 * DAY }

    const aludelArgs = [
      admin.address,
      rewardPoolFactory.address,
      powerSwitchFactory.address,
      stakingTokenAddress,
      dustToken.address,
      [rewardScaling.floor, rewardScaling.ceiling, rewardScaling.time],
    ]
    const aludel = await deployContract(
      'AludelPiedras',
      await ethers.getContractFactory('AludelPiedras'),
      admin,
      aludelArgs
    );
    await aludel.connect(admin).registerVaultFactory(vaultFactoryAddress)
    await dustToken.connect(admin).transferOwnership(aludel.address)
    // const powerSwitch = await ethers.getContractAt('PowerSwitch', await aludel.getPowerSwitch())
    // const rewardPool = await ethers.getContractAt('RewardPool', (await aludel.getAludelData()).rewardPool)

    // await stakingToken.mint(admin.address, 1, 10)
  })

export const signPermitEIP2612ERC721 = async (
  owner: Wallet,
  token: Contract,
  spenderAddress: string,
  tokenId: BigNumberish,
  deadline: BigNumberish,
  nonce?: BigNumberish,
) => {
  // get nonce
  nonce = nonce || (await token.nonces(owner.address))
  // console.log('aaaaaaaaaaaa')
  // get chainId
  const chainId = (await token.provider.getNetwork()).chainId
  // get domain
  const domain = {
    name: 'Piedras',
    version: '1',
    chainId: chainId,
    verifyingContract: token.address,
  }
  // get types
  const types: any = {}
  types['Permit'] = [
    { name: 'owner', type: 'address' },
    { name: 'spender', type: 'address' },
    { name: 'tokenId', type: 'uint256' },
    { name: 'nonce', type: 'uint256' },
    { name: 'deadline', type: 'uint256' },
  ]
  // get values
  const values = {
    owner: owner.address,
    spender: spenderAddress,
    tokenId: tokenId,
    nonce: nonce,
    deadline: deadline,
  }
  // sign permission
  // todo: add fallback if wallet does not support eip 712 rpc
  const signedPermission = await owner._signTypedData(domain, types, values)
  // split signature
  const sig = splitSignature(signedPermission)
  // return
  return [
    values.owner,
    values.spender,
    values.tokenId,
    values.deadline,
    sig.v,
    sig.r,
    sig.s,
  ]
}

task('mint-and-lock', 'Mint Crucible and lock in Aludel')
  .addParam('aludel', 'Aludel reward contract')
  .addParam('crucibleFactory', 'Crucible factory contract')
  .addParam('transmuter', 'TransmuterV1 contract')
  .addParam('tokenId', 'the token id')
  .setAction(async (args, { ethers, run, network }) => {
    // log config

    console.log('Network')
    console.log('  ', network.name)
    console.log('Task Args')
    console.log(args)

    // compile

    await run('compile')

    // get signer

    const signer = (await ethers.getSigners())[0]
    console.log('Signer')
    console.log('  at', signer.address)
    console.log('  ETH', formatEther(await signer.getBalance()))
    const signerWallet = Wallet.fromMnemonic(process.env.DEV_MNEMONIC || '')
    // expect(signer.address).to.be.eq(signerWallet.address)

    // fetch contracts

    const aludel = await ethers.getContractAt('AludelPiedras', args.aludel, signer)
    const stakingToken = await ethers.getContractAt(
      'IERC721Permit',
      (await aludel.getAludelData()).stakingToken,
      signer,
    )
    const crucibleFactory = await ethers.getContractAt(
      'CrucibleFactory',
      args.crucibleFactory,
      signer,
    )
    const transmuter = await ethers.getContractAt(
      'TransmuterV2',
      args.transmuter,
      signer,
    )

    // declare config

    // const amount = parseUnits(args.amount, await stakingToken.decimals())
    const salt = randomBytes(32)
    const deadline = (await ethers.provider.getBlock('latest')).timestamp + 60 * 60 * 24 * 100
    // validate balances
    // expect(await stakingToken.balanceOf(signer.address)).to.be.gte(amount)

    // craft permission

    const crucible = await ethers.getContractAt(
      'CrucibleV2',
      await transmuter.predictDeterministicAddress(
        await crucibleFactory.getTemplate(),
        salt,
        crucibleFactory.address,
      ),
      signer,
    )

    const tokenId = args.tokenId

    console.log('Sign Permit')

    const permit = await signPermitEIP2612ERC721(
      signerWallet,
      stakingToken,
      transmuter.address,
      tokenId,
      deadline,
    )

    const signNFTPermission = async (
      method: string,
      vault: Contract,
      owner: Wallet,
      delegateAddress: string,
      tokenAddress: string,
      tokenId: BigNumberish,
      vaultNonce: BigNumberish,
      chainId?: BigNumberish,
    ) => {
      // get chainId
      chainId = chainId || (await vault.provider.getNetwork()).chainId
      // craft permission
      const domain = {
        name: 'UniversalVault',
        version: '1.0.0',
        chainId,
        verifyingContract: vault.address,
      }
      const types = {} as Record<string, any[]>
      types[method] = [
        { name: 'delegate', type: 'address' },
        { name: 'token', type: 'address' },
        { name: 'tokenId', type: 'uint256' },
        { name: 'nonce', type: 'uint256' },
      ]
      const value = {
        delegate: delegateAddress,
        token: tokenAddress,
        tokenId,
        nonce: vaultNonce,
      }
      // sign permission
      const signedPermission = await owner._signTypedData(domain, types, value)
      // return
      return signedPermission
    }

    console.log('Sign Lock')

    const permission = await signNFTPermission(
      'LockNFT',
      crucible,
      signerWallet,
      aludel.address,
      stakingToken.address,
      tokenId,
      0,
    )

    console.log('Mint, Deposit, Stake')

    const tx = await transmuter.mintCruciblePermitAndStake(
      aludel.address,
      crucibleFactory.address,
      signer.address,
      salt,
      permit,
      permission
    )
    console.log('  in', tx.hash)
  })

task('deployer', async ({ }, { ethers }) => {
  console.log('Deployer address', await (await ethers.getSigners())[0].getAddress())
})
