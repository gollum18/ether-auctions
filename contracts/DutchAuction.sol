pragma solidity >=0.4.22 <0.7.0;

contract DutchAuction {

    // Stores the address of the ether receiving entity
    address payable public beneficiary;
    // The auction ends if the reserve price is reached
    uint public auctionReservePrice;
    // The starting price of the auction
    uint public auctionStartPrice;
    
    // The amount of time in-between steps
    uint internal auctionStepTime;
    // The amount to decrease the price by with each step
    uint internal auctionStepAmount;
    // The next time for the price decrease
    uint internal nextDecreaseTime;
    
    // Current state of the auction
    uint public currentPrice;
    
    // Set to true at the end, disallows any change.
    bool ended;
    
    // Events that will be emitted on changes.
    event PriceLowered(uint newPrice);
    event AuctionEnded(address winner, uint amount);
    
    contract DutchAuction(
        uint _startingPrice,
        uint _reservePrice,
        uint _stepTime,
        uint _stepAmount,
        address _beneficiary
    ) public {
        beneficiary = _beneficiary;
        auctionStartPrice = _startingPrice;
        auctionReservePrice = _reservePrice;
        auctionStepTime = _stepTime;
        auctionStepAmount = _stepAmount;
        nextDecreaseTime = now + auctionStepTime;
    }
    
    function bid() public payable {
        require (
            ended == false,
            "Auction has ended."
        );
        
        require(
            msg.value >= currentPrice,
            "Current price not met."
        );
        
        ended = true;
        emit AuctionEnded(msg.sender, msg.value);
        beneficiary.transfer(msg.value);
    }
    
    function decreasePrice() public {
        require (
            ended == false,
            "Auction has ended."
        );
        require(
            now >= nextDecreaseTime,
            "Price decrease time not elapsed."
        );
        require (
            currentPrice > auctionReservePrice,
            "Current price already at auction reserve price."
        )
        // if we reached the end of the auction and no one bid at the 
        // reserve price, then end the auction
        if (currentPrice == auctionReservePrice && !ended) {
            ended = true;
        } else {
            if (currentPrice - auctionStepAmount < auctionReservePrice) {
                currentPrice = auctionReservePrice;
            } else {
                currentPrice -= auctionStepAmount;
            }
            nextDecreaseTime = now + auctionStepTime;
            emit PriceLowered(currentPrice);
        }
    }
}