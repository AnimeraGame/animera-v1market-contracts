// Defining bytecode and abi from original contract on mainnet to ensure bytecode matches and it produces the same pair code hash

module.exports = async function ({ ethers, getNamedAccounts, deployments, getChainId }) {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

  await deploy('MarsPunks', {
    from: deployer,
    log: true,
    args: [
      "https://opensea-creatures-api.herokuapp.com/api/creature/"
    ],
    deterministicDeployment: false,
  })
}

module.exports.tags = ["ERC721", "MarsPunks", "MarseVerse"];
