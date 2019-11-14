pragma solidity >= 0.4.22 <0.7.0;

contract Auction {
  string public item;
  address payable public beneficiary;
  address public highestBidder;
  uint public highestBid;
  uint public auctionEndTime;
  mapping(address => uint) pendingReturns;
  bool ended;

  event HighestBidIncreased(address bidder, uint amount);
  event AuctionEnded(address winner, uint amount);

  constructor (
    string memory _item,
    uint _biddingTime,
    address payable _beneficiary
  ) public {
    item = _item;
    beneficiary = _beneficiary;
    auctionEndTime = now + _biddingTime;
  }

  function bid() public payable {
    require(
      now <= auctionEndTime,
      "Auction already ended!"
    );

    require(
      msg.value > highestBid,
      "Bid not greater than highest bid!"
    );

    if (highestBid != 0) {
      pendingReturns[highestBidder] += highestBid;
    }

    highestBidder = msg.sender;
    highestBid = msg.value;
    emit HighestBidIncreased(msg.sender, msg.value);
  }

  function withdraw() public {
    require(
      now >= auctionEndTime,
      "Auction has not ended yet!"
    );
    
    require(
      !ended,
      "Auction has already been called!"
    );

    ended = true;
    emit AuctionEnded(highestBidder, highestBid);

    beneficiary.transfer(highestBid);
  }
}

contract AuctionHouse {

  Auction[] private auctions;
  uint private auctionTracker;

  event AuctionCreated(uint auctionID, address beneficiary, uint auctionEndTime, string item);

  constructor () public {
    auctionTracker = 0;
  }

  function createAuction (
    string memory item, 
    uint biddingTime, 
    address payable beneficiary
  ) public {
    Auction newAuction = new Auction(item, biddingTime, beneficiary);
    auctions.push(newAuction);
    auctionTracker += 1;
    emit AuctionCreated(
      auctionTracker - 1, 
      newAuction.beneficiary(),
      newAuction.auctionEndTime(),
      newAuction.item()
    );
  }

  function getAuction(uint id) public view returns (Auction) {
    require (
      id >= 0 && id < auctionTracker,
      "Auction ID not valid!"
    );
    return auctions[id];
  }

  function getTotalAuctions() public view returns (uint) {
    return auctionTracker - 1;
  }

}
