import { ethers, network } from "hardhat";
import CHAIN_ID from "../constants/chainIds.json"


const SRC_CONTRACT = "0x0225f470BEEF499B890fE7F96477ab586B129A14"
const DST_CONTRACT = "0x22276c7c214C6DB5aD41819719A8b62233e660df"

// moonbase to optimism-goerli
async function main() {
  const [owner] = await ethers.getSigners()

  const oft = await ethers.getContractAt("OFT", SRC_CONTRACT);
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

  // const approveTx = await oft.approve(owner.address, amount)
  // console.log('approving...')
  // result = await approveTx.wait();
  // console.log(result);


  const fees = await oft.estimateSendFee(dstChainId, DST_CONTRACT, am, false, nonBytes)
  console.log(fees[0])
  const tx = await oft.sendFrom(owner.address, 421613, DST_CONTRACT, am, owner.address, SRC_CONTRACT, nonBytes, { gasLimit: 2000000, value: fees[0] })

  console.log('sending message...')
  result = await tx.wait();
  console.log(result);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});