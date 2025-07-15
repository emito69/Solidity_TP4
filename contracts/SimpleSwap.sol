// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LiquidityToken.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";


//@notice: A simple decentralized exchange contract for token swaps and liquidity provision
//@dev: Implements basic AMM functionality with liquidity pools and token swaps
contract SimpleSwap is Ownable {

/**** Data / Variables ***/

    //@notice: Tokens addresses to their IERC20 interface instances
    address private token1addr;
    address private token2addr;

    //@notice: Tokens ERC20 instances
    ERC20 private token1;
    ERC20 private token2;

    //@notice: Liquidity token contract instance
    LiquidityToken private liquidityToken;

    //@notice: Boolean to check First Pool initialziation // default `true` 
    bool private isNotLiquid = true; 

    //@notice: Temporary struct to avoid stack too deep errors and Multiple Access to State Variables
    //@dev: Contains various temporary variables used across functions
    struct TempStruct {  // needed to declare this struct to solve "CompilerError: Stack too deep." 
        bool isNotLiquid;
        address token1addr;
        address token2addr;
        ERC20  token1;
        ERC20  token2;
        LiquidityToken liquidityToken;
        bytes20 temp1;
        bytes20 temp2;
        uint256 reserveA;
        uint256 reserveB;
        uint256 ratio1;
        uint256 ratio2;
        uint256 liqTemp;
        uint256 amountA;
        uint256 amountB;
        
    }

    //@notice: Minimum liquidity amount to be locked in the contract
    uint256 MINIMUM_LIQUIDITY;

/****   Modifiers   *******/

/****   Events   *******/
    /**
     * @notice Emitted when liquidity is added to a pool
     * @dev Records the addition of liquidity to the pool
     * @param from The address providing the liquidity
     * @param to The address receiving the liquidity tokens
     * @param tokenA The first token in the pair
     * @param tokenB The second token in the pair
     * @param amountA The amount of tokenA added
     * @param amountB The amount of tokenB added
     * @param liquidity The amount of liquidity tokens minted
     */
    event AddLiquidity(address indexed from, address indexed to, address tokenA, address tokenB, uint amountA, uint amountB, uint liquidity);

    /**
     * @notice Emitted when liquidity is removed from a pool
     * @dev Records the removal of liquidity from the pool
     * @param from The address removing the liquidity
     * @param to The address receiving the underlying tokens
     * @param tokenA The first token in the pair
     * @param tokenB The second token in the pair
     * @param amountA The amount of tokenA received
     * @param amountB The amount of tokenB received
     */
    event RemoveLiquidity(address indexed from, address indexed to, address tokenA, address tokenB, uint amountA, uint amountB); 

    /**
     * @notice Emitted when a token swap occurs
     * @dev Records a token swap between two tokens in the pool
     * @param from The address initiating the swap
     * @param to The address receiving the swapped tokens
     * @param tokenA The input token
     * @param tokenB The output token
     * @param amounts An array containing the input amount and output amount
     */
    event SwapExactTokensForTokens(address indexed from, address indexed to, address tokenA, address tokenB, uint[] amounts); 

/****   CONSTRUCTOR   *******/

    //@notice: Initializes the contract with minimum liquidity requirement
    constructor() Ownable(msg.sender) {
        MINIMUM_LIQUIDITY = 1*(10**6);
    }

/**** EXTERNAL FUNCTIONS ****/

    // 1 - addLiquidity
    //@notice: Adds liquidity to a token pair pool
    //@dev: Handles both new and existing pools, calculates optimal amounts, mints liquidity tokens
    //@params: tokenA - First token address
    //@params: tokenB - Second token address
    //@params: amountADesired - Desired amount of tokenA to add
    //@params: amountBDesired - Desired amount of tokenB to add
    //@params: amountAMin - Minimum acceptable amount of tokenA
    //@params: amountBMin - Minimum acceptable amount of tokenB
    //@params: to - Address to receive liquidity tokens
    //@params: deadline - Transaction validity deadline
    //@returns: amountA - Actual amount of tokenA added
    //@returns: amountB - Actual amount of tokenB added
    //@returns: liquidity - Amount of liquidity tokens minted
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, 
                            uint amountAMin, uint amountBMin, address to, uint deadline) external 
                    returns (uint amountA, uint amountB, uint liquidity){
        
        require((block.timestamp <= deadline),"DEADLINE_PAST");
        require(tokenA != tokenB, "SAME_TOKENS");
        
        /// a) Initiate temp Variables
        TempStruct memory tempStruct;
        tempStruct.amountA = amountADesired;  // For new pools, uses exactly the amounts provided by the user
        tempStruct.amountB = amountBDesired;  // For new pools, uses exactly the amounts provided by the user

        // a1) Owner Adds initial Liquidity Pool
        if (isNotLiquid) {
            require(msg.sender == owner(), "POOL_NOT_INITIATED");

            tempStruct.token1addr = tokenA;
            tempStruct.token2addr = tokenB;
            tempStruct.token1 = ERC20(tokenA);
            tempStruct.token2 = ERC20(tokenB);
            tempStruct.liquidityToken = new LiquidityToken(address(this));
            
      
            // tempStruct.amountA = amountADesired;  // For new pools, uses exactly the amounts provided by the user - Already assigned
            // tempStruct.amountB = amountBDesired;  // For new pools, uses exactly the amounts provided by the user - Already assigned
                    // This sets the initial price ratio of the pool

            // Update State Variables
            isNotLiquid = false;   // initial pool liquidity finished
            token1addr = tempStruct.token1addr;
            token2addr = tempStruct.token2addr;
            token1 = tempStruct.token1;
            token2 = tempStruct.token2;
            liquidityToken = tempStruct.liquidityToken;

        /// a2) or Existing Pool Calculation 
        }else { 

            /// a) Initiate temp Variables
            tempStruct.token1addr = token1addr;
            tempStruct.token2addr = token2addr;           
            tempStruct.token1 = token1;  
            tempStruct.token2 = token2;  
            tempStruct.liquidityToken = liquidityToken;

            require(tokenA == tempStruct.token1addr, "ADDRESS_A_ERROR");
            require(tokenB == tempStruct.token2addr, "ADDRESS_B_ERROR");
            
            // a) Get Current Reserves
            tempStruct.reserveA = tempStruct.token1.balanceOf(address(this));
            tempStruct.reserveB = tempStruct.token2.balanceOf(address(this));

            // b) Calculate Proportional Amounts and Determine Best Ratio
            uint256 amountBProportional = _getProportionalValue(amountADesired, tempStruct.reserveA, tempStruct.reserveB);
            if (amountBProportional <= amountBDesired) {
                require(amountBProportional >= amountBMin, "INSUFF_B_AMOUNT"); // Slippage Protection
                tempStruct.amountA = amountADesired;
                tempStruct.amountB = amountBProportional;
            } else {
                uint amountAProportional = _getProportionalValue(amountBDesired, tempStruct.reserveB, tempStruct.reserveA);
                assert(amountAProportional <= amountADesired);
                require(amountAProportional >= amountAMin, "INSUFF_A_AMOUNT");  // Slippage Protection
                tempStruct.amountA = amountAProportional;
                tempStruct.amountB = amountBDesired;
            }
        }

        // c) Token Transfer
        
        // approve - already given by msg.sender
        // transfer
        bool statusA = _transferFrom(tempStruct.token1, msg.sender, address(this), tempStruct.amountA);
            if(!statusA){
                revert ("FAIL TRANSF TOKEN A");  
            }
        
        // approve - already given by msg.sender
        // transfer
        bool statusB = _transferFrom(tempStruct.token2, msg.sender, address(this), tempStruct.amountB);
            if(!statusB){
                revert ("FAIL TRANSF TOKEN B");  
            }

        // d) Calculate equivalent Liquidity Tokens
        if (tempStruct.liquidityToken.totalSupply() == 0) {
            // √(amountA * amountB) is the geometric mean of the deposited amounts
            // MINIMUM_LIQUIDITY is 1000 wei (burned to prevent division by zero)
            
            tempStruct.liquidityToken.mint(address(this), MINIMUM_LIQUIDITY); // initial Liquidity
            tempStruct.liqTemp = Math.sqrt(tempStruct.amountA*tempStruct.amountB) - MINIMUM_LIQUIDITY; // firts liquidity to emmmit
            
        }else {
            // min(amountA/reserveA, amountB/reserveB) * total L 
            tempStruct.ratio1 = (tempStruct.amountA * tempStruct.liquidityToken.totalSupply()) / tempStruct.reserveA;
            tempStruct.ratio2 = (tempStruct.amountB * tempStruct.liquidityToken.totalSupply()) / tempStruct.reserveB;

            if (tempStruct.ratio1 <= tempStruct.ratio2) {
                tempStruct.liqTemp = tempStruct.ratio1;
            } else{
                tempStruct.liqTemp = tempStruct.ratio2;
            }
        }
        
        // e) Mint Liquidity Tokens
        require(tempStruct.liqTemp > 0, "INSUFF_LIQUIDITY");
        tempStruct.liquidityToken.mint(to, tempStruct.liqTemp);


        /// a) Update State Variables
        token1 = tempStruct.token1;
        token2 = tempStruct.token2;
        liquidityToken = tempStruct.liquidityToken;

        // Emit Event AddLiquidity
        emit AddLiquidity(msg.sender, to, tempStruct.token1addr, tempStruct.token2addr, tempStruct.amountA, tempStruct.amountB, tempStruct.liqTemp);
        
        return (tempStruct.amountA, tempStruct.amountB, tempStruct.liqTemp);

    }

    // 2 - removeLiquidity
    //@notice: Removes liquidity from a token pair pool
    //@dev: Burns liquidity tokens and returns proportional amounts of both tokens
    //@params: tokenA - First token address
    //@params: tokenB - Second token address
    //@params: liquidity - Amount of liquidity tokens to burn
    //@params: amountAMin - Minimum acceptable amount of tokenA to receive
    //@params: amountBMin - Minimum acceptable amount of tokenB to receive
    //@params: to - Address to receive underlying tokens
    //@params: deadline - Transaction validity deadline
    //@returns: amountA - Actual amount of tokenA received
    //@returns: amountB - Actual amount of tokenB received
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external 
                        returns (uint amountA, uint amountB){
        require(isNotLiquid == false, "POOL_NOT_INITIATED"); //checks if the liquidity pool exists by looking at the pair's key
        require((block.timestamp <= deadline),"DEADLINE_PAST");
        require(tokenA != tokenB, "SAME_TOKENS");
        

        /// a) Initiate temp Variables
        TempStruct memory tempStruct;
        tempStruct.token1addr = token1addr;
        tempStruct.token2addr = token2addr;           
        tempStruct.token1 = token1;  
        tempStruct.token2 = token2;  
        tempStruct.liquidityToken = liquidityToken;

        require(tokenA == tempStruct.token1addr, "ADDRESS_A_ERROR");
        require(tokenB == tempStruct.token2addr, "ADDRESS_B_ERROR");
             
        // Sender needs to have Sufficient Liquidity to claim for it     
        require((liquidity <= tempStruct.liquidityToken.balanceOf(msg.sender)), "INSUFF_LIQUIDITY");


        /// b) Ammount Calculation 
        amountA = _getEffectiveLiquidOut(liquidity, tempStruct.token1, tempStruct.liquidityToken);
        require(amountA >= amountAMin, "TKA_<_Min");  
        amountB = _getEffectiveLiquidOut(liquidity, tempStruct.token2, tempStruct.liquidityToken);
        require(amountB >= amountBMin, "TKB_<_Min");  

        // c) Burn Tokens
        tempStruct.liquidityToken.burnFrom(msg.sender, liquidity);

        // d) Token Transfer
        // approve
        tempStruct.token1.approve(address(this), amountA);
        // transfer
        bool statusA = _transferFrom(tempStruct.token1, address(this), to, amountA);
        if(!statusA){
            revert ("FAIL_trasnf_TKA");  
        }

        // approve
        tempStruct.token2.approve(address(this), amountB);
        // transfer
        bool statusB = _transferFrom(tempStruct.token2, address(this), to, amountB);
        if(!statusB){
            revert ("FAIL_trasnf_TKB");  
        }

        /// a) Update State Variables
        token1 = tempStruct.token1;
        token2 = tempStruct.token2;
        liquidityToken = tempStruct.liquidityToken;
        
        // Emit RemoveLiquidity Event
        emit RemoveLiquidity(msg.sender, to, tokenA, tokenB, amountA, amountB); 

        return (amountA, amountB);
    }

    // 3 - swapExactTokensForTokens
    //@notice: Swaps an exact amount of tokens for another token
    //@dev: Implements constant product formula for price calculation
    //@params: amountIn - Exact amount of input tokens to swap
    //@params: amountOutMin - Minimum acceptable amount of output tokens
    //@params: path - Array of token addresses representing swap path
    //@params: to - Address to receive output tokens
    //@params: deadline - Transaction validity deadline
    //@returns: amounts - Array containing input and output amounts
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external 
                                returns (uint[] memory amounts){
        require((block.timestamp <= deadline),"DEADLINE_PAST");
        require(path[0] != path[1], "SAME_TOKENS");

        /// a) Initiate temp Variables
        TempStruct memory tempStruct;
        tempStruct.token1addr = token1addr;
        tempStruct.token2addr = token2addr;           
        tempStruct.token1 = token1;  
        tempStruct.token2 = token2;  
        tempStruct.liquidityToken = liquidityToken;

        address tokenA =path[0];
        address tokenB = path[1];

        require(tokenA == tempStruct.token1addr, "ADDRESS_A_ERROR");
        require(tokenB == tempStruct.token2addr, "ADDRESS_B_ERROR");
                   
        /// a2) Ammount Calculation 
        uint256 ammountOut = _getEffectiveAmountOut(amountIn, tempStruct.token1, tempStruct.token2);
        require(ammountOut >= amountOutMin, "TKB_<_Min");  

        // c) Token Transfer
        // approve - already given by msg.sender
        // transfer
        bool statusA = _transferFrom(tempStruct.token1, msg.sender, address(this), amountIn);
            if(!statusA){
                revert ("FAIL_trasnf_TKA");  
            }  

        // approve
        tempStruct.token2.approve(address(this), ammountOut);
        // transfer
        bool statusB = _transferFrom(tempStruct.token2, address(this), to, ammountOut);
            if(!statusB){
                revert ("FAIL_trasnf_TKB");  
            }

        uint256[] memory _amounts = new uint256[](2);
        _amounts[0]= amountIn;
        _amounts[1]= ammountOut;

        /// a) Update State Variables
        token1 = tempStruct.token1;
        token2 = tempStruct.token2;
        liquidityToken = tempStruct.liquidityToken;
        
        // Emit SwapExactTokensForTokens Event
        emit SwapExactTokensForTokens(msg.sender, to, tempStruct.token1addr, tempStruct.token2addr, _amounts); 

        return _amounts;
    }

    // 4 - getPrice
    //@notice: Gets the current price ratio between two tokens
    //@dev: Calculates spot price based on current reserves
    //@params: tokenA - First token address
    //@params: tokenB - Second token address
    //@returns: price - Current price of tokenA in terms of tokenB
    function getPrice(address tokenA, address tokenB) external view 
                returns (uint256 price){
        
        /// a) Initiate temp Variables
        TempStruct memory tempStruct;
        tempStruct.token1addr = token1addr;
        tempStruct.token2addr = token2addr;           
        tempStruct.token1 = token1;  
        tempStruct.token2 = token2;  

        require(tokenA == tempStruct.token1addr, "ADDRESS_A_ERROR");
        require(tokenB == tempStruct.token2addr, "ADDRESS_B_ERROR");
                
        //bool areTokens = (isToken[tokenA] && isToken[tokenB]);
        //require(areTokens, "Tokens address not existing in contract");
        price = ( 1e18 * tempStruct.token2.balanceOf(address(this)) )/ tempStruct.token1.balanceOf(address(this));  // Spot Price (Token A in terms of Token B) = reservesB/reservesA
        return price;  // * 1e18 required in the Verification COntract

    }

    // 5 - getAmountOut
    //@notice: Calculates output amount for a given input amount and reserves
    //@dev: Uses constant product formula (x*y=k)
    //@params: amountIn - Input amount
    //@params: reserveIn - Reserve amount of input token
    //@params: reserveOut - Reserve amount of output token
    //@returns: amountOut - Expected output amount
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure 
                    returns (uint256 amountOut){
        
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);   
        //amountOut = reserveOut - ((reserveIn * reserveOut) / (reserveIn + amountIn))   // equivalent formula
        return amountOut;
    }

/**** AUX FUNCTIONS ****/

    //@notice: Calculates effective output amount for a swap
    //@dev: Internal implementation of constant product formula
    //@params: _amountIn - Input amount
    //@params: _addressA - Input token address
    //@params: _addressB - Output token address
    //@returns: amountOut - Calculated output amount
    function _getEffectiveAmountOut(uint256 _amountIn, ERC20 _token1, ERC20 _token2) internal view
                    returns (uint256 amountOut){  
        amountOut = (_amountIn * _token2.balanceOf(address(this))) / (_token1.balanceOf(address(this)) + _amountIn);
        return amountOut;
    }

    //@notice: Calculates token amount to return when removing liquidity
    //@dev: Proportional to liquidity share and token reserves
    //@params: _liquidity - Amount of liquidity tokens being burned
    //@params: _token - Token address to calculate amount for
    //@params: _key - Token pair key
    //@returns: amountOut - Amount of token to return
    function _getEffectiveLiquidOut(uint256 _liquidity, ERC20 _token, LiquidityToken _liqToken) internal view
                    returns (uint256 amountOut){  
        // (senderLiquidity * tokenRESERVES ) / totalSUPPLyL 
        amountOut =( (_liquidity * _token.balanceOf(address(this)) ) / _liqToken.totalSupply() );
        return amountOut;
    }


    //@notice: Calculates proportional value for tokenB given tokenA amount and reserves
        // To maintain the proportion: amountA / amountB = reserveA / reserveB
    //@dev: Maintains reserve ratio when adding liquidity
        // Implement: (amountADesired * reserveB) / reserveA
    //@params: amountA - Amount of tokenA
    //@params: reserveA - Reserve amount of tokenA
    //@params: reserveB - Reserve amount of tokenB
    //@returns: proportionalValue - Calculated amount of tokenB
    function _getProportionalValue(uint amountA, uint reserveA, uint reserveB) internal pure
                            returns (uint256 proportionalValue){       
        require(amountA > 0, "INSUFF_AMOUNT_TKA");
        require(reserveA > 0 && reserveB > 0, "INSUFF_LIQUIDITY");
        proportionalValue = amountA * reserveB / reserveA;  // amountB
    }


    //@notice: Internal token transfer function
    //@dev: Wrapper for ERC20 transferFrom
    //@params: token - Token address
    //@params: _from - Sender address
    //@params: _to - Recipient address
    //@params: _amount - Transfer amount
    //@returns: status - Transfer success status
    function _transferFrom(ERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool status){ 
       return status = _token.transferFrom(_from, _to, _amount);
    }

}