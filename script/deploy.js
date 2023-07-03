const { ethers, upgrades } = require("hardhat");

async function main() {
  const Factory = await ethers.getContractFactory("Factory");
  const factory = await upgrades.deployProxy(Factory, [], {
    initializer: "initialize",
  });
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