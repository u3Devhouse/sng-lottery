import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { convertToHex } from "./utils";
import { parseEther, parseUnits } from "ethers/lib/utils";
import { constants } from "ethers";

const USDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"

describe("Alt buys Lottery", function ()
{

  async function setup()
  {
    const otcWallet = await ethers.getImpersonatedSigner("0x28b170c9B73603E09bF51B485252218A68E279D2")
    const [ owner, user1, user2, user3, user4, user5, team, upkeep, burnwallet ] = await ethers.getSigners();
    const LotteryFactory = await ethers.getContractFactory("BlazeLottery", owner);
    const MockTokenFactory = await ethers.getContractFactory("MockToken", owner);
    const MockVRFFactory = await ethers.getContractFactory("VRFCoordinatorV2Mock", owner);
    const vrf = await MockVRFFactory.deploy(parseEther("0.1"), 1000000000);
    const usdc = await ethers.getContractAt("MockToken", USDCAddress);
    await vrf.createSubscription()
    await vrf.fundSubscription(1, parseEther("10"))
    const mockToken = await MockTokenFactory.deploy();
    const lottery = await LotteryFactory.deploy(mockToken.address, vrf.address, "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc", 1, team.address, burnwallet.address, otcWallet.address);
    await vrf.addConsumer(1, lottery.address)
    await mockToken.transfer(user1.address, ethers.utils.parseEther("1000"))
    await mockToken.transfer(user2.address, ethers.utils.parseEther("1000"))
    await mockToken.transfer(user3.address, ethers.utils.parseEther("1000"))
    await mockToken.transfer(user4.address, ethers.utils.parseEther("1000"))
    await mockToken.transfer(user5.address, ethers.utils.parseEther("1000"))
    await mockToken.transfer(otcWallet.address, ethers.utils.parseEther("100000000000"))
    // approve the lottery to spend the users tokens
    await user4.sendTransaction({ to: otcWallet.address, value: ethers.utils.parseEther("1") })
    await mockToken.connect(otcWallet).approve(lottery.address, ethers.utils.parseEther("100000000000"))
    return { lottery, owner, user1, user2, user3, user4, user5, mockToken, team, vrf, upkeep, usdc, burnwallet }
  }

  async function setupStarted()
  {
    const init = await setup()
    const { lottery, owner, user1, user2, user3, user4, user5, mockToken, upkeep } = init
    await lottery.activateLottery(parseEther("10"), await time.latest() + 3600)
    await lottery.setUpkeeper(upkeep.address, true)
    await mockToken.connect(user1).approve(lottery.address, parseEther("1000"))
    await mockToken.connect(user2).approve(lottery.address, parseEther("1000"))
    await mockToken.connect(user3).approve(lottery.address, parseEther("1000"))
    await mockToken.connect(user4).approve(lottery.address, parseEther("1000"))
    await mockToken.connect(user5).approve(lottery.address, parseEther("1000"))

    await mockToken.connect(owner).approve(lottery.address, parseEther("10000"))
    await lottery.connect(owner).addToPot(parseEther("10000"), 1, [])

    return init
  }
  it("Should set the token to add as accepted", async () => {
    const { lottery, owner, user1, user2, user3, user4, user5, mockToken, team, vrf, upkeep } = await setupStarted();
    expect((await lottery.acceptedTokens(USDCAddress)).accepted).to.equal(false)
    await lottery.connect(owner).acceptAlt(USDCAddress, true)
    const usdcAltStuff = await lottery.acceptedTokens(USDCAddress)
    expect(usdcAltStuff.accepted).to.equal(true)
    expect(usdcAltStuff.burn).to.equal(0);
    expect(usdcAltStuff.dev).to.equal(0);
    expect(usdcAltStuff.match3).to.equal(0);
    expect(usdcAltStuff.match4).to.equal(0);
    expect(usdcAltStuff.match5).to.equal(0);
    expect(usdcAltStuff.v2Pair).to.equal(constants.AddressZero);

    await lottery.connect(owner).setAltDistribution(25,25,25,5,20,USDCAddress, "0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc");
    const usdcAltStuff2 = await lottery.acceptedTokens(USDCAddress)
    expect(usdcAltStuff2.accepted).to.equal(true)
    expect(usdcAltStuff2.burn).to.equal(20);
    expect(usdcAltStuff2.dev).to.equal(5);
    expect(usdcAltStuff2.match3).to.equal(25);
    expect(usdcAltStuff2.match4).to.equal(25);
    expect(usdcAltStuff2.match5).to.equal(25);
    expect(usdcAltStuff2.v2Pair).to.equal("0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc");
  })

  it("Should allow users to buy with alt tokens", async () => {
    const { lottery, owner, user1, team, mockToken, usdc, burnwallet } = await setupStarted();
    await lottery.connect(owner).acceptAlt(USDCAddress, true)
    await lottery.connect(owner).setAltDistribution(25,25,25,5,20,USDCAddress, "0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc");
    await lottery.connect(owner).setAltPrice(parseUnits("1",6), USDCAddress);

    const usdcWhale = await ethers.getImpersonatedSigner("0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503");
    await usdc.connect(usdcWhale).transfer(user1.address, ethers.utils.parseUnits("1000",6))

    const ticketToBuy = convertToHex([ 10, 20, 30, 40, 50 ])
    const beforeBalance = await mockToken.balanceOf(lottery.address)
    await usdc.connect(user1).approve(lottery.address, ethers.utils.parseEther("1000"))
    await lottery.connect(user1).buyTicketsWithAltTokens([ticketToBuy, ticketToBuy], USDCAddress)
    expect(await mockToken.balanceOf(lottery.address)).to.be.gt(beforeBalance)
    console.log({
      beforeBalance: beforeBalance.toString(),
      afterBalance: (await mockToken.balanceOf(lottery.address)).toString(),
      burnWalletBalance: (await usdc.balanceOf(burnwallet.address)).toString(),
      devBalance: (await usdc.balanceOf(team.address)).toString(),
    })

    expect((await lottery.getUserTickets(user1.address,1)).tickets).to.equal(2)
  })
})