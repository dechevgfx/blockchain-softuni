// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract AuctionPlatform {
    struct Auction {
        address creator;
        uint256 start;
        uint256 end;
        string name;
        string description;
        uint256 startingPrice;
        uint256 highestBid;
        bool isFinalized;
        address highestBidder;
    }

    uint256 public auctionId;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256))
        public availableToWithdrawal;

    event NewAuction(uint256 indexed auctionId);
    event NewHighestBid(uint256 id, uint256 bid, address bidder);

    modifier onlyActiveAuction(uint256 id) {
        // require(
        //     block.timestamp > auctions[id].start &&
        //         block.timestamp < auctions[id].end,
        //     "Not active auction"
        // );
        require(!auctions[id].isFinalized, "Auction is finalized");
        _;
    }

    function createAuction(
        uint256 start,
        uint256 end,
        string memory name,
        string memory description,
        uint256 startingPrice
    ) external {
        require(start > block.timestamp, "Auction has to start in the future");
        require(end > start, "Not a valid auction duration");

        auctionId++;

        auctions[auctionId] = Auction(
            msg.sender,
            start,
            end,
            name,
            description,
            startingPrice,
            0,
            false,
            address(0)
        );

        emit NewAuction(auctionId);
    }

    function placeBid(uint256 id) external payable onlyActiveAuction(id) {
        require(
            msg.value > auctions[id].startingPrice,
            "Bid must be bigger than the starting price"
        );
        require(msg.value > auctions[id].highestBid, "Not a valid bid");

        if (auctions[id].highestBidder != address(0)) {
            availableToWithdrawal[id][auctions[id].highestBidder] += auctions[
                id
            ].highestBid;
        }

        auctions[id].highestBid = msg.value;
        auctions[id].highestBidder = msg.sender;

        emit NewHighestBid(id, msg.value, msg.sender);
    }

    function finalizeBid(uint256 id) external {
        require(block.timestamp > auctions[id].end, "Auction is not ended");

        if (auctions[id].highestBid > 0) {
            payable(auctions[id].creator).transfer(auctions[id].highestBid);
        }

        auctions[id].isFinalized = true;
    }

    function withdraw(uint256 id) external {
        require(
            availableToWithdrawal[id][msg.sender] > 0,
            "User has nothing to withdraw"
        );

        uint256 amount = availableToWithdrawal[id][msg.sender];
        availableToWithdrawal[id][msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
