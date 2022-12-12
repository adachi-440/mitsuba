import { ethers, network } from "hardhat";
import CHAIN_ID from "../constants/chainIds.json"
import DEPLOYMENTS from "../constants/deployments.json"

const VOTE = DEPLOYMENTS.voting

// moonbase to optimism-goerli
async function main() {
  const [owner] = await ethers.getSigners()
  const src = DEPLOYMENTS.oft[network.name as keyof typeof DEPLOYMENTS.oft]
  const voteRequest = DEPLOYMENTS["voting-request"][network.name as keyof typeof DEPLOYMENTS["voting-request"]]

  const oft = await ethers.getContractAt("OFT", src);
  const dstChainId = CHAIN_ID["arbitrum-goerli"]

  const chainId = network.config.chainId;

  if (chainId === undefined) {
    throw new Error("chainId invalid");
  }

  const amount = ethers.utils.parseEther('100000')

  let result;
  const mintTX = await oft.mint(owner.address, amount)
  console.log('minting...')
  result = await mintTX.wait();
  console.log(result);

  const am = ethers.utils.parseEther('1')
  const nonBytes = ethers.utils.defaultAbiCoder.encode(["string"], [""])


  let approveTx;
  if (chainId === 80001) {
    approveTx = await oft.approve(VOTE, amount)
    console.log('approving...')
    result = await approveTx.wait();
    console.log(result);

  } else {
    approveTx = await oft.approve(voteRequest, amount)
    console.log('approving...')
    result = await approveTx.wait();
    console.log(result);
  }



  // const fees = await oft.estimateSendFee(dstChainId, DST_CONTRACT, am, false, nonBytes)
  // console.log(fees[0])
  // const tx = await oft.sendFrom(owner.address, 421613, DST_CONTRACT, am, owner.address, SRC_CONTRACT, nonBytes, { gasLimit: 2000000, value: fees[0] })

  // console.log('sending message...')
  // result = await tx.wait();
  // console.log(result);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});