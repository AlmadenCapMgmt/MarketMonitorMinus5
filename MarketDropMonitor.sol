// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import “@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol”;

/**

- @title MarketDropMonitor
- @dev Smart contract that monitors S&P 500 and Dow Jones for 5%+ daily drops
- Uses Chainlink price feeds for reliable market data
  */
  contract MarketDropMonitor {
  // Chainlink price feed interfaces
  AggregatorV3Interface internal spPriceFeed;
  AggregatorV3Interface internal dowPriceFeed;
  
  // Contract owner
  address public owner;
  
  // Tracking variables
  struct DailyPrice {
  int256 openPrice;
  int256 currentPrice;
  uint256 lastUpdate;
  bool dropEventEmitted;
  }
  
  mapping(string => DailyPrice) public dailyPrices;
  
  // Events
  event MarketDrop(
  string indexed market,
  int256 openPrice,
  int256 currentPrice,
  int256 dropPercentage,
  uint256 timestamp
  );
  
  event PriceUpdate(
  string indexed market,
  int256 price,
  uint256 timestamp
  );
  
  // Constants
  int256 constant DROP_THRESHOLD = -500; // -5.00% (basis points * 100)
  uint256 constant SECONDS_IN_DAY = 86400;
  
  // Modifiers
  modifier onlyOwner() {
  require(msg.sender == owner, “Only owner can call this function”);
  _;
  }
  
  constructor() {
  owner = msg.sender;
  
  ```
   // Mainnet Chainlink price feeds
   // S&P 500: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
   // Dow Jones: Replace with actual Dow feed address when available
   spPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
   // Note: You'll need to find the correct Dow Jones feed address
   // dowPriceFeed = AggregatorV3Interface(0x...);
  ```
  
  }
  
  /**
  - @dev Get latest price from Chainlink feed
    */
    function getLatestPrice(string memory market) public view returns (int256) {
    AggregatorV3Interface priceFeed;
    
    if (keccak256(bytes(market)) == keccak256(bytes(“SP500”))) {
    priceFeed = spPriceFeed;
    } else if (keccak256(bytes(market)) == keccak256(bytes(“DOW”))) {
    priceFeed = dowPriceFeed;
    } else {
    revert(“Invalid market”);
    }
    
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return price;
    }
  
  /**
  - @dev Initialize daily tracking - should be called at market open
    */
    function initializeDailyTracking(string memory market) external {
    int256 currentPrice = getLatestPrice(market);
    
    // Check if it’s a new day or first initialization
    if (block.timestamp - dailyPrices[market].lastUpdate > SECONDS_IN_DAY) {
    dailyPrices[market] = DailyPrice({
    openPrice: currentPrice,
    currentPrice: currentPrice,
    lastUpdate: block.timestamp,
    dropEventEmitted: false
    });
    
    ```
     emit PriceUpdate(market, currentPrice, block.timestamp);
    ```
    
    }
    }
  
  /**
  - @dev Update current price and check for 5% drop
    */
    function updatePrice(string memory market) external {
    require(dailyPrices[market].openPrice != 0, “Daily tracking not initialized”);
    
    int256 currentPrice = getLatestPrice(market);
    dailyPrices[market].currentPrice = currentPrice;
    dailyPrices[market].lastUpdate = block.timestamp;
    
    emit PriceUpdate(market, currentPrice, block.timestamp);
    
    // Check for 5% drop
    checkForDrop(market);
    }
  
  /**
  - @dev Internal function to check for 5% drop and emit event
    */
    function checkForDrop(string memory market) internal {
    DailyPrice storage dayData = dailyPrices[market];
    
    // Skip if drop event already emitted today
    if (dayData.dropEventEmitted) {
    return;
    }
    
    // Calculate percentage change
    int256 priceDiff = dayData.currentPrice - dayData.openPrice;
    int256 percentageChange = (priceDiff * 10000) / dayData.openPrice; // Basis points
    
    // Check if drop exceeds threshold
    if (percentageChange <= DROP_THRESHOLD) {
    dayData.dropEventEmitted = true;
    
    ```
     emit MarketDrop(
         market,
         dayData.openPrice,
         dayData.currentPrice,
         percentageChange,
         block.timestamp
     );
    ```
    
    }
    }
  
  /**
  - @dev Get current day’s price data
    */
    function getDailyPriceData(string memory market)
    external
    view
    returns (int256 openPrice, int256 currentPrice, uint256 lastUpdate, bool dropEventEmitted)
    {
    DailyPrice memory dayData = dailyPrices[market];
    return (dayData.openPrice, dayData.currentPrice, dayData.lastUpdate, dayData.dropEventEmitted);
    }
  
  /**
  - @dev Calculate current percentage change
    */
    function getCurrentDropPercentage(string memory market) external view returns (int256) {
    DailyPrice memory dayData = dailyPrices[market];
    require(dayData.openPrice != 0, “Daily tracking not initialized”);
    
    int256 priceDiff = dayData.currentPrice - dayData.openPrice;
    return (priceDiff * 10000) / dayData.openPrice; // Returns in basis points
    }
  
  /**
  - @dev Reset daily tracking - useful for testing or manual reset
    */
    function resetDailyTracking(string memory market) external onlyOwner {
    delete dailyPrices[market];
    }
  
  /**
  - @dev Update price feed address (owner only)
    */
    function updatePriceFeed(string memory market, address newFeedAddress) external onlyOwner {
    if (keccak256(bytes(market)) == keccak256(bytes(“SP500”))) {
    spPriceFeed = AggregatorV3Interface(newFeedAddress);
    } else if (keccak256(bytes(market)) == keccak256(bytes(“DOW”))) {
    dowPriceFeed = AggregatorV3Interface(newFeedAddress);
    } else {
    revert(“Invalid market”);
    }
    }
  
  /**
  - @dev Emergency function to transfer ownership
    */
    function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), “New owner cannot be zero address”);
    owner = newOwner;
    }
    }
