const { ethers, upgrades } = require("hardhat");
const PROXY_CONTRACT_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

async function main() {
  const Factory = await ethers.getContractFactory("FactoryV2");
  const factory = await upgrades.upgradeProxy(PROXY_CONTRACT_ADDRESS, Factory, {kind: "uups"});
  await factory.deployed();
  console.log("proxy deployed to: ", factory.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });