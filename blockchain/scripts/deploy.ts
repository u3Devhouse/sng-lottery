import { ethers } from "hardhat";

async function main() {

  const Token = await ethers.getContractFactory("MockToken");
  const token = await Token.deploy();
  const Lottery = await ethers.getContractFactory("BlazeLottery");
  const lottery = await Lottery.deploy(token.address,"0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625", "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c", 3216, "0x7Ff20b4E1Ad27C5266a929FC87b00F5cCB456374");
  await lottery.deployed();
  console.log("Lottery deployed to:", lottery.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
