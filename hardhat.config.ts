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
    kovan: {
      url: 'https://eth-kovan.alchemyapi.io/v2/TqGuuMN8VQTIhz1RcRjTCneWWIbonrjx',
      chainId: 42,
      accounts: {
        mnemonic
      }
    },
    mumbai: {
      url: 'https://rpc-mumbai.matic.today',
      chainId: 80001,
      accounts: {
        mnemonic
      }
    },
    rinkeby: {
      url: 'https://eth-rinkeby.alchemyapi.io/v2/63SAsoDt322jm-yUuQ7N-3aAAannBCmI',
      accounts: {
        mnemonic
      },
    },
    goerli: {
      // url: 'https://goerli.infura.io/v3/' + process.env.INFURA_ID,
      url: 'https://eth-goerli.alchemyapi.io/v2/du8xyOP3WSstXJf8JNaK8dSYjlFDFoR9',
      accounts: {
        mnemonic,
      },
    },
    xdai: {
      url: `https://rpc.xdaichain.com/`,
      chainId: 100,
      accounts: {
        mnemonic
      },
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
