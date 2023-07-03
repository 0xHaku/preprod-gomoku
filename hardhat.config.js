/** @type import('hardhat/config').HardhatUserConfig */
require("@openzeppelin/hardhat-upgrades");

module.exports = {
  solidity: "0.8.18",
  // defaultNetwork: "localhost",
  networks: {
    hardhat: {
      chainId: 31336,
    },
    anvil: {
      chainId: 31336,
      url: "http://127.0.0.1:8545"
    },
  },
  paths: {
    sources: "./src",
  },
};
