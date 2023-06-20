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
    await vrf.addConsumer(1, lottery.address)
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

    await mockToken.connect(owner).approve(lottery.address, parseEther("10000"))
    await lottery.connect(owner).addToPot(parseEther("10000"), 1)

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

      // Cant buy zero tickets
      await expect( lottery.connect(user1).buyTickets([])).to.be.revertedWithCustomError(lottery,"BlazeLot__InsufficientTickets")

      expect((await lottery.roundInfo(0)).pot).to.equal(0)
      expect((await lottery.roundInfo(1)).pot).to.equal(parseEther("10").mul(10 + 100 + 20 + 40 + 60).add(parseEther("10000")))
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

  describe("Round Ends and Draws", ()=>{
    it("Should have true on upkeep needed when round ends", async () => {
      const { lottery } = await loadFixture(setupStarted);
      await time.increase(3601)
      const upkeepCheck = await lottery.checkUpkeep("0x00")
      expect(upkeepCheck.upkeepNeeded).to.equal(true)
      const decodedPerformData = ethers.utils.defaultAbiCoder.decode(["bool", "uint[]"], upkeepCheck.performData)
      expect(decodedPerformData[0]).to.equal(true)
      expect(decodedPerformData[1].length).to.equal(5)
      expect(decodedPerformData[1][0]).to.equal(0)
    })
    it("Should not allow to draw if round is not finished", async () => {
      const { lottery } = await loadFixture(setupStarted);

      const upkeepCheck = await lottery.checkUpkeep("0x00")
      expect(upkeepCheck.upkeepNeeded).to.equal(false)
      const decodedPerformData = ethers.utils.defaultAbiCoder.decode(["bool", "uint[]"], upkeepCheck.performData)
      expect(decodedPerformData[0]).to.equal(true)
      expect(decodedPerformData[1].length).to.equal(5)
      expect(decodedPerformData[1][0]).to.equal(0)
      await expect(lottery.endRound()).to.be.revertedWithCustomError(lottery, "BlazeLot__InvalidRoundEndConditions");
    })
    it("Should request a winner and set the data appropriately", async () => {
      const { lottery, team, user1, user2, user3, user4, upkeep, vrf, mockToken } = await loadFixture(setupStarted);
      const ticketToBuy1 = convertToHex([10,20,30,40,50])
      const ticketToBuy2 = convertToHex([10,63,48,55,11])
      const ticketToBuy3 = convertToHex([19,15,4,8,24])
      const ticketToBuy4 = convertToHex([10,3,36,23,22])

      await lottery.connect(user1).buyTickets(new Array(10).fill(ticketToBuy1))
      await lottery.connect(user2).buyTickets(new Array(100).fill(ticketToBuy2))
      await lottery.connect(user3).buyTickets(new Array(20).fill(ticketToBuy3))
      await lottery.connect(user4).buyTickets(new Array(1).fill(ticketToBuy4))
      const totalTicketsPot = parseEther("10").mul(10 + 100 + 20 + 1).add(parseEther("10000"))

      await time.increase(3601);
      const upkeepCheck = await lottery.checkUpkeep("0x00")
      const decodedPerformData = ethers.utils.defaultAbiCoder.decode(["bool", "uint[]"], upkeepCheck.performData)
      expect( upkeepCheck.upkeepNeeded).to.equal(true)
      expect(decodedPerformData[0]).to.equal(true)

      await expect(lottery.connect(upkeep).performUpkeep(upkeepCheck.performData)).to.emit(vrf, "RandomWordsRequested")
      // Shouldn't allow to draw again while waiting for randomness
      const roundInfo = await lottery.roundInfo(1)
      expect(roundInfo.randomnessRequestID).to.equal(1)
      const afterRequestUpkeepCheck = await lottery.checkUpkeep("0x00")
      expect(afterRequestUpkeepCheck.upkeepNeeded).to.equal(false)
      await expect(lottery.endRound()).to.be.revertedWithCustomError(lottery, "BlazeLot__InvalidRoundEndConditions");

      // fulfill randomness
      const randonNumberSelected = convertToHex([4,10,3,87,5])
      await vrf.fulfillRandomWordsWithOverride(1, lottery.address, [randonNumberSelected])
      // requestId = 1 ?
      const matchings = await lottery.matches(1)
      expect(matchings.winnerNumber).to.equal( convertToHex([4,10,3,23,5])) // digit over 6 bits got turned to 6 bit number
      expect(matchings.match1).to.equal(0)
      // Shouldnt allow to buy tickets
      await expect(lottery.connect(user1).buyTickets(new Array(10).fill(ticketToBuy1))).to.be.revertedWithCustomError(lottery,"BlazeLot__RoundInactive").withArgs(1)
      
      // Should request upkeep again
      const afterRandomnessUpkeepCheck = await lottery.checkUpkeep("0x00")
      expect(afterRandomnessUpkeepCheck.upkeepNeeded).to.equal(true)
      const decodedPerformData2 = ethers.utils.defaultAbiCoder.decode(["bool", "uint[]"], afterRandomnessUpkeepCheck.performData)
      expect(decodedPerformData2[0]).to.equal(false)
      expect(decodedPerformData2[1][0]).to.equal(20+110)
      expect(decodedPerformData2[1][1]).to.equal(0)
      expect(decodedPerformData2[1][2]).to.equal(1)
      expect(decodedPerformData2[1][3]).to.equal(0)
      expect(decodedPerformData2[1][4]).to.equal(0)

      // Should not allow to draw again while round has not advanced
      await expect(lottery.endRound()).to.revertedWithCustomError(lottery, "BlazeLot__InvalidRoundEndConditions");
      const tokenSupplyBeforeUpkeep = await mockToken.totalSupply()
      // Not allowed to perform upkeep if not upkeeper
      await expect(lottery.connect(user1).performUpkeep(afterRandomnessUpkeepCheck.performData)).to.be.revertedWithCustomError(lottery, "BlazeLot__InvalidUpkeeper");
      // Should perform upkeep
      await expect(lottery.connect(upkeep).performUpkeep(afterRandomnessUpkeepCheck.performData)).to.emit(lottery, "RolloverPot").withArgs(1, totalTicketsPot.div(2))
      // New CheckUpkeep should be false
      const afterUpkeepUpkeepCheck = await lottery.checkUpkeep("0x00")
      expect(afterUpkeepUpkeepCheck.upkeepNeeded).to.equal(false)
      // Round should have advanced
      const roundInfo2 = await lottery.roundInfo(2)
      expect(roundInfo2.active).to.equal(true)
      expect(roundInfo2.randomnessRequestID).to.equal(0)
      const round1InfoEnded = await lottery.roundInfo(1)
      expect(round1InfoEnded.active).to.equal(false)
      // Price got rolled over
      expect(roundInfo2.price).to.equal(round1InfoEnded.price)
      const round1Winners = await lottery.matches(1)
      // Check that all data was added appropriately
      expect(round1Winners.match1).to.equal(130)
      expect(round1Winners.match2).to.equal(0)
      expect(round1Winners.match3).to.equal(1)
      expect(round1Winners.match4).to.equal(0)
      expect(round1Winners.match5).to.equal(0)
      // Check that pot was rolled over
      expect(roundInfo2.pot).to.equal(totalTicketsPot.div(2))
      // Tokens were burned
      expect(tokenSupplyBeforeUpkeep).to.be.gt(await mockToken.totalSupply())
      // tokens were sent to team wallet
      expect(await mockToken.balanceOf(team.address)).to.equal(totalTicketsPot.mul(5).div(100))

    })
    it("Should roll over all funds to next round if no one plays", async () => {
      const { lottery, team, user1, user2, user3, user4, upkeep, vrf, mockToken } = await loadFixture(setupStarted);
      await time.increase(3601);
      await lottery.connect(user1).endRound()
      expect(await lottery.currentRound()).to.equal(2)
      const roundInfo = await lottery.roundInfo(1)
      const round2Info = await lottery.roundInfo(2)
      expect(round2Info.active).to.equal(true)
      expect(roundInfo.active).to.equal(false)
      expect(round2Info.pot).to.equal(roundInfo.pot.mul(75).div(100))
      
    })
  })

  async function setupTicketsBought () {
    const init = await setupStarted()

    const { lottery, team, user1, user2, user3, user4, user5, upkeep, vrf, mockToken } = init;
    const ticketToBuy1 = convertToHex([10,20,30,40,50]) // match 1
    const ticketToBuy2 = convertToHex([10,63,48,5,11]) // match 2
    const ticketToBuy3 = convertToHex([19,3,4,5,23]) // match 4
    const ticketToBuy4 = convertToHex([10,3,36,23,22]) // match 3
    const ticketToBuy5 = convertToHex([0,0,0,0,0])

    await lottery.connect(user1).buyTickets(new Array(2).fill(ticketToBuy1))
    await lottery.connect(user2).buyTickets(new Array(4).fill(ticketToBuy2))
    await lottery.connect(user3).buyTickets(new Array(2).fill(ticketToBuy3))
    await lottery.connect(user4).buyTickets(new Array(1).fill(ticketToBuy4))
    await lottery.connect(user5).buyTickets(new Array(5).fill(ticketToBuy5))

    const pot = (await lottery.roundInfo(1)).pot

    return {...init, pot}
  }

  async function setupRoundEnded() {
    const init = await setupTicketsBought()
    const { lottery, upkeep, vrf } = init;
    // End the round
    await time.increase(3601);
    const upkeepCheck = await lottery.checkUpkeep("0x00")
    await lottery.connect(upkeep).performUpkeep(upkeepCheck.performData)
    // fulfill randomness
    const randonNumberSelected = convertToHex([4,10,3,23,5])
    await vrf.fulfillRandomWordsWithOverride(1, lottery.address, [randonNumberSelected])
    // Set winners
    const afterRandomnessUpkeepCheck = await lottery.checkUpkeep("0x00")
    await lottery.connect(upkeep).performUpkeep(afterRandomnessUpkeepCheck.performData)
    return init
  }

  describe("Claim Winnings", () => {
    it("Should not allow to claim winnings if round is not finished", async () => {
      const { lottery, user1 } = await loadFixture(setupTicketsBought);
      await expect(lottery.connect(user1).claimTickets(1, [0,1,2,3,4], [0,1,2,3,4])).to.be.revertedWithCustomError(lottery, "BlazeLot__InvalidRound");
      
    })
    it("should not allow to claim winnings if tickets are not winners", async() => {
      const { lottery, user1, user5 } = await loadFixture(setupRoundEnded);

      // function reverts when trying to claim tickets that are not winners
      // if a single ticket is not a winner, the whole claim is reverted
      await expect(lottery.connect(user5).claimTickets(1, [0,1,2,3,4], [0,1,2,3,4])).to.be.revertedWithCustomError(lottery, "BlazeLot__InvalidClaimMatch").withArgs(0);// args(ticketIndex)
      // Cannot claim duplicate indexed tickets
      await expect(lottery.connect(user1).claimTickets(1, [0,0], [1,1])).to.be.revertedWithCustomError(lottery, "BlazeLot__DuplicateTicketIdClaim").withArgs(1,0); // args( round id,ticket index, match)

    })
    it("Should allow to claim winnings if tickets are winners", async () =>{
      const { lottery, user3, user4, upkeep, vrf, mockToken, pot } = await loadFixture(setupRoundEnded);
      // Make sure user can claim winnings
      const initU1Balance = await mockToken.balanceOf(user3.address);
      expect(await lottery.checkTicket(1, 0, user3.address)).to.equal(pot.div(4).div(2))
      await expect(lottery.checkTickets(1, [0,3], user3.address)).to.be.revertedWithPanic();
      await expect(lottery.connect(user3).claimTickets(1, [0,1], [4,4])).to.emit(lottery, "RewardClaimed").withArgs(user3.address, pot.div(4));
      expect(await mockToken.balanceOf(user3.address)).to.equal(initU1Balance.add(pot.div(4)));
      await expect(lottery.connect(user3).claimTickets(1, [0], [4])).to.be.revertedWithCustomError(lottery, "BlazeLot__DuplicateTicketIdClaim").withArgs(1,0); // args( round id,ticket index)

    })
    it("Should be able to claim winnings from multiple rounds")
  })

})