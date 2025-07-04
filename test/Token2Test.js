const {expect} = require("chai");
const { ethers } = require("hardhat");

describe("Token2Test", function() {
    
    let Token2;  // deploy object
    let token2;  // contract object

    let owner;
    let addr1;
    let addr2;

    let address = [owner, addr1, addr2];  // three contract where deployed using DeploymentModule

    beforeEach(async function(){
        Token2 = await ethers.getContractFactory("Token2");
        token2 = await Token2.deploy();
        address = await ethers.getSigners();
    });

        it("testing decimalsToken2()", async function(){
        let result = await token2.decimals();
        expect(result).to.equal(18);
    });


    it("testing ownerToken2()", async function(){
        let result = await token2.owner();
        expect(result).to.equal(address[0]);
    });

    it("testing symbolToken2()", async function(){
        let result = await token2.symbol();
        expect(result).to.equal("TK2");
    });

    it("testing mintToken2()", async function(){
        const addr = address[0];
        const premint = (await token2.balanceOf(addr)); //minted to owner whem deployed
        const amount = ethers.parseEther("9999987655220000000000000000000");
        await token2.mint(addr, amount);
        let result = (await token2.balanceOf(addr));
        expect(result).to.equal(amount + premint);
    });

});