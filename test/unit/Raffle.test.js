const { network, getNamedAccounts, deployments, ethers } = require('hardhat')
const { developmentChains, networkConfig } = require('../../helper-hardhat-config')
const { assert, expect } = require('chai')

!developmentChains.includes(network.name) ? describe.skip : describe("Raffle Unit Tests", async function () {
    let raffle, vrfCoordinatorV2Mock, raffleEntranceFee, deployer, interval
    const chainId = network.config.chainId


    beforeEach(async function () {
        deployer = (await getNamedAccounts()).deployer
        await deployments.fixture(["all"])
        raffle = await ethers.getContract("Raffle", deployer)
        vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock", deployer)
        raffleEntranceFee = await raffle.getEntranceFee()
        interval = await raffle.getInterval()

    })

    describe("constructor", async function () {
        it("initiatlize the raffle correctly", async function () {
            const raffleState = await raffle.getRaffleState()
            assert.equal(raffleState.toString(), "0", "These two should match")
            assert.equal(interval.toString(), networkConfig[chainId]["interval"])

        })
    })

    describe("enterRaffle", async function () {
        it("reverts when you don't pay enough", async function () {
            await expect(raffle.enterRaffle()).to.be.revertedWith(
                "Raffle__SendMoreToEnterRaffle"
            )
        })
        it("records players when the enter", async function () {
            await raffle.enterRaffle({ value: raffleEntranceFee })
            const playerFromContract = await raffle.getPlayer(0);
            assert.equal(playerFromContract, deployer)
        })
        it("emits events on enter", async function () {
            await expect(raffle.enterRaffle({ value: raffleEntranceFee })).to.emit(raffle, "RaffleEnter") // Contract instance(raffle), event name(RaffleEnter)
        })
        it("doesnt allow entrance when raffle is calculating", async function () {
            await raffle.enterRaffle({ value: raffleEntranceFee })
            await network.provider.send("evm_increaseTime", [interval.toNumber() + 1]) //Increases blockchain time
            await network.provider.send("evm_mine", []) // Mining of new bock when time is increased
            await raffle.performUpkeep([])
            await expect(raffle.enterRaffle({ value: raffleEntranceFee })).to.be.revertedWith("Raffle__RaffleNotOpen")

        })


    })

})