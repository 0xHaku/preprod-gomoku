const { ethers, upgrades } = require("hardhat");

async function main() {
  const Factory = await ethers.getContractFactory("Factory");
  const factory = await upgrades.deployProxy(Factory, [], {
    initializer: "initialize",
    kind: "uups"
  });
  await factory.deployed();
  console.log("proxy deployed to: ", factory.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });