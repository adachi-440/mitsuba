import { ethers, network } from "hardhat";
import DEPLOYMENTS from "../constants/deployments.json"
import FORWARDERS from "../constants/trustedForwarder.json"

async function main() {
  const Voting = await ethers.getContractFactory("Voting");
  const forwarder = FORWARDERS[network.name as keyof typeof FORWARDERS]
  const voting = await Voting.deploy(DEPLOYMENTS.oft[network.name as keyof typeof DEPLOYMENTS.oft]);

  await voting.deployed();

  console.log(`Voting deployed to ${voting.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
