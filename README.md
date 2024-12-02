# 🎰 Provably Random Smart Contract Raffle

A cutting-edge, decentralized and automated raffle system built on blockchain technology, leveraging Chainlink VRF for verifiable randomness and Chainlink Automation for trustless execution.

## 🌟 Features

- **Decentralized Random Selection**: Utilizes Chainlink VRF (Verifiable Random Function) v2.5 for cryptographically proven fair winner selection
- **Automated Execution**: Implements Chainlink Automation for time-based trigger mechanisms
- **Gas Optimized**: Implements custom errors and efficient storage practices for minimal gas consumption
- **Fully Tested**: Comprehensive unit tests with 100% coverage, including:
  - Local blockchain testing
  - Forked testnet testing
  - Mainnet fork testing
- **Modular Architecture**: Clean separation of concerns between core logic, deployment, and configuration

## 🔧 Technical Stack

- **Smart Contract**: Solidity 0.8.19
- **Development Framework**: Foundry
- **External Dependencies**:
  - Chainlink VRF V2.5
  - Chainlink Automation
  - OpenZeppelin Contracts

## 🏗 Architecture

### Core Components

1. **Raffle Contract**
   - Manages ticket purchases
   - Handles winner selection
   - Distributes prizes
   - Integrates with Chainlink VRF for randomness
   - Implements automated drawing mechanism

2. **Helper Configuration**
   - Network-specific configurations
   - Automated mock deployment for local testing
   - Dynamic chain ID detection

3. **Deployment System**
   - Automated deployment scripts
   - Environment-specific configurations
   - Subscription management for Chainlink VRF

## 🔄 Workflow

1. **Entry Phase**
   - Users enter by purchasing tickets
   - Entry fees are securely stored in the contract
   - Events are emitted for front-end tracking

2. **Drawing Phase**
   - Automated trigger based on time interval
   - Chainlink VRF request for random number
   - Winner selection using verifiable randomness

3. **Prize Distribution**
   - Automated transfer to winner
   - State reset for next round
   - Event emission for transparency

## 🛡 Security Features

- Comprehensive input validation
- State machine implementation
- Gas optimization techniques

## 🧪 Testing

Extensive testing suite including:
- Unit tests for all core functionalities
- Fuzz testing for edge cases
- Gas optimization tests
- Network forking tests


### Quick Start
```
make install
```

### Run Tests
```
forge test
```

## 📜 License

This project is licensed under the MIT License.


---

Built with ❤️ by Squilliam - Bringing transparency and fairness to decentralized raffles.