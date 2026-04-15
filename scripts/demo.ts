import { network } from "hardhat";

function section(title: string) {
  console.log(`\n=== ${title} ===`);
}

async function main() {
  const connection = await network.connect();
  const { ethers } = connection;
  const [owner, allowedPayer, wrongPayer, hospitalWallet, emergencyWallet] = await ethers.getSigners();

  const minPayment = ethers.parseEther("0.01");
  const vipPayment = ethers.parseEther("0.05");
  const hospitalQueue: any = await ethers.deployContract("HospitalQueue", [
    allowedPayer.address,
    hospitalWallet.address,
    emergencyWallet.address,
    minPayment,
    vipPayment,
  ]);
  await hospitalQueue.waitForDeployment();

  section("Deployment");
  console.log("Contract:", await hospitalQueue.getAddress());
  console.log("Owner:", owner.address);
  console.log("Allowed payer:", allowedPayer.address);
  console.log("Hospital wallet:", hospitalWallet.address);
  console.log("Emergency wallet:", emergencyWallet.address);

  section("Access checks");
  try {
    await hospitalQueue.connect(wrongPayer).takeQueue(0, { value: ethers.parseEther("0.02") });
  } catch {
    console.log("Wrong payer rejected successfully.");
  }
  try {
    await hospitalQueue.connect(allowedPayer).takeQueue(3, { value: ethers.parseEther("0.02") });
  } catch {
    console.log("Invalid serviceType rejected successfully.");
  }

  section("Queue payments");
  const regularTx = await hospitalQueue.connect(allowedPayer).takeQueue(0, {
    value: ethers.parseEther("0.02"),
  });
  await regularTx.wait();
  console.log("Regular queue paid (serviceType 0).");

  const vipTx = await hospitalQueue.connect(allowedPayer).takeQueue(2, {
    value: ethers.parseEther("0.06"),
  });
  await vipTx.wait();
  console.log("VIP queue paid (serviceType 2).");

  const emergencyTx = await hospitalQueue.connect(allowedPayer).takeQueue(1, {
    value: ethers.parseEther("0.03"),
  });
  await emergencyTx.wait();
  console.log("Emergency queue paid (serviceType 1).");

  const paidBalance = await hospitalQueue.userBalances(allowedPayer.address);
  const lastQueue = await hospitalQueue.userQueueNumbers(allowedPayer.address);
  const contractReserve = await ethers.provider.getBalance(await hospitalQueue.getAddress());

  section("Final stats");
  console.log("User total paid:", ethers.formatEther(paidBalance), "ETH");
  console.log("User last queue number:", lastQueue.toString());
  console.log("Contract reserve before withdrawal:", ethers.formatEther(contractReserve), "ETH");

  if (contractReserve > 0n) {
    const withdrawTx = await hospitalQueue.connect(owner).withdraw();
    await withdrawTx.wait();
    console.log("Owner withdrew contract reserve.");
  }

  await connection.close();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
