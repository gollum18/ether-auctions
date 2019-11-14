pragma solidity >= 0.4.22 <0.7.0;

contract Auction {
  uint public auctionID;
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
    uint _auctionID,
    string memory _item,
    uint _biddingTime,
    address payable _beneficiary
  ) public {
    auctionID = _auctionID;
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
