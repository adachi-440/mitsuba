/* eslint-disable prettier/prettier */
import { task, types } from "hardhat/config";

task(
  "TASK_SET_CHAIN_ID",
  "setChainID",
).addParam<number>("chainid", "the target network", 0, types.int)
  .addParam<string>("address", "the target contract address", "", types.string)
  // .addParam<string>("nchainid", "Remote ChainID", "", types.string)
  .setAction(async (taskArgs, hre): Promise<null> => {
    let voting = await hre.ethers.getContractAt("Voting", taskArgs.address);
    const chainId = taskArgs.chainid

    try {
      let tx = await (await voting.addChainId(chainId, { gasLimit: 2000000 })).wait()
      console.log(`✅ [${hre.network.name}] addChainId(${chainId})`)
      console.log(` tx: ${tx.transactionHash}`)

    } catch (e: any) {
      if (e.error.message.includes("The chainId + address is already trusted")) {
        console.log("*source already set*")
      } else {
        console.log(e)
        console.log(`❌ [${hre.network.name}] addChainId(${chainId})`)
      }
    }
    return null;
  });
