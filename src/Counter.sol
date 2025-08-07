// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract AuctionApplication {
    address public owner;
    mapping(address => uint256) public bids;
    address[] public bidderAddresses;
    uint256 public highestBid;
    uint256 public minBid;

    enum State {
        pending,
        started,
        paused,
        cancelled,
        ended
    }

    State internal state;

    constructor() {
        owner = msg.sender;
        state = State.pending;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "You are not the owner");
        _;
    }

    modifier onlyBidder() {
        require(owner != msg.sender, "You are not a Bidder");
        _;
    }

    function setMinimumBid(uint256 _minBid) private onlyOwner {
        minBid = _minBid;
    }

    function startAuction() public onlyOwner {
        require(state == State.pending, "Auction is already started");
        state = State.started;
        setMinimumBid(1);
    }

    function pauseAuction() public onlyOwner {
        require(state == State.started, "Auction has already stopped");
        state = State.paused;
    }

    function endAuction() public onlyOwner {
        require(
            state != State.ended &&
                state != State.cancelled &&
                state != State.pending,
            "Auction has already stopped"
        );
        state = State.ended;
    }

    function cancelAuction() public onlyOwner {
        state = State.cancelled;
        for (uint i = 0; i < bidderAddresses.length; i++) {
            if (bids[bidderAddresses[i]] > 0) {
                payable(bidderAddresses[i]).transfer(bids[bidderAddresses[i]]);
                bids[bidderAddresses[i]] = 0;
            }
        }
        bidderAddresses = new address[](0);
    }

    function offerBid() public payable onlyBidder {
        require(msg.value > minBid, "Bid is lower than minimum");
        bids[msg.sender] = msg.value;
        bidderAddresses.push(msg.sender);

        if (bidderAddresses.length == 1) {
            highestBid = msg.value;
        } else {
            for (uint i = 0; i < bidderAddresses.length; i++) {
                if (bids[bidderAddresses[i]] > highestBid) {
                    highestBid = bids[bidderAddresses[i]];
                }
            }
        }
    }

    function withdrawBid() public onlyBidder {
        require(state != State.ended, "You can't withdraw, Auction has ended");
        for (uint i = 0; i < bidderAddresses.length; i++) {
            if (bidderAddresses[i] == msg.sender) {
                if (bids[msg.sender] > 0) {
                    payable(msg.sender).transfer(bids[msg.sender]);
                    bids[msg.sender] = 0;
                }
                break;
            }
        }
    }
}
