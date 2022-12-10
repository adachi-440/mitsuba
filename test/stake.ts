import { ethers, network } from "hardhat";
import CHAIN_ID from "../constants/chainIds.json"
import ROUTERS from "../constants/router.json"
import ABI from "../constants/crossChainRouter.json"
import DEPLOYMENTS from "../constants/deployments.json"

const VOTE = DEPLOYMENTS.voting


// optimism-goerli to arbitrum-goerli
async function main() {
  const [owner] = await ethers.getSigners()
  const SRC_CONTRACT = DEPLOYMENTS["voting-request"][network.name as keyof typeof DEPLOYMENTS["voting-request"]]

  const voteRequest = await ethers.getContractAt("VoteRequest", SRC_CONTRACT);
  const dstChainId = CHAIN_ID["arbitrum-goerli"]
  const router = ROUTERS[network.name as keyof typeof ROUTERS]

  const chainId = network.config.chainId;

  if (chainId === undefined) {
    throw new Error("chainId invalid");
  }

  const amount = ethers.utils.parseEther('10')

  const endpoint = await ethers.getContractAt(
    ABI,
    router,
    owner
  )

  let result;
  let tx;
  // const approveTx = await oft.approve(owner.address, amount)
  // console.log('approving...')
  // result = await approveTx.wait();
  // console.log(result);

  // const c = ethers.utils.defaultAbiCoder.encode(["uint256", "address"], [amount, owner.address]);
  // const callData = ethers.utils.defaultAbiCoder.encode(["uint256", "bytes"], [2, c]);
  // const payload = ethers.utils.defaultAbiCoder.encode(["address", "bytes"], [router, callData]);

  // const fees = await endpoint.estimateSendFee(dstChainId, payload, false)
  // const fee = fees[0]
  // console.log(`fees is the message fee in wei: ${fee}`)

  if (chainId === 421613) {
    const voting = await ethers.getContractAt("Voting", VOTE);
    tx = await voting.stake(amount)
    console.log('staking...')
    result = await tx.wait();
    console.log(result);

  } else {
    tx = await voteRequest.setVote(DEPLOYMENTS.voting)
    console.log('setting...')
    await tx.wait();
    tx = await voteRequest.stake(amount, 1, 421613, { gasLimit: 2000000, value: 0 })
    console.log('sending message...')
    result = await tx.wait();
    console.log(result);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});