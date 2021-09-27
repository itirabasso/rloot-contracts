require('dotenv').config()
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "hardhat-typechain";
import "solidity-coverage"
// require('./scripts/deploy')
// require('./scripts/chainlink')
// require('./scripts/game')
// require('./scripts/rloot')
// require('./scripts/management')
require('./scripts/raffle')

import "@nomiclabs/hardhat-etherscan";
import "hardhat-gas-reporter"

require('dotenv').config()

const mnemonic = process.env.DEV_MNEMONIC || ''
const archive_node = process.env.ETHEREUM_ARCHIVE_URL || ''

export default {
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10000,
      },
    },
  },
  networks: {
    hardhat: {
      forking: {
        url: process.env.ETHEREUM_ARCHIVE_URL,
      },
      accounts: {
        mnemonic
        
      }
    },
    mumbai: {
      url: 'https://polygon-mumbai.g.alchemy.com/v2/du8xyOP3WSstXJf8JNaK8dSYjlFDFoR9',
      chainId: 80001,
      accounts: {
        mnemonic
      }
    },
    localhost: {
      url: 'http://localhost:8545',
      chainId: 31337,
      accounts: {
        mnemonic
      }
    },
    remote: {
      url: '',
      chainId: 31337
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY,
  },
}
