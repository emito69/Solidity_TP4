<!--
**emito69/emito69** is a ✨ _special_ ✨ repository because its `README.md` (this file) appears on your GitHub profile.
Here are some ideas to get you started:
- 🔭 I’m currently working on ...
- 🌱 I’m currently learning ...
- 👯 I’m looking to collaborate on ...
- 🤔 I’m looking for help with ...
- 💬 Ask me about ...
- 📫 How to reach me: ...
- 😄 Pronouns: ...
- ⚡ Fun fact: ...

En el README de github no puedo añadir scrpits de java o css, tengo que trabajar directamente con atributos en html
-->

Solidity_TP4

<div id="header" align="center">
  <h2 align="center"> <img src="https://github.com/devicons/devicon/blob/master/icons/solidity/solidity-plain.svg" title="Solidity" alt="Solidity" height="30" width="40"/> TP4 Solidity ETH-KIPU <img src="https://github.com/devicons/devicon/blob/master/icons/solidity/solidity-plain.svg" title="Solidity" alt="Solidity" height="30" width="40"/> </h2>
  Code Documentation and Explanation
  <h6 align="center"> This repository contains a decentralized exchange (DEX) project built with Hardhat, featuring Solidity smart contracts for token swapping/liquidity, comprehensive tests, and a frontend interface that interacts with deployed contracts on Sepolia testnet.</h6>
   <br>
</div>

## Overview

This project is a decentralized exchange (DEX) implementation using Hardhat for development and testing, with a frontend interface that interacts with contracts deployed on the Sepolia testnet. It includes:

  1. Smart contracts for token swapping and liquidity provision

  2. Comprehensive test suite

  3. Web interface for user interaction

## Decentralized Exchange (DEX) Implementation

A complete decentralized exchange implementation with Hardhat development environment, comprehensive testing, and frontend interface deployed on Sepolia testnet.

## Project Structure

### Smart Contracts
- `SimpleSwap.sol`: Core DEX contract implementing:
  - ERC20 token contract (TK1) with minting capability
  - Constant product AMM (x*y=k)
  - Liquidity provision/removal
  - Token swaps with slippage protection
  - Price calculations
  - Minimum liquidity locking
- `Token1.sol`: ERC20 token contract (TK1) with minting capability
- `Token2.sol`: ERC20 token contract (TK2) with minting capability

### Test Suite
- `simpleswaptest.js`: 
  - Core functionality tests (swap, add/remove liquidity)
  - Edge cases (zero amounts, deadline expiration)
  - Access control tests
  - Mathematical correctness verification
- `token1test.js`: TK1 token standard compliance
- `token2test.js`: TK2 token standard compliance

### Frontend
- `index.html`: Responsive interface with:
  - Wallet connection
  - Liquidity management
  - Swap functionality
  - Price feeds
- `script.js`: Web3 interaction logic
- `styles.css`: Clean, functional UI styling

## Technical Specifications

### SimpleSwap Contract
**Key Features:**
- Implements constant product market maker algorithm
- Liquidity provider tokens minted/burned proportionally
- 0.3% swap fee (implied in price calculation)
- Minimum liquidity lock (1M wei)
- Slippage protection via amountOutMin parameters
- Deadline protection for transactions

**Security Measures:**
- Reentrancy protection
- Input validation
- Ownership controls
- Reserve ratio maintenance

### Frontend Architecture
- Ethers.js for Web3 interaction
- MetaMask integration
- Real-time contract state display
- Transaction receipt parsing
- Error handling and user feedback

## Test Coverage

**Test Metrics:**

- Resumme coverage %:
```bash annotate
-----------------|----------|----------|----------|----------|----------------|
File             |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
-----------------|----------|----------|----------|----------|----------------|
 contracts/      |    92.68 |    55.56 |      100 |    94.29 |                |
  SimpleSwap.sol |    91.43 |    55.88 |      100 |    93.55 |... 236,275,283 |
  Token1.sol     |      100 |       50 |      100 |      100 |                |
  Token2.sol     |      100 |       50 |      100 |      100 |                |
-----------------|----------|----------|----------|----------|----------------|
All files        |    92.68 |    55.56 |      100 |    94.29 |                |
-----------------|----------|----------|----------|----------|----------------|


% Stmts:	Percentage of statements executed by tests
% Branch:	Percentage of conditional branches tested (if/else, switches)
% Funcs_	Percentage of functions called during tests
% Lines:	Percentage of lines executed (similar to statements)
Uncovered Lines:	Specific lines not executed by tests
```

- 15+ individual test cases
- Positive and negative test scenarios
- Gas usage optimization verification
- Cross-contract interaction tests


**Comprehensive test suite covering:**
- 100% of core swap functionality
- 100% of liquidity operations
- 100% of mathematical calculations
- Edge cases (empty pools, max values)
- Access control verification
- Event emission validation

## Deployment Information

### Sepolia Testnet Addresses
- SimpleSwap: [0x54218b05c15B0bB14d6098dd1945Eff8b5019389](https://sepolia.etherscan.io/address/0x54218b05c15b0bb14d6098dd1945eff8b5019389)
- Token1 (TK1): [0x917b3026E6aFf77242150eb1F42aBF46e80E843d](https://sepolia.etherscan.io/address/0x917b3026e6aff77242150eb1f42abf46e80e843d)
- Token2 (TK2): [0x255Db58F3E6631F3589E79a7C0ff23ABC3C853aC](https://sepolia.etherscan.io/address/0x255db58f3e6631f3589e79a7c0ff23abc3c853ac)

## Audit Considerations

### Security
- All mathematical operations protected against overflow/underflow
- Proper access control modifiers
- Slippage and deadline protections
- Liquidity lock mechanism

### Gas Optimization
- Minimal storage operations
- Efficient mathematical calculations
- Event emission optimization

### Frontend Security
- Input sanitization
- Contract call validation
- Error handling

## Getting Started

### Prerequisites
- Node.js (v16+)
- Hardhat
- MetaMask (Sepolia testnet configured)
- Testnet ETH

### Installation
```bash annotate
git clone [repository-url]
cd project-directory
npm install
npm install @openzeppelin/contracts       
```
### Testing

```nodejs annotate
npx hardhat test
```

### Coverage Report
```nodejs annotate
npx hardhat coverage
```


### Frontend Usage
  1. Open (https://emito69.github.io/Solidity_TP4/frontend/index.html) in a browser

  2. Connect your MetaMask wallet

  3. Interact with the DEX functions through the UI



##  License

```
MIT License
```


<hr>
<h6 align="center"> "El blockchain no es solo tecnología, es una revolución en la forma como intercambiamos valor y confianza." - Anónimo.</h6>

<hr>
<div align="center">
 <h4> 🛠 Lenguages & Tools : </h4>
  <img src="https://github.com/devicons/devicon/blob/master/icons/solidity/solidity-plain.svg" title="Solidity" alt="Solidity" height="30" width="40"/>
  <img src="https://github.com/devicons/devicon/blob/master/icons/solidity/solidity-original.svg" title="Solidity" alt="Solidity" height="30" width="40"/>
  <img src="https://github.com/devicons/devicon/blob/master/icons/solidity/solidity-plain.svg" title="Solidity" alt="Solidity" height="30" width="40"/>
  <br>
</div>

<hr>

## Contact

 <h4> 🔭 About me : </h4>

- 📝  I am an Instrumentation and Control engineer who constantly trains to keep up with new technologies.

- 📫 How to reach me: [my Linkedin](https://www.linkedin.com/in/emiliano-alvarez-a6677b1b4).

<br>
<div id="badges" align="center">
    <a href="https://www.linkedin.com/in/emiliano-alvarez-a6677b1b4/">
        <img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="Linkedin Badge"  style="max-width: 100%;">
    </a> 
</div>
<br>
</div>

