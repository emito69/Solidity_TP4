const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const DeploymentModule = buildModule("DeploymentModule", (m) => {
    // Deploy all contracts in the same module
    const token1 = m.contract("Token1");
    const token2 = m.contract("Token2");
    const simpleSwap = m.contract("SimpleSwap");

    return { token1, token2, simpleSwap};
});

module.exports = DeploymentModule;
