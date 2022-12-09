import { ethers, network } from "hardhat";
import LZ_ENDPOINTS from "../constants/layerzeroEndpoints.json"
import ROUTERS from "../constants/router.json"

async function main() {
    const OFT = await ethers.getContractFactory("OFT");
    const endpoint = LZ_ENDPOINTS[network.name as keyof typeof LZ_ENDPOINTS]
    const router = ROUTERS[network.name as keyof typeof ROUTERS]
    const oft = await OFT.deploy("Futaba", "FTB", endpoint, router);

    await oft.deployed();

    console.log(`OFT deployed to ${oft.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
