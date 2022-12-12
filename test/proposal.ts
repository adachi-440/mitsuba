import { ethers, network } from "hardhat";
import CHAIN_ID from "../constants/chainIds.json"
import ROUTERS from "../constants/router.json"
import ABI from "../constants/crossChainRouter.json"
import DEPLOYMENTS from "../constants/deployments.json"


const VOTE = DEPLOYMENTS.voting

// moonbase to arbitrum-goerli
async function main() {
  const [owner] = await ethers.getSigners()

  const voting = await ethers.getContractAt("Voting", VOTE);

  const chainId = network.config.chainId;

  if (chainId === undefined) {
    throw new Error("chainId invalid");
  }

  const amount = ethers.utils.parseEther('1')

  let result;



  // const approveTx = await oft.approve(owner.address, amount)
  // console.log('approving...')
  // result = await approveTx.wait();
  // console.log(result);

  // const tx = await voting.createProposal("Test", "Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test ", 180)

  // console.log('sending message...')
  // result = await tx.wait();
  // console.log(result);

  // result = await voting.countVotes(2)
  // console.log(`Vote Result: ${result}`)

  // result = await voting.ProposalCount()
  // console.log(`Proposal Count: ${result}`)

  result = await voting.getBalanceOfEachChain(420)
  console.log(`Proposals: ${result}`)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});