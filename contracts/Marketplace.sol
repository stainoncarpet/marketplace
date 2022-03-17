//SPDX-License-Identifier: MIT

pragma solidity >=0.8.11 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Marketplace is Ownable {
    uint256 public constant AUCTION_DURATION = 3 days;
    address public NFT;
    address public ERC20Token;

    event SaleCreated();
    event SaleCanceled();
    event SaleFinished();
    event AuctionCreated();
    event AuctionCanceled();
    event AuctionFinished();

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

    modifier onlyOngoing(uint256 tokenId) {
        require(condition);
        _;
    }

    modifier onlyValidSale(uint256 tokenId) {
        require(salesByTokenId[tokenId].length > 0, "Invalid token id");
        _;
    }

    //-Функция createItem() - создание нового предмета, обращается к контракту NFT и вызывает функцию mint. 
    // / функция смарт контракта маркетплейса для создания NFT
    function createItem(string memory tokenURI, address owner) external {
        mint(tokenURI, owner);
    }

    //-Функция mint(), доступ к которой должен иметь только контракт маркетплейса 
    // / функция 721 и 1155 для минта нового NFT доступ должен быть только у контракта маркетплйеса
    function mint(string memory tokenURI, address owner) private {
        (bool success, bytes memory returnedData) = NFT.call{value: 0}(abi.encodeWithSignature("mint(string,address)", tokenURI, owner));
    }

    // SALE
    // продажа осуществляется за определенный токен ERC20
    //-Функция listItem() - выставка на продажу предмета. 
    // / функция маркетплеса для выставления NFT на продажу
    // на время листинга NFT отправляется на адрес маркетплейса
    function listItem(uint256 tokenId, uint256 price) external {
        (bool success, bytes memory returnedData) = NFT.call{value: 0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), tokenId));
        require(success, "Failed to list item");
        Sale memory sale = Sale({
            startedAt: block.timestamp,
            startedBy: msg.sender,
            price: price,
            status: Status.ONGOING
        });
        salesByTokenId[tokenId].push(sale);
    }

    //-Функция buyItem() - покупка предмета.
    function buyItem(uint256 tokenId) external onlyValidSale(tokenId) {
        Sale[] storage tokenSales = salesByTokenId[tokenId];
        Sale storage lastTokenSale = tokenSales[tokenSales.length - 1];
        require(lastTokenSale.status == Status.ONGOING, "Sale is not ongoing");

        (bool success, bytes memory returnedData) = NFT.call{value: 0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), msg.sender, tokenId));
        (bool success2, bytes memory returnedData2) = ERC20Token.call{value:0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, lastTokenSale.startedBy, lastTokenSale.price));
        require(success && success2, "Transaction failed");
        lastTokenSale.status = Status.FINISHED;
    }

    //-Функция cancel() - отмена продажи выставленного предмета / функция отмены продажи NFT, может быть вызвана до момента buyitem
    function cancel(uint256 tokenId) external onlyValidSale(tokenId) {
        Sale[] storage tokenSales = salesByTokenId[tokenId];
        Sale storage lastTokenSale = tokenSales[tokenSales.length - 1];
        require(lastTokenSale.status == Status.ONGOING, "Sale cannot be canceled");
        require(lastTokenSale.startedBy == msg.sender, "Only seller can cancel offering");

        (bool success, bytes memory returnedData) = NFT.call{value: 0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), lastTokenSale.startedBy, tokenId));
        require(success, "Transaction failed");
        lastTokenSale.status = Status.CANCELED;
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
    }

    // -Функция makeBid() - сделать ставку на предмет аукциона с определенным id.
    /// функция повышения ставки лота с tokenId
    /// с пользователя списываются токены и заморажиают на контракте
    //// если ставка не первая то предыдущему пользователю возвращаются его замороенные токены
    function makeBid(uint256 tokenId, uint256 price) external {
        require(tokenId < auctionsByTokenId[tokenId].length, "No auction with token found");
        Auction[] storage auctions = auctionsByTokenId[tokenId];
        require(price > auctions[auctions.length - 1].highestBid, "New bid must be higher than current");
        require(auctions[auctions.length - 1].status == Status.ONGOING, "Auction has ended");

        if(auctions[auctions.length - 1].highestBid != 0 && auctions[auctions.length - 1].highestBidder == msg.sender) {
            revert();
        }

        (bool success, bytes memory returnedData) = ERC20Token.call{value:0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), price));

        if(auctions[auctions.length - 1].highestBid > 0) {
            (bool success2, bytes memory returnedData2) = ERC20Token.call{value:0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), auctions[auctions.length - 1].highestBidder, auctions[auctions.length - 1].highestBid));
        }

        auctions[auctions.length - 1].highestBid = price;
        auctions[auctions.length - 1].highestBidder = msg.sender;
        auctions[auctions.length - 1] += 1;
    }

    // //-Функция finishAuction() - завершить аукцион и отправить НФТ победителю
    //// NFT идет последнему биддеру, а токены продавцу
    function finishAuction(uint256 tokenId) external {
        Auction[] storage auctions = auctionsByTokenId[tokenId];
        require(block.timestamp >= auctions[auctions.length - 1].startedAt + AUCTION_DURATION, "Too early to finish");
        if(auctions[auctions.length - 1].bidsCount < 2) {
            (bool success, bytes memory returnedData) = ERC20Token.call{value:0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), auctions[auctions.length - 1].highestBidder, auctions[auctions.length - 1].highestBid));
        } else {
            (bool success, bytes memory returnedData) = ERC20Token.call{value:0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), auctions[auctions.length - 1].startedBy, auctions[auctions.length - 1].highestBid));
            (bool success2, bytes memory returnedData2) = NFT.call{value: 0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), auctions[auctions.length - 1].highestBidder, tokenId));
        }
        auctions[auctions.length - 1].status = Status.FINISHED;
    }

    //-Функция cancelAuction() - отменить аукцион
    function cancelAuction(uint256 tokenId) external {
        Auction[] storage auctions = auctionsByTokenId[tokenId];
        require(auctions[auctions.length - 1].startedBy == msg.sender, "Only auction owner can cancel it");
        require(block.timestamp >= auctions[auctions.length - 1].startedAt + AUCTION_DURATION, "Too early to cancel");
        auctions[auctions.length - 1].status = Status.CANCELED;

        if (auctions[auctions.length - 1].highestBid > 0) {
            (bool success, bytes memory returnedData) = ERC20Token.call{value:0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), auctions[auctions.length - 1].highestBidder, auctions[auctions.length - 1].highestBid));
        }
    }

    function destroyContract() external onlyOwner {
        selfdestruct(payable(owner()));
    }

    //Аукцион длится 3 дня с момента старта аукциона. В течении этого срока аукцион не может быть отменен. 
    //В случае если по истечению срока набирается более двух ставок аукцион считается состоявшимся и создатель аукциона его завершает (НФТ переходит к последнему биддеру и токены создателю аукциона). 
    //В противном случае токены возвращаются последнему биддеру, а НФТ остается у создателя.
}
