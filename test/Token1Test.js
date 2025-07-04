const {expect} = require("chai");
const { ethers } = require("hardhat");

describe("SimpleSwap", function() {
    
    let Token1;  // deploy object
    let token1;  // contract object

    let owner;
    let addr1;
    let addr2;

    let address = [owner, addr1, addr2];  // three contract where deployed using DeploymentModule

    beforeEach(async function(){
        Token1 = await ethers.getContractFactory("Token1");
        token1 = await Token1.deploy();
        address = await ethers.getSigners();
    });


    it("testing decimalsToken1()", async function(){
        let result = await token1.decimals();
        expect(result).to.equal(18);
    });


    it("testing ownerToken1()", async function(){
        let result = await token1.owner();
        expect(result).to.equal(address[0]);
    });

    it("testing symbolToken1()", async function(){
        let result = await token1.symbol();
        expect(result).to.equal("TK1");
    });

    it("testing mintToken1()", async function(){
        const addr = address[0];
        const premint = (await token1.balanceOf(addr)); //minted to owner whem deployed
        const amount = ethers.parseEther("9999987655220000000000000000000");
        await token1.mint(addr, amount);
        let result = (await token1.balanceOf(addr));
        expect(result).to.equal(amount + premint);
    });



});