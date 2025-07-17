// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title SimpleSwap
 * @notice A simplified decentralized exchange contract for token swaps and liquidity provision
 * @dev Implements basic swap functionality and liquidity pool management
 */
contract SimpleSwap is ERC20, Ownable {

/**** Data / Variables ***/

    /**
     * @notice Address of the first token in the trading pair
     */
    address private token1addr;
    
    /**
     * @notice Address of the second token in the trading pair
     */
    address private token2addr;

    /**
     * @notice Temporary struct to avoid stack too deep errors and Multiple Access to State Variables
     * @dev Contains various temporary variables used across functions
     */
    struct TempStruct {  
        uint256 ratio1;
        uint256 ratio2;
        uint256 liqTemp;
        uint256 reserveA; 
        uint256 reserveB; 
        bool statusA;
        bool statusB;
    }

    /**
     * @notice Minimum liquidity amount to be locked in the contract
     * @dev Prevents division by zero in initial pool setup
     */
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

    /**
     * @notice Initializes the contract with minimum liquidity requirement
     * @dev Sets the name and symbol for liquidity tokens and initializes owner
     */
    constructor() ERC20 ("SimpleSwap Liquidity Token", "SSL") Ownable(msg.sender) {
        MINIMUM_LIQUIDITY = 1*(10**6);
    }

/**** EXTERNAL FUNCTIONS ****/

    /**
     * @notice Adds liquidity to a token pair pool
     * @dev Handles both new and existing pools, calculates optimal amounts, mints liquidity tokens
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param amountADesired Desired amount of tokenA to add
     * @param amountBDesired Desired amount of tokenB to add
     * @param amountAMin Minimum acceptable amount of tokenA
     * @param amountBMin Minimum acceptable amount of tokenB
     * @param to Address to receive liquidity tokens
     * @param deadline Transaction validity deadline
     * @return amountA Actual amount of tokenA added
     * @return amountB Actual amount of tokenB added
     * @return liquidity Amount of liquidity tokens minted
     */
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, 
                            uint amountAMin, uint amountBMin, address to, uint deadline) external 
                    returns (uint amountA, uint amountB, uint liquidity){
        
        require((block.timestamp <= deadline),"DEADLINE_PAST");
        require(tokenA != tokenB, "SAME_TOKENS");
        
        /// a) Initiate temp Variables
        TempStruct memory tempStruct;
        amountA = amountADesired;  // For new pools, uses exactly the amounts provided by the user
        amountB = amountBDesired;  // For new pools, uses exactly the amounts provided by the user

        // a1) Owner Adds initial Liquidity Pool
        if (totalSupply() == 0) {
            require(msg.sender == owner(), "POOL_NOT_INIT");

            token1addr = tokenA;
            token2addr = tokenB;
            
            // This sets the initial price ratio of the pool
            // amountA = amountADesired;  // For new pools, uses exactly the amounts provided by the user - Already assigned
            // amountB = amountBDesired;  // For new pools, uses exactly the amounts provided by the user - Already assigned

        /// a2) or Existing Pool Calculation 
        }else { 

            require(tokenA == token1addr, "ADDR_A_ERROR");
            require(tokenB == token2addr, "ADDR_B_ERROR");
            
            // a) Get Current Reserves
            tempStruct.reserveA = ERC20(tokenA).balanceOf(address(this));
            tempStruct.reserveB = ERC20(tokenB).balanceOf(address(this));

            // b) Calculate Proportional Amounts and Determine Best Ratio
            (amountA, amountB) = _calculateOptimalAmounts(amountADesired, amountBDesired, amountAMin, amountBMin, tempStruct.reserveA, tempStruct.reserveB);
        }

        // c) Token Transfer
        
        // approve - already given by msg.sender
        // transfer
        tempStruct.statusA =  ERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
            if(!tempStruct.statusA){
                revert ("FAIL_TRANSF_TKA");  
            }
        
        // approve - already given by msg.sender
        // transfer
        tempStruct.statusB = ERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
            if(!tempStruct.statusB){
                revert ("FAIL_TRANSF_TKB");  
            }

        // d) Calculate equivalent Liquidity Tokens
        if (totalSupply() == 0) {
            // √(amountA * amountB) is the geometric mean of the deposited amounts
            // MINIMUM_LIQUIDITY is 1000 wei (burned to prevent division by zero)
            _mint(address(this), MINIMUM_LIQUIDITY); // initial Liquidity
            tempStruct.liqTemp = Math.sqrt(amountA*amountB) - MINIMUM_LIQUIDITY; // firts liquidity to emmmit
            
        }else {

            tempStruct.liqTemp = _calculateLiquidity(amountA, amountB, tempStruct);
        }
        
        // e) Mint Liquidity Tokens
        require(tempStruct.liqTemp > 0, "INSUFF_LIQ");
        _mint(to, tempStruct.liqTemp);

        // Emit Event AddLiquidity
        emit AddLiquidity(msg.sender, to, tokenA, tokenB, amountA, amountB, tempStruct.liqTemp);
        
        return (amountA, amountB, tempStruct.liqTemp);

    }

    /**
     * @notice Removes liquidity from a token pair pool
     * @dev Burns liquidity tokens and returns proportional amounts of both tokens
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param liquidity Amount of liquidity tokens to burn
     * @param amountAMin Minimum acceptable amount of tokenA to receive
     * @param amountBMin Minimum acceptable amount of tokenB to receive
     * @param to Address to receive underlying tokens
     * @param deadline Transaction validity deadline
     * @return amountA Actual amount of tokenA received
     * @return amountB Actual amount of tokenB received
     */
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external 
                        returns (uint amountA, uint amountB){
        require((block.timestamp <= deadline),"DEADLINE_PAST");
        require(totalSupply() > 0, "POOL_NOT_INIT"); //checks if the liquidity pool exists by looking at the pair's key
        require(tokenA == token1addr, "ADDR_A_ERROR");
        require(tokenB == token2addr, "ADDR_B_ERROR");    

       
        // Sender needs to have Sufficient Liquidity to claim for it     
        require((liquidity <= balanceOf(msg.sender)), "INSUFF_LIQ");

        /// b) Ammount Calculation 
        amountA = _getEffectiveLiquidOut(liquidity, tokenA, totalSupply());
        require(amountA >= amountAMin, "TKA_<_Min");  
        amountB = _getEffectiveLiquidOut(liquidity, tokenB, totalSupply());
        require(amountB >= amountBMin, "TKB_<_Min");  

        // c) Burn Tokens
        _burn(msg.sender, liquidity);

        // d) Token Transfer
        // approve
        ERC20(tokenA).approve(address(this), amountA);
        // transfer
        bool statusA = ERC20(tokenA).transferFrom(address(this), to, amountA);
        if(!statusA){
            revert ("FAIL_TRANF_TKA");  
        }

        // approve
        ERC20(tokenB).approve(address(this), amountB);
        // transfer
        bool statusB = ERC20(tokenB).transferFrom(address(this), to, amountB);
        if(!statusB){
            revert ("FAIL_TRANF_TKB");  
        }
        
        // Emit RemoveLiquidity Event
        emit RemoveLiquidity(msg.sender, to, tokenA, tokenB, amountA, amountB); 

        return (amountA, amountB);
    }

    /**
     * @notice Swaps an exact amount of tokens for another token
     * @dev Implements constant product formula for price calculation
     * @param amountIn Exact amount of input tokens to swap
     * @param amountOutMin Minimum acceptable amount of output tokens
     * @param path Array of token addresses representing swap path
     * @param to Address to receive output tokens
     * @param deadline Transaction validity deadline
     * @return amounts Array containing input and output amounts
     */
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external 
                                returns (uint[] memory amounts){
        require((block.timestamp <= deadline),"DEADLINE_PAST");
        require(totalSupply()> 0, "POOL_NOT_INIT"); //checks if the liquidity pool exists by looking at the pair's key
        require(path[0] == token1addr, "ADDR_A_ERROR");
        require(path[1] == token2addr, "ADDR_B_ERROR");      

        /// a1) Initiate temp Variables
        address tokenA =path[0];
        address tokenB = path[1];       
                   
        /// a2) Ammount Calculation 
        uint256 ammountOut = _getEffectiveAmountOut(amountIn, tokenA, tokenB);
        require(ammountOut >= amountOutMin, "TKB_<_Min");  

        // c) Token Transfer
        // approve - already given by msg.sender
        // transfer
        bool statusA = ERC20(tokenA).transferFrom(msg.sender, address(this), amountIn);
            if(!statusA){
                revert ("FAIL_TRANF_TKA");  
            }  

        // approve
        ERC20(tokenB).approve(address(this), ammountOut);
        // transfer
        bool statusB = ERC20(tokenB).transferFrom(address(this), to, ammountOut);
            if(!statusB){
                revert ("FAIL_TRANF_TKB");  
            }

        uint256[] memory _amounts = new uint256[](2);
        _amounts[0]= amountIn;
        _amounts[1]= ammountOut;
        
        // Emit SwapExactTokensForTokens Event
        emit SwapExactTokensForTokens(msg.sender, to, tokenA, tokenB, _amounts); 

        return _amounts;
    }

    /**
     * @notice Gets the current price ratio between two tokens
     * @dev Calculates spot price based on current reserves
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return price Current price of tokenA in terms of tokenB
     */
    function getPrice(address tokenA, address tokenB) external view 
                returns (uint256 price){
        require(tokenA == token1addr, "ADD_A_ERR");
        require(tokenB == token2addr, "ADD_B_ERR");    
                
        // Spot Price (Token A in terms of Token B) = reservesB/reservesA
        price = ( 1e18 * ERC20(tokenB).balanceOf(address(this)) )/ ERC20(tokenA).balanceOf(address(this));  
        return price;  // * 1e18 required in the Verification COntract

    }

    /**
     * @notice Calculates output amount for a given input amount and reserves
     * @dev Uses constant product formula (x*y=k)
     * @param amountIn Input amount
     * @param reserveIn Reserve amount of input token
     * @param reserveOut Reserve amount of output token
     * @return amountOut Expected output amount
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure 
                    returns (uint256 amountOut){
        
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);   
        //amountOut = reserveOut - ((reserveIn * reserveOut) / (reserveIn + amountIn))   // equivalent formula
        return amountOut;
    }

/**** AUX FUNCTIONS ****/

    /**
     * @notice Internal function to calculate effective output amount for a swap
     * @dev Uses constant product formula
     * @param _amountIn Input amount
     * @param _token1 Input token address
     * @param _token2 Output token address
     * @return amountOut Calculated output amount
     */
    function _getEffectiveAmountOut(uint256 _amountIn, address _token1, address _token2) internal view
                    returns (uint256 amountOut){  
        amountOut = (_amountIn * ERC20(_token2).balanceOf(address(this))) / (ERC20(_token1).balanceOf(address(this)) + _amountIn);
        return amountOut;
    }

    /**
     * @notice Internal function to calculate effective liquidity output when removing liquidity
     * @dev Calculates proportional share of reserves
     * @param _liquidity Amount of liquidity tokens being burned
     * @param _token Token address to calculate output for
     * @param _swapLiquidity Total liquidity supply
     * @return amountOut Calculated token output amount
     */
    function _getEffectiveLiquidOut(uint256 _liquidity, address _token, uint256 _swapLiquidity) internal view
                    returns (uint256 amountOut){  
        // (senderLiquidity * tokenRESERVES ) / totalSUPPLyL 
        amountOut =( (_liquidity * ERC20(_token).balanceOf(address(this)) ) / _swapLiquidity);
        return amountOut;
    }

    /**
     * @notice Internal function to calculate liquidity tokens to mint
     * @dev Uses minimum of two ratios to determine fair liquidity amount
     * @param amountA Amount of tokenA being added
     * @param amountB Amount of tokenB being added
     * @param tempStruct Temporary storage struct with current reserves
     * @return Calculated liquidity token amount
     */
    function _calculateLiquidity(uint256 amountA, uint256 amountB, TempStruct memory tempStruct) internal view returns (uint256) {
        // min(amountA/reserveA, amountB/reserveB) * total L 
        tempStruct.ratio1 = (amountA * totalSupply()) / tempStruct.reserveA;
        tempStruct.ratio2 = (amountB * totalSupply()) / tempStruct.reserveB;

        return tempStruct.ratio1 <= tempStruct.ratio2 ? tempStruct.ratio1 : tempStruct.ratio2;
    }

    /**
     * @notice Internal function to calculate proportional value
     * @dev Used for determining optimal deposit amounts
     * @param amountA Input amount
     * @param reserveA Reserve of tokenA
     * @param reserveB Reserve of tokenB
     * @return proportionalValue Calculated proportional amount
     */
    function _getProportionalValue(uint amountA, uint reserveA, uint reserveB) internal pure
                            returns (uint256 proportionalValue){       
        require(amountA > 0, "INSUF_AMOUNT_TKA");
        require(reserveA > 0 && reserveB > 0, "INSUFF_LIQ");
        proportionalValue = amountA * reserveB / reserveA;  // amountB
    }

    /**
     * @notice Internal function to calculate optimal deposit amounts
     * @dev Ensures deposits maintain pool ratio with minimal slippage
     * @param amountADesired Desired amount of tokenA
     * @param amountBDesired Desired amount of tokenB
     * @param amountAMin Minimum acceptable amount of tokenA
     * @param amountBMin Minimum acceptable amount of tokenB
     * @param reserveA Current reserve of tokenA
     * @param reserveB Current reserve of tokenB
     * @return amountA Optimal amount of tokenA to deposit
     * @return amountB Optimal amount of tokenB to deposit
     */
    function _calculateOptimalAmounts(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountA, uint256 amountB) {
        uint amountBProportional = _getProportionalValue(amountADesired, reserveA, reserveB);
        
        if (amountBProportional <= amountBDesired) {
            require(amountBProportional >= amountBMin, "INSUF_B_AMOUNT"); // Slippage Protection
            return (amountADesired, amountBProportional);
        } else {
            uint256 amountAProportional = _getProportionalValue(amountBDesired, reserveB, reserveA);
            assert(amountAProportional <= amountADesired);
            require(amountAProportional >= amountAMin, "INSUF_A_AMOUNT"); // Slippage Protection
            return (amountAProportional, amountBDesired);
        }
    }
}