const { ethers, upgrades } = require("hardhat");
const PROXY_CONTRACT_ADDRESS = "0x62753Fd89C49Def15F904DCB4d46531bEb9736A5";

async function main() {
  const Factory = await ethers.getContractFactory("FactoryV2");
  const implAddress = await upgrades.prepareUpgrade(PROXY_CONTRACT_ADDRESS, Factory, {
    kind: "uups"
  });
  console.log("implemention deployed to: ", implAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });