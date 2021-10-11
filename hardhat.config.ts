require('dotenv').config()
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "hardhat-typechain";
import "solidity-coverage"

require('./scripts/management')
import './scripts/raffle'

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
        url: archive_node
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
    rinkeby: {
      url: 'https://eth-rinkeby.alchemyapi.io/v2/63SAsoDt322jm-yUuQ7N-3aAAannBCmI',
      chainId: 4,
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
