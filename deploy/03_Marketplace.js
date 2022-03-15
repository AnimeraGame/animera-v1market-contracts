// Defining bytecode and abi from original contract on mainnet to ensure bytecode matches and it produces the same pair code hash

module.exports = async function ({ ethers, getNamedAccounts, deployments, getChainId }) {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy('Marketplace', {
    from: deployer,
    log: true,
    args: [
      "0x3bA21a3c0A32263e35e29A4038CCB972f34BcBB6", // on mumbai
      0
    ],
    deterministicDeployment: false
  });
};

module.exports.tags = ['TribeOne', 'MarsMarketplace', 'MarsVerse'];
