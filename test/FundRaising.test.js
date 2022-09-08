const { assert, expect } = require("chai")
const { getNamedAccounts, ethers, accounts } = require("hardhat")

describe("FundRaising", function () {
    let FundRaising, fundraising
    let deployer
    beforeEach(async () => {
        deployer = accounts[0]
        //deployer = (await getNamedAccounts()).deployer
        //FundRaising = await ethers.getContractFactory("FundRaising", deployer)
        FundRaising = await ethers.getContractFactory("FundRaising")
        fundraising = await FundRaising.deploy()
        await fundraising.deployed()
    })

    describe("startCampaign", function () {
        let name = "Campaign"
        let desciption = ""
        let targetAmount = 10
        let duration = 1000
        it("Add new campaign", async () => {
            await fundRaising.startCampaign(name, desciption, targetAmount, duration)
            const campaign = await fundRaising.getCampaign(0)
            assert.equal(campaign.name, name)
            assert.equal(campaign.desciption, desciption)
            assert.equal(campaign.targetAmount, targetAmount)
            assert.equal(campaign.duration, duration)
        })
    })
    /*
    describe("donate", function () {
        
    })

    describe("cancelDonation", function () {
        
    })

    describe("finishCampaign", function () {
        
    })

    describe("refundDonation", function () {

    })*/
})