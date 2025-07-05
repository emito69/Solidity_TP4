const {expect} = require("chai");
const { ethers } = require("hardhat");
const { deployProject } = require("@nomicfoundation/hardhat-ignition/modules");

describe("SimpleSwap", function() {
    // Contract instances
    let SimpleSwap
    let Token1;
    let Token2;
    let simpleswap;
    let token1;
    let token2;
    
    // Signers
    let owner;
    let addr1;
    let addr2;
    let addrs;

    // Signers
    let token1Address;
    let token2Address;
    let simpleswapAddress;

    let amountInR;
    let amountOutR;


    beforeEach(async function() {
        // Get signers
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

        // Deploy Token1 using ethers.js
        Token1 = await ethers.getContractFactory("Token1");
        token1 = await Token1.deploy();
        await token1.waitForDeployment();
        token1Address = await token1.getAddress();

        // Deploy Token2 using ethers.js
        Token2 = await ethers.getContractFactory("Token2");
        token2 = await Token2.deploy();
        await token2.waitForDeployment();
        token2Address = await token2.getAddress();

        // Deploy SimpleSwap with token addresses
        SimpleSwap = await ethers.getContractFactory("SimpleSwap");
        simpleswap = await SimpleSwap.deploy();
        await simpleswap.waitForDeployment();
        simpleswapAddress = await simpleswap.getAddress();

        // Log addresses for debugging
        console.log("Token1 address:", token1Address);
        console.log("Token2 address:", token2Address);
        console.log("SimpleSwap address:", simpleswapAddress);
    });

    it("testing getAmountOut()", async function() {
        const amountIn = ethers.parseEther("999998765522");
        const reserveIn = ethers.parseEther("99999876552200000000000000");
        const reserveOut = ethers.parseEther("7777777655220000000000000");
        const expected = ethers.parseEther("77777776552");
        const amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);   

        let result = await simpleswap.getAmountOut(amountIn, reserveIn, reserveOut);
        expect(result).to.equal(amountOut);
    });

    it("testing ownerSimpleSwap()", async function() {
        let result = await simpleswap.owner();
        expect(result).to.equal(owner);
    });

  
    it("should allow token swaps between Token1 and Token2", async function() {
        // Mint some tokens to SwapContract
        const mintAmount = ethers.parseEther("1000000000000000000");
        //await token1.mint(simpleswapAddress, mintAmount);
        //await token2.mint(simpleswapAddress, mintAmount);
        
        // Mint some tokens to owner
        await token1.mint(owner, mintAmount);
        await token2.mint(owner, mintAmount);

        // Mint some tokens to addr1
        await token1.mint(addr1, mintAmount);
        await token2.mint(addr1, mintAmount);

        // Mint some tokens to addr2
        await token1.mint(addr2, mintAmount);
        await token1.mint(addr2, mintAmount);
        
        // Approve SimpleSwap to spend tokens (the maximum)
        await token1.approve(simpleswapAddress, mintAmount);
        await token2.approve(simpleswapAddress, mintAmount);

        // Addresses input parameter array
        const addresssArray = [token1Address, token2Address];

        //const block = await ethers.provider.getBlock("latest");
        const deadline = 1000000001000000;
        
        // Add a Liquidity Pool
        const amountDesired = ethers.parseEther("50000000000000");
        const amountMin = ethers.parseEther("50000000");

        const tx = await simpleswap.addLiquidity(token1Address, token2Address, amountDesired, amountDesired, amountMin, amountMin, owner, deadline);
        // Wait for confirmation
        const receipt = await tx.wait();

        // The return values are in the receipt's events
        // Find the SwapExactTokensForTokens event in the logs
        const event = receipt.logs
            .map(log => {
                try {
                return simpleswap.interface.parseLog(log);
                } catch {
                return null;
                }
            })
            .find(e => e?.name === "AddLiquidity"); // Replace with your actual event name

        //console.log(event);
                        
        // Verify transaction success
        expect(receipt.status).to.equal(1);

        // Access emitted events
        //const event = receipt.events?.find(e => e.event === "AddLiquidity");

        //console.log(receipt.events);

        //const event2 = receipt.events?.find(e => e.event === "AddLiquidity");
  
        // Verify event was emitted
        expect(event).to.not.be.undefined;
        
        if (event) {
            // The amounts array is the last argument in the event
            const a1 = event.args.amountA;
            const a2 = event.args.amountB;
            const l1 = event.args.liquidity;

        } else {
            console.error("Event not found in transaction receipt");
        }
        
        
        
        // check Before
        const token2BalanceBefore = await token2.balanceOf(owner.getAddress());

        // Perform swap
        const swapAmountIn = ethers.parseEther("999999");
        const swapAmountOutMin = ethers.parseEther("10");
        const tx2  = await simpleswap.swapExactTokensForTokens(swapAmountIn, swapAmountOutMin, addresssArray, owner, deadline);

        // Wait for confirmation
        const receipt2 = await tx2.wait();
        
        // The return values are in the receipt's events
        // Find the SwapExactTokensForTokens event in the logs
        const event2 = receipt2.logs
            .map(log => {
                try {
                return simpleswap.interface.parseLog(log);
                } catch {
                return null;
                }
            })
            .find(e => e?.name === "SwapExactTokensForTokens"); // Replace with your actual event name

        expect(event2).to.not.be.undefined;
        // Access the amounts array
        const args = event2.args;
        const amounts = args.amounts;
        
        if (event2) {                   
 

        } else {
            console.error("Event not found in transaction receipt");
        }
        
        // check After
        const token2BalanceAfter = await token2.balanceOf(owner);
       
        expect(token2BalanceAfter).to.equal(BigInt(token2BalanceBefore)+BigInt(amounts[1]));
            
    });
  
    
});
