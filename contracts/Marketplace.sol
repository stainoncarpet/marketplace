//SPDX-License-Identifier: MIT

pragma solidity >=0.8.11 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Marketplace is Ownable {
    uint256 public constant AUCTION_DURATION = 3 days;
    address public NFT;
    address public ERC20Token;

    enum Status {
        ONGOING, CANCELED, FINISHED
    }
    
    struct Auction {
        uint256 startedAt;
        address startedBy;
        address contractAddress;
        uint256 tokenId;
        uint256 highestBid;
        address highestBidder;
        Status status;
    }

    struct Sale {
        uint256 startedAt;
        address startedBy;
        address contractAddress;
        uint256 tokenId;
        uint256 price;
        Status status;
    }

    struct Item {
        address contractAddress;
        uint256 tokenId;
        address createdFor;
    }

    Auction[] public auctions;
    Sale[] public sales;

    constructor(address _nft, address _erc20) {
        NFT = _nft;
        ERC20Token = _erc20;
    }

    //-Функция createItem() - создание нового предмета, обращается к контракту NFT и вызывает функцию mint. 
    // / функция смарт контракта маркетплейса для создания NFT
    function createItem(string memory tokenURI, address owner) external {
        mint(owner);
    }

    //-Функция mint(), доступ к которой должен иметь только контракт маркетплейса 
    // / функция 721 и 1155 для минта нового NFT доступ должен быть только у контракта маркетплйеса
    function mint(address owner) private {
        (bool success, bytes memory returnedData) = NFT.call{value: 0}(abi.encodeWithSignature("mint(address)", owner));
    }

    // SALE
    // продажа осуществляется за определенный токен ERC20
    //-Функция listItem() - выставка на продажу предмета. / функция маркетплеса для выставления NFT на продажу
    // на время листинга NFT отправляется на адрес маркетплейса
    function listItem(uint256 tokenId, uint256 price) external {
        (bool success, bytes memory returnedData) = NFT.call{value: 0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), tokenId));
        Sale memory sale = Sale({
            startedAt: block.timestamp,
            startedBy: msg.sender,
            contractAddress: NFT,
            tokenId: tokenId,
            price: price,
            status: Status.ONGOING
        });
        sales.push(sale);
    }

    //-Функция buyItem() - покупка предмета.
    function buyItem(uint256 tokenId) external {
        for (uint256 index = 0; index < sales.length; index++) {
            if(sales[index].tokenId == tokenId && sales[index].status == Status.ONGOING) {
                NFT.call{value: 0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), msg.sender, tokenId));
                ERC20Token.call{value:0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, sales[index].startedBy, sales[index].price));
                sales[index].status = Status.FINISHED;
                return;
            }
        }
    }

    //-Функция cancel() - отмена продажи выставленного предмета / функция отмены продажи NFT, может быть вызвана до момента buyitem
    function cancel(tokenId) external {
        for (uint256 index = 0; index < sales.length; index++) {
            if(sales[index].tokenId == tokenId && sales[index].status == Status.ONGOING) {
                NFT.call{value: 0}(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), sales[index].startedBy, tokenId));
                sales[index].status = Status.CANCELED;
                return;
            }
        }
    }

    // AUCTION

    //-Функция listItemOnAuction() - выставка предмета на продажу в аукционе.
    // function listItemOnAuction(address _contractAddress, uint256 _tokenId) external {
    //     Auction memory auction = Auction({        
    //         startedAt: block.timestamp,
    //         startedBy: msg.sender,
    //         contractAddress: _contractAddress,
    //         tokenId: _tokenId,
    //         highestBid: 0,
    //         highestBidder: address(0),
    //         hasEnded: false
    //     });
    //     auctions.push(auction);
    // }

    // //-Функция makeBid() - сделать ставку на предмет аукциона с определенным id.
    // function makeBid(uint256 _auctionId) external {

    // }

    // //-Функция finishAuction() - завершить аукцион и отправить НФТ победителю
    // function finishAuction(uint256 _auctionId) external {
    //     auctions[_auctionId];
    // }

    // //-Функция cancelAuction() - отменить аукцион
    // function cancelAuction(uint256 _auctionId) external {
    //     require(auctions[_auctionId].startedBy == msg.sender, "Only auction owner can cancel it");

    // }

    //Аукцион длится 3 дня с момента старта аукциона. В течении этого срока аукцион не может быть отменен. 
    //В случае если по истечению срока набирается более двух ставок аукцион считается состоявшимся и создатель аукциона его завершает (НФТ переходит к последнему биддеру и токены создателю аукциона). 
    //В противном случае токены возвращаются последнему биддеру, а НФТ остается у создателя.
}
