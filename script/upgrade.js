const { ethers, upgrades } = require("hardhat");
const PROXY_CONTRACT_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

async function main() {
  const Factory = await ethers.getContractFactory("FactoryV2");
  const factory = await upgrades.upgradeProxy(PROXY_CONTRACT_ADDRESS, Factory);
  console.log("deploying...:", factory.address);
  await factory.deployed();
  console.log("deployed to: ", factory.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });