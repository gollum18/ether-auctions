pragma solidity >= 0.4.22 <0.7.0;

import "./Auction.sol";

contract AuctionHouse {

  Auction[] private auctions;
  uint public totalAuctions;

  event AuctionCreated(Auction auction);

  constructor () public {
    totalAuctions = 0;
  }

  function createAuction (
    string memory item, 
    uint biddingTime, 
    address payable beneficiary
  ) public {
    Auction newAuction = new Auction(totalAuctions, item, biddingTime, beneficiary);
    auctions.push(newAuction);
    totalAuctions += 1;
    emit AuctionCreated(newAuction);
  }

  function getAuction(uint id) public view returns (Auction) {
    require (
      id >= 0 && id < totalAuctions,
      "Auction ID not valid!"
    );
    return auctions[id];
  }

}
