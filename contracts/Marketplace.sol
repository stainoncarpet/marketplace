//SPDX-License-Identifier: MIT

pragma solidity >=0.8.11 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is Ownable {
    uint256 public constant AUCTION_DURATION = 3 days;
    address public NFT;
    address public ERC20Token;

    event SaleCreated(uint256 tokenId, uint256 price);
    event SaleCanceled(uint256 tokenId);
    event SaleFinished(uint256 tokenId);
    event AuctionCreated(uint256 tokenId, uint256 minPrice);
    event AuctionCanceled(uint256 tokenId);
    event AuctionFinished(uint256 tokenId, uint256 price);

    enum Status {
        ONGOING, CANCELED, FINISHED
    }
    
    struct Auction {
        uint256 startedAt;
        address startedBy;
        uint256 highestBid;
        address highestBidder;
        uint256 bidsCount;
        Status status;
    }

    struct Sale {
        uint256 startedAt;
        address startedBy;
        uint256 price;
        Status status;
    }

    mapping(uint256 => Auction[]) public auctionsByTokenId;
    mapping(uint256 => Sale[]) public salesByTokenId;

    constructor(address _nft, address _erc20) {
        NFT = _nft;
        ERC20Token = _erc20;
    }

    modifier onlyOngoing(uint256 tokenId, string memory tradeType) {
        if(keccak256(abi.encodePacked(tradeType)) == keccak256(abi.encodePacked("auction"))) {
            Auction[] memory auctions = auctionsByTokenId[tokenId];
            Auction memory auction = auctions[auctions.length - 1];
            require(auction.status == Status.ONGOING, "Incorrect timing");
        } else if(keccak256(abi.encodePacked(tradeType)) == keccak256(abi.encodePacked("sale"))) {
            Sale[] memory sales = salesByTokenId[tokenId];
            Sale memory sale = sales[sales.length - 1];
            require(sale.status == Status.ONGOING, "Incorrect timing");
        }
        _;
    }

    modifier onlyValidTrade(uint256 tokenId, string memory tradeType) {
        if(keccak256(abi.encodePacked(tradeType)) == keccak256(abi.encodePacked("auction"))) {
            require(auctionsByTokenId[tokenId].length > 0, "Invalid token id");
        } else if(keccak256(abi.encodePacked(tradeType)) == keccak256(abi.encodePacked("sale"))) {
            require(salesByTokenId[tokenId].length > 0, "Invalid token id");
        }
        
        _;
    }

    function createItem(string memory tokenURI, address owner) external {
        mint(tokenURI, owner);
    }

    function mint(string memory tokenURI, address owner) private {
        NFT.call{value: 0}(abi.encodeWithSignature("mint(string,address)", tokenURI, owner));
    }

    function listItem(uint256 tokenId, uint256 price) external {
        NFT.call{value: 0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), tokenId));
        Sale memory sale = Sale({
            startedAt: block.timestamp,
            startedBy: msg.sender,
            price: price,
            status: Status.ONGOING
        });
        salesByTokenId[tokenId].push(sale);
        emit SaleCreated(tokenId, price);
    }

    //-Функция buyItem() - покупка предмета.
    function buyItem(uint256 tokenId) external onlyValidTrade(tokenId, "sale") onlyOngoing(tokenId, "sale") {
        Sale[] storage tokenSales = salesByTokenId[tokenId];
        Sale storage lastTokenSale = tokenSales[tokenSales.length - 1];
        NFT.call{value: 0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), msg.sender, tokenId));
        ERC20Token.call{value:0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, lastTokenSale.startedBy, lastTokenSale.price));
        lastTokenSale.status = Status.FINISHED;
        emit SaleFinished(tokenId);
    }

    //-Функция cancel() - отмена продажи выставленного предмета / функция отмены продажи NFT, может быть вызвана до момента buyitem
    function cancel(uint256 tokenId) external onlyValidTrade(tokenId, "sale") {
        Sale[] storage tokenSales = salesByTokenId[tokenId];
        Sale storage lastTokenSale = tokenSales[tokenSales.length - 1];
        require(lastTokenSale.status == Status.ONGOING, "Sale cannot be canceled");
        require(lastTokenSale.startedBy == msg.sender, "Only seller can cancel offering");

        NFT.call{value: 0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), lastTokenSale.startedBy, tokenId));
        lastTokenSale.status = Status.CANCELED;
        emit SaleCanceled(tokenId);
    }

    // AUCTION

    //-Функция listItemOnAuction() - выставка предмета на продажу в аукционе.
    /// функция маркетплейса для выставления ткена на аукцион
    /// на время проведения аукциона токен отправляется маркетплейсу
    function listItemOnAuction(uint256 tokenId, uint256 minPrice) external {
        Auction memory auction = Auction({        
            startedAt: block.timestamp,
            startedBy: msg.sender,
            highestBid: 0,
            highestBidder: address(0),
            bidsCount: 0,
            status: Status.ONGOING
        });
        auctionsByTokenId[tokenId].push(auction);
        NFT.call{value: 0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), tokenId));
        emit AuctionCreated(tokenId, minPrice);
    }

    // -Функция makeBid() - сделать ставку на предмет аукциона с определенным id.
    /// функция повышения ставки лота с tokenId
    /// с пользователя списываются токены и заморажиают на контракте
    //// если ставка не первая то предыдущему пользователю возвращаются его замороенные токены
    function makeBid(uint256 tokenId, uint256 price) external {
        require(tokenId < auctionsByTokenId[tokenId].length, "No auction with token found");
        Auction[] storage auctions = auctionsByTokenId[tokenId];
        Auction storage auction = auctions[auctions.length - 1];
        require(price > auction.highestBid, "New bid must be higher than current");
        require(auction.status == Status.ONGOING, "Auction has ended");

        if(auction.highestBid != 0 && auction.highestBidder == msg.sender) {
            revert();
        }

        ERC20Token.call{value:0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), price));

        if(auction.highestBid > 0) {
            ERC20Token.call{value:0}(abi.encodeWithSignature("transfer(address,uint256)", auction.highestBidder, auction.highestBid));
        }

        auction.highestBid = price;
        auction.highestBidder = msg.sender;
        auction.bidsCount += 1;
    }

    // //-Функция finishAuction() - завершить аукцион и отправить НФТ победителю
    //// NFT идет последнему биддеру, а токены продавцу
    function finishAuction(uint256 tokenId) external {
        Auction[] storage auctions = auctionsByTokenId[tokenId];
        Auction storage auction = auctions[auctions.length - 1];
        require(block.timestamp >= auction.startedAt + AUCTION_DURATION, "Too early to finish");

        // just declare auction as finished and return unsold nft to seller
        if(auction.bidsCount == 0) {
            NFT.call{value: 0}(abi.encodeWithSignature("transfer(address,uint256)", auction.startedBy, tokenId));
            auction.status = Status.FINISHED;
            emit AuctionFinished(tokenId, auction.highestBid);
        }
        // return everything to everybody
        else if(auction.bidsCount == 1) {
            ERC20Token.call{value:0}(abi.encodeWithSignature("transfer(address,uint256)", auction.highestBidder, auction.highestBid));
            NFT.call{value: 0}(abi.encodeWithSignature("transfer(address,uint256)", auction.startedBy, tokenId));
            auction.status = Status.FINISHED;
            emit AuctionFinished(tokenId, auction.highestBid);
        }
        // send resulted cnfigurations to both
        else {
            ERC20Token.call{value:0}(abi.encodeWithSignature("transfer(address,uint256)", auction.startedBy, auction.highestBid));
            NFT.call{value: 0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), auction.highestBidder, tokenId));
            auction.status = Status.FINISHED;
            emit AuctionFinished(tokenId, auction.highestBid);
        }
    }

    //-Функция cancelAuction() - отменить аукцион
    function cancelAuction(uint256 tokenId) external {
        Auction[] storage auctions = auctionsByTokenId[tokenId];
        Auction storage auction = auctions[auctions.length - 1];

        require(auction.startedBy == msg.sender, "Only auction owner can cancel it");
        require(block.timestamp >= auction.startedAt + AUCTION_DURATION, "Too early to cancel");
        auction.status = Status.CANCELED;

        if (auction.highestBid > 0) {
            ERC20Token.call{value:0}(abi.encodeWithSignature("transfer(address,uint256)", auction.highestBidder, auction.highestBid));
        }
        emit AuctionCanceled(tokenId);
    }

    function destroyContract() external onlyOwner {
        selfdestruct(payable(owner()));
    }

    //Аукцион длится 3 дня с момента старта аукциона. В течении этого срока аукцион не может быть отменен. 
    //В случае если по истечению срока набирается более двух ставок аукцион считается состоявшимся и создатель аукциона его завершает (НФТ переходит к последнему биддеру и токены создателю аукциона). 
    //В противном случае токены возвращаются последнему биддеру, а НФТ остается у создателя.
}
