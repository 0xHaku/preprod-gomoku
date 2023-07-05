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
    mumbai: {
      chainId: 80001,
      url: "https://rpc.ankr.com/polygon_mumbai",
      accounts: ["7b8ec31fabf635b0238a3005fd0c1214cc2f18f56699f0e47387c5d45c9558fc"],
    }
  },
  paths: {
    sources: "./src",
  },
};
