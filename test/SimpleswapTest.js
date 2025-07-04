const {expect} = require("chai");
const { ethers } = require("hardhat");

describe("SimpleSwap", function() {
    
    let Simpleswap;  // deploy object
    let simpleswap;  // contract object

    let owner;
    let addr1;
    let addr2;

    let address = [owner, addr1, addr2];  // three contract where deployed using DeploymentModule

        
    beforeEach(async function(){
        Simpleswap = await ethers.getContractFactory("SimpleSwap");
        simpleswap = await Simpleswap.deploy();
        address = await ethers.getSigners();
    });

    
    it("testing getAmountOut()", async function(){
        const amountIn = ethers.parseEther("999998765522");
        const reserveIn = ethers.parseEther("99999876552200000000000000");
        const reserveOut = ethers.parseEther("7777777655220000000000000");
        const expected = ethers.parseEther("77777776552");
        const amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);   

        let result = await simpleswap.getAmountOut(amountIn, reserveIn, reserveOut);

        expect(result).to.equal(amountOut);
    });


    it("testing ownerSimpleSwap()", async function(){
        let result = await simpleswap.owner();
        expect(result).to.equal(address[0]);
    });
   


});
