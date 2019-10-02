pragma solidity >=0.4.22 <0.7.0;

// Implements a ChanceAuction. In such an auction, participants buy
// relatively low cost tickets that increase their chance of winning the 
// auction. Generally the more tickets a participant owns, the higher their
// odds of winning the auction. This ChanceAuction currently only supports a
// single item. 
contract ChanceAuction {

    
    // Defines a Buyer that tracks payments made, ticket count, and buyer index
    struct Buyer {
        uint ticketsPurchased;  // the total amount of tickets the buyer holds
        uint payment;           // the total amount of ether the buyer has sent to the contract
        uint index;             // the index for the buyers address in the buyerAddresses array
    }

    // Parameters of the auction.
    address payable public beneficiary;
    uint public auctionEndTime;
    uint public auctionTicketPrice;
  
    // Stores the addresses of users who have purchased tickets
    address[] buyerAddresses;
    // Stores the number of tickets each person owns for each 
    // item in the auction.
    mapping(address => Buyer) buyers;
    
    // Stores Ether balances held for ticket purchases
    uint totalBalance;
    // Stores the total tickets purchased so far.
    uint totalTickets;
    
    // Determines whether the auction has ended or not.
    // When true, prevents future changes to the contract.
    bool ended;
    
    // Events that will be emitted on changes.
    event auctionEnded(address winner);
    
    /// Create a new ChanceAuction with the indicated `_biddingTime`
    /// and `_ticketPrice`. All payments for tickets will be sent to
    /// the `_beneficiary` at the end of the auction.
    constructor(
        uint _biddingTime,
        address payable _beneficiary,
        uint _ticketPrice,
    ) public {
        beneficiary = _beneficiary;
        auctionEndTime = now + _biddingTime;
        auctionTicketPrice = _ticketPrice;
    }
    
    /// Ends the action.
    function endAuction() public {
        require(
            ended == false,
            "Auction already ended."
        )
        
        // set the ended flag to prevent reentry
        ended = true;
        
        address highestTicketAddress;
        uint highestTickets = 0;
        address winner;
        bool winnerFound;
        uint chance;
        
        // WARNING: Looping in Solidity contracts consumes gas very quickly, keep the operations
        //  here simple
        for (uint i = 0; i < buyerAddresses.length; i++) {
            // This is a fallback in case no one was chosen to win the auction
            if (buyers[buyerAddresses[i]].ticketsPurchased > highestTickets) {
                highestTicketAddress = buyerAddresses[i];
                highestTickets = buyers[buyerAddresses[i]].ticketsPurchased;
            }
            // WARNING: Using this is a security hole, the address passed in its place should be 
            //  known only to the contract
            chance = uint(genNum(buyerAddresses.length, 3, address(this)) / buyerAddresses.length);
            if (chance < uint(buyers[buyerAddresses[i]].ticketsPurchased / totalTickets)) {
                winner = buyersAddresses[i];
                winnerFound = true;
                break;
            }
        }
        
        if (winnerFound == false) {
            winner  = highestTicketAddress;
        }
        
        emit AuctionEnded(winner);
        
        beneficiary.transfer(totalBalance);
    }
    
    /// Allows for purchasing a ticket. Tickets are refundable.
    function purchaseTicket() public payable returns (bool) {
        require(
            now <= auctionEndTime,
            "Auction already ended."
        );
        
        require(
            msg.value == auctionTicketPrice,
            "Payment must match ticket price."
        );
        
        require(
            msg.sender.balance >= auctionTicketPrice,
            "Balance not high enough to purchase a ticket."
        );
        
        // This should only execute for first time buyers, otherwise they fall into the else
        if (buyers[msg.sender].ticketsPurchased == 0) {
            buyers[msg.sender] = Buyer({
                ticketsPurchased: 1,
                payment: auctionTicketPrice, 
                index: buyerAddresses.push(msg.sender) - 1
            });
        } else {
            buyers[msg.sender].ticketsPurchased += 1;
            buyers[msg.sender].payment += auctionTicketPrice;
        }
        
        return true;
    }
    
    /// Refunds a single ticket purchased. The sender must have
    /// purchased at least a single ticket.
    function refundTicket() public returns (bool) {
        require(
            ended == false,
            "Auction already ended."
        );
        
        require(
            buyers[msg.sender].ticketsPurchased > 0,
            "No tickets purchased."
        )
        
        // Decrement the buyers ticket count and payment status
        buyers[msg.sender].ticketsPurchased -= 1;
        buyers[msg.sender].payment -= auctionTicketPrice;
        
        // Attempts to send the buyer their money back
        if (!msg.sender.send(auctionTicketPrice)) {
            buyers[msg.sender].ticketsPurchased += 1;
            buyers[msg.sender].payment += auctionTicketPrice;
            return false;
        }
        
        // Remove the buyer from the auction if their ticket count is zero
        if (buyers[msg.sender].ticketsPurchased == 0) {
            delete buyerAddresses[buyers[msg.sender].index];
        }
        
        return true;
    }
    
    // This function comes from Etheremon
    function getRandom(uint8 maxRan, uint8 index, address priAddress) constant public returns(uint8) {
        uint256 genNum = uint256(block.blockhash(block.number-1)) + uint256(priAddress);
        for (uint8 i = 0; i < index && i < 6; i++) {
            genNum /= 256;
        }
        return uint8(genNum % maxRan);
    }

}