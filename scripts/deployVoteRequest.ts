import { ethers, network } from "hardhat";
import ROUTERS from "../constants/router.json"
import DEPLOYMENTS from "../constants/deployments.json"
import FORWARDERS from "../constants/trustedForwarder.json"


const VOTE = DEPLOYMENTS.voting

async function main() {
  const token = DEPLOYMENTS.oft[network.name as keyof typeof DEPLOYMENTS.oft]
  const router = ROUTERS[network.name as keyof typeof ROUTERS]
  const forwarder = FORWARDERS[network.name as keyof typeof FORWARDERS]
  const VoteRequest = await ethers.getContractFactory("VoteRequest");
  const voteRequest = await VoteRequest.deploy(router, VOTE, token, forwarder);

  await voteRequest.deployed();

  console.log(`VoteRequest deployed to ${voteRequest.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
