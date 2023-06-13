import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { convertToHex } from "./utils";
import { parseEther } from "ethers/lib/utils";


describe("Lottery", function () {

  async function setup(){
    const [owner, user1, user2, user3, user4, user5, team, upkeep] = await ethers.getSigners();
    const LotteryFactory = await ethers.getContractFactory("BlazeLottery", owner);
    const MockTokenFactory = await ethers.getContractFactory("MockToken", owner);
    const MockVRFFactory = await ethers.getContractFactory("VRFCoordinatorV2Mock", owner);
    const vrf = await MockVRFFactory.deploy(parseEther("0.1"),1000000000);
    await vrf.createSubscription()
    await vrf.fundSubscription(1, parseEther("10"))
    const mockToken = await MockTokenFactory.deploy();
    const lottery = await LotteryFactory.deploy(mockToken.address, vrf.address, "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc", 1, team.address);
    await mockToken.transfer(user1.address, ethers.utils.parseEther("1000"))
    await mockToken.transfer(user2.address, ethers.utils.parseEther("1000"))
    await mockToken.transfer(user3.address, ethers.utils.parseEther("1000"))
    await mockToken.transfer(user4.address, ethers.utils.parseEther("1000"))
    await mockToken.transfer(user5.address, ethers.utils.parseEther("1000"))
    return {lottery, owner, user1, user2, user3, user4, user5, mockToken, team, vrf, upkeep}
  }

  async function setupStarted () {
    const init = await setup()
    const {lottery, owner, user1, user2, user3, user4, user5, mockToken, upkeep} = init
    await lottery.activateLottery(parseEther("10"), await time.latest() + 3600)
    await lottery.setUpkeeper(upkeep.address, true)
    await mockToken.connect(user1).approve(lottery.address, parseEther("1000"))
    await mockToken.connect(user2).approve(lottery.address, parseEther("1000"))
    await mockToken.connect(user3).approve(lottery.address, parseEther("1000"))
    await mockToken.connect(user4).approve(lottery.address, parseEther("1000"))
    await mockToken.connect(user5).approve(lottery.address, parseEther("1000"))
    return init
  }

  describe("Owner Functions", ()=>{
    it("Should set the price for current Round", async() => {
      const { lottery, owner, user1, user2, user3, user4, user5, mockToken} = await loadFixture(setup);
      await expect(lottery.connect(user1).setPrice(0, 0)).to.be.revertedWith("Ownable: caller is not the owner");
      await lottery.setPrice( parseEther("12"), 1, )
      const round1Info = await lottery.roundInfo(1)
      expect(round1Info.price).to.equal(parseEther("12"))
    })
    it("Should set a keeper address", async() => {
      const { lottery, owner, user1, user2, user3, user4, user5, mockToken} = await loadFixture(setup);
      await expect(lottery.connect(user1).setUpkeeper(user1.address, true)).to.be.revertedWith("Ownable: caller is not the owner");
      await lottery.setUpkeeper(user1.address, true)
      expect(await lottery.upkeeper(user1.address)).to.equal(true)
      expect(await lottery.upkeeper(user2.address)).to.equal(false)
    })
    it("Should add an amount to the pot", async () => {
      const { lottery, owner, user1, user2, user3, user4, user5, mockToken} = await loadFixture(setup);
      await mockToken.approve(lottery.address, parseEther("1000"))
      await expect(lottery.addToPot(parseEther("10"),0)).to.be.revertedWithCustomError(lottery, "BlazeLot__InvalidRound");
      await lottery.addToPot(parseEther("10"),1)
      await lottery.addToPot(parseEther("20"), 2)
      expect((await lottery.roundInfo(1)).pot).to.equal(parseEther("10"))
      expect((await lottery.roundInfo(2)).pot).to.equal(parseEther("20"))

      await mockToken.connect(user1).approve(lottery.address, parseEther("1000"))
      await lottery.connect(user1).addToPot(parseEther("30"), 1)
      expect((await lottery.roundInfo(1)).pot).to.equal(parseEther("40"))
    })

  })

  describe("Calculation functions", () => {
    it("Should check that ticket matches are the same regardless of scenario", async () => {
      const { lottery } = await loadFixture(setup);

      const ticketWinner = convertToHex([10,20,30,40,50])
      
      let ticketToBuy = convertToHex([10,20,30,40,50])
      expect(await lottery.checkTicketMatching(ticketWinner, ticketToBuy)).to.equal(5)
      
      ticketToBuy = convertToHex([50,40,30,20,10])
      expect(await lottery.checkTicketMatching(ticketWinner, ticketToBuy)).to.equal(5)

      ticketToBuy = convertToHex([10,20,30,40,60])
      expect(await lottery.checkTicketMatching(ticketToBuy, ticketWinner)).to.equal(4)
      // Repeating numbers
      ticketToBuy = convertToHex([10,10,30,40,10])
      // If winner was repeated digits only count 1
      expect(await lottery.checkTicketMatching(ticketToBuy, ticketWinner)).to.equal(3)
      // If ticket has repeated numbers, it works as expected
      expect(await lottery.checkTicketMatching(ticketWinner, ticketToBuy)).to.equal(3)
      
      ticketToBuy = convertToHex([88,1,0,3,0])
      expect(await lottery.checkTicketMatching(ticketWinner, ticketToBuy)).to.equal(0)

      // use only numbers between 0 and 63
      ticketToBuy = convertToHex([1,40,63, 74, 148 ])
      expect(await lottery.checkTicketMatching(ticketWinner, ticketToBuy)).to.equal(1)
    })
  })

  describe( "Buy Tickets", function (){
    it("Should not allow to buy tickets until the round is started", async ()=>{
      const { lottery, user1 } = await loadFixture(setup);
      const ticketToBuy = convertToHex([10,20,30,40,50])
      await expect(lottery.connect(user1).buyTickets(new Array(10).fill(ticketToBuy))).to.be.revertedWithCustomError(lottery,"BlazeLot__RoundInactive").withArgs(0)
    })
    it("Should not allow to buy tickets until the round is started NOT EVEN OWNER", async ()=>{
      const { lottery, owner } = await loadFixture(setup);
      const ticketToBuy = convertToHex([10,20,30,40,50])
      await expect(lottery.connect(owner).buyTickets(new Array(10).fill(ticketToBuy))).to.be.revertedWithCustomError(lottery,"BlazeLot__RoundInactive").withArgs(0)
    })
    it("should buy tickets", async function (){
      const { lottery, owner, user1, user2, user3, user4, user5} = await loadFixture(setupStarted);
      const ticketToBuy = convertToHex([10,20,30,40,50])
      const user2TicketsToBuy = new Array(100).fill(ticketToBuy)
      await lottery.connect(user1).buyTickets(new Array(10).fill(ticketToBuy))
      await lottery.connect(user2).buyTickets(user2TicketsToBuy)
      await lottery.connect(user3).buyTickets(new Array(20).fill(ticketToBuy))
      await lottery.connect(user4).buyTickets(new Array(40).fill(ticketToBuy))
      await lottery.connect(user5).buyTickets(new Array(60).fill(ticketToBuy))

      expect((await lottery.roundInfo(0)).pot).to.equal(0)
      expect((await lottery.roundInfo(1)).pot).to.equal(parseEther("10").mul(10 + 100 + 20 + 40 + 60))
      expect((await lottery.roundInfo(2)).pot).to.equal(0)
      // Nothing on ROUND 0
      let user1Tickets = await lottery.getUserTickets(user1.address, 0)
      expect(user1Tickets[2]).to.equal(0)
      // Normal rounds
      user1Tickets = await lottery.getUserTickets(user1.address, 1)
      expect(user1Tickets[2]).to.equal(10)
      user1Tickets = await lottery.getUserTickets(user2.address, 1)
      expect(user1Tickets[2]).to.equal(100)
      user1Tickets = await lottery.getUserTickets(user3.address, 1)
      expect(user1Tickets[2]).to.equal(20)
      user1Tickets = await lottery.getUserTickets(user4.address, 1)
      expect(user1Tickets[2]).to.equal(40)
      user1Tickets = await lottery.getUserTickets(user5.address, 1)
      expect(user1Tickets[2]).to.equal(60)
    })
    it("Should not allow to buy tickets if round time has ended", async ()=>{
      const { lottery, owner, user1, user2, user3, user4, user5} = await loadFixture(setupStarted);
      const ticketToBuy = convertToHex([10,20,30,40,50])
      await time.increase(3601)
      await expect(lottery.connect(user1).buyTickets(new Array(10).fill(ticketToBuy))).to.be.revertedWithCustomError(lottery,"BlazeLot__RoundInactive").withArgs(1)
    })
  })

})