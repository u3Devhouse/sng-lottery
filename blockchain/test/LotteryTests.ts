import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { convertToHex } from "./utils";
import { parseEther } from "ethers/lib/utils";

const usdtETH = "0xdAC17F958D2ee523a2206206994597C13D831ec7"

describe("Lottery", function () {

  async function setup(){
    const [owner, user1, user2, user3, user4, user5] = await ethers.getSigners();
    const LotteryFactory = await ethers.getContractFactory("BlazeLottery", owner);
    const lottery = await LotteryFactory.deploy(usdtETH)
    const usdtWhale = await ethers.getImpersonatedSigner("0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503")
    const usdt = await ethers.getContractAt("IERC20", usdtETH, usdtWhale)
    await usdt.transfer(user1.address, ethers.utils.parseEther("1000"))
    await usdt.transfer(user2.address, ethers.utils.parseEther("1000"))
    await usdt.transfer(user3.address, ethers.utils.parseEther("1000"))
    await usdt.transfer(user4.address, ethers.utils.parseEther("1000"))
    return {lottery, owner, user1, user2, user3, user4, user5, usdt}
  }

  describe("Owner Functions", ()=>{
    it("Should set the price for current Round", async() => {
      const { lottery, owner, user1, user2, user3, user4, user5, usdt} = await loadFixture(setup);
      await expect(lottery.connect(user1).setPrice(0, 0)).to.be.revertedWith("Ownable: caller is not the owner");
      await lottery.setPrice( parseEther("10"), 1, )
      const round1Info = await lottery.roundInfo(1)
      expect(round1Info.price).to.equal(parseEther("10"))
    })

  })

  describe( "Buy Tickets", function (){
    it("should buy 2 tickets", async function (){
      const { lottery, owner, user1, user2, user3, user4, user5} = await loadFixture(setup);
      const ticketToBuy = convertToHex([10,20,30,40,50])
      const user2TicketsToBuy = new Array(100).fill(ticketToBuy)
      await lottery.connect(user1).buyTickets(new Array(10).fill(ticketToBuy))
      await lottery.connect(user2).buyTickets(user2TicketsToBuy)
      await lottery.connect(user3).buyTickets(new Array(20).fill(ticketToBuy))
      await lottery.connect(user4).buyTickets(new Array(40).fill(ticketToBuy))
      await lottery.connect(user5).buyTickets(new Array(60).fill(ticketToBuy))

      const user1Tickets = await lottery.getUserTickets(user1.address, 0)
      expect(user1Tickets[2]).to.equal(10)
    })
  })
})