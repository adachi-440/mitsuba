/* eslint-disable prettier/prettier */
import { ethers } from "hardhat";
import { task, types } from "hardhat/config";
import DEPLOYMENTS from "../constants/deployments.json"
import ROUTERS from "../constants/router.json"


task(
  "TASK_SET_ROUTER",
  "setRouter",
).setAction(async (taskArgs, hre): Promise<null> => {
  const router = ROUTERS[hre.network.name as keyof typeof ROUTERS]
  const src = DEPLOYMENTS["voting-request"][hre.network.name as keyof typeof DEPLOYMENTS["voting-request"]]
  const voteRequest = await ethers.getContractAt("VoteRequest", src);

  try {
    let tx = await (await voteRequest.setRouter(router, { gasLimit: 2000000 })).wait()
    console.log(`✅ [${hre.network.name}] setRouter(${router})`)
    console.log(` tx: ${tx.transactionHash}`)

  } catch (e: any) {
    if (e.error.message.includes("The chainId + address is already trusted")) {
      console.log("*source already set*")
    } else {
      console.log(e)
      console.log(`❌ [${hre.network.name}] setRouter(${router})`)
    }
  }
  return null;
});
