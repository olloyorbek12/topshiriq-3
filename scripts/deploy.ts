import { network } from "hardhat";

async function main() {
  const connection = await network.connect();
  const { ethers } = connection;
  const [owner, allowedPayer, hospitalWallet, emergencyWallet] = await ethers.getSigners();

  const minPayment = ethers.parseEther("0.01");
  const vipPayment = ethers.parseEther("0.05");

  const hospitalQueue = await ethers.deployContract("HospitalQueue", [
    allowedPayer.address,
    hospitalWallet.address,
    emergencyWallet.address,
    minPayment,
    vipPayment,
  ]);
  await hospitalQueue.waitForDeployment();

  console.log("HospitalQueue deployed to:", await hospitalQueue.getAddress());
  console.log("Owner:", owner.address);
  console.log("Allowed payer:", allowedPayer.address);
  console.log("Hospital wallet:", hospitalWallet.address);
  console.log("Emergency wallet:", emergencyWallet.address);
  console.log("Minimum payment:", ethers.formatEther(minPayment), "ETH");
  console.log("VIP payment:", ethers.formatEther(vipPayment), "ETH");

  await connection.close();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
