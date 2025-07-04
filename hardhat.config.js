require("@nomicfoundation/hardhat-toolbox");
require('solidity-coverage');

const { vars } = require("hardhat/config");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    // your network configs
  },
  mocha: {
    timeout: 40000
  }
};
