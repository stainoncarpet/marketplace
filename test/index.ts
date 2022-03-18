/* eslint-disable no-unreachable */
/* eslint-disable spaced-comment */
/* eslint-disable no-unused-expressions */
/* eslint-disable node/no-missing-import */
/* eslint-disable node/no-extraneous-import */
/* eslint-disable prettier/prettier */
/* eslint-disable no-unused-vars */

import { expect } from "chai";
import { ethers, network } from "hardhat";

const TEN_HUMAN_READABLE_ERC20_TOKENS = ethers.utils.parseUnits("10");
const TWENTY_HUMAN_READABLE_ERC20_TOKENS = ethers.utils.parseUnits("20");
const ONE_DAY_IN_SECONDS = 86400;

describe("Sales: Marketplace, ERC20 Token, NFT", function () {
  let Marketplace: any, marketplace: any, signers: any[], metamaskSigner: any, decimalPart: number;
  let NFT: any, nft: any;
  let MarketToken: any, marketToken: any;

  beforeEach(async () => {
    NFT = await ethers.getContractFactory("NFT");
    nft = await NFT.deploy();
    await nft.deployed();

    MarketToken = await ethers.getContractFactory("MarketToken");
    marketToken = await MarketToken.deploy( ethers.utils.parseUnits("21000000") );
    await marketToken.deployed();

    Marketplace = await ethers.getContractFactory("Marketplace");
    marketplace = await Marketplace.deploy(nft.address, marketToken.address);
    await marketplace.deployed();

    await nft.setMinter(marketplace.address);

    signers = await ethers.getSigners();
    metamaskSigner = await ethers.getSigner(process.env.METAMASK_PUBLIC_KEY);

    await marketplace.createItem("ipfs://someuri/", signers[1].address);
  });

  it("Should mint initial ERC20 MarketToken supply", async function () {
    expect(parseInt(ethers.utils.formatEther(await marketToken.totalSupply()))).to.equal(21000000);
  });

  it("Should see Marketplace as minter for NFT", async function () {
    expect(await nft.minter()).to.be.equal(marketplace.address);
  });

  it("Marketplace should mint an NFT for signer on demand", async function () {
    // minted nft belongs to initiator, not marketplace
    expect(await nft.balanceOf(signers[1].address)).to.be.equal(1);
    expect(await nft.balanceOf(marketplace.address)).to.be.equal(0);
  });

  it("Should list NFT for sale", async function () {
    const seller = signers[1];

    // nft with id0 belongs to signer1
    // allow Marketplace to manage nft0
    await nft.connect(seller).approve(marketplace.address, 0);

    // list token0 for 10 ERC20
    expect(await marketplace.connect(seller).listItem(0, TEN_HUMAN_READABLE_ERC20_TOKENS))
    .to.emit(marketplace,"SaleCreated")
    .withArgs(0, TEN_HUMAN_READABLE_ERC20_TOKENS)
    ;

    // the token should belong to Marketplace
    expect(await nft.balanceOf(seller.address)).to.be.equal(0);
    expect(await nft.balanceOf(marketplace.address)).to.be.equal(1);

    // new sale should be registered
    const newSale = await marketplace.salesByTokenId(0, 0);
    expect(newSale.startedBy).to.be.equal(seller.address);
  });

  it("Should be able to buy nft", async function () {
    // nft with id0 belongs to signer1
    // allow Marketplace to manage nft0 of seller
    await nft.connect(signers[1]).approve(marketplace.address, 0);

    // list token0 for 10 ERC20
    await marketplace.connect(signers[1]).listItem(0, TEN_HUMAN_READABLE_ERC20_TOKENS);

    // seller (signer[1]) doesn't have erc20tokens, signer[0] does
    expect(await marketToken.balanceOf(signers[1].address)).to.be.equal(0);
    expect(await marketToken.balanceOf(signers[0].address)).to.be.equal(ethers.utils.parseUnits("21000000"));

    // allow Marketplace to manage erc20 of buyer
    await marketToken.connect(signers[0]).approve(marketplace.address, TEN_HUMAN_READABLE_ERC20_TOKENS);

    expect(await marketplace.connect(signers[0]).buyItem(0))
    .to.emit(marketplace, "SaleFinished")
    .withArgs(0)
    ;

    expect(await nft.ownerOf(0)).to.be.equal(signers[0].address);
    expect(await marketToken.balanceOf(signers[1].address)).to.be.equal(TEN_HUMAN_READABLE_ERC20_TOKENS);
  });

  it("Should cancel sale listing", async function () {
    const seller = signers[1];

    // nft with id0 belongs to signer1
    // allow Marketplace to manage nft0
    await nft.connect(seller).approve(marketplace.address, 0);

    // list token0 for 10 ERC20
    await marketplace.connect(seller).listItem(0, TEN_HUMAN_READABLE_ERC20_TOKENS);

    // the token should belong to Marketplace
    expect(await nft.balanceOf(seller.address)).to.be.equal(0);
    expect(await nft.balanceOf(marketplace.address)).to.be.equal(1);

    expect(await marketplace.connect(seller).cancel(0))
    .to.emit(marketplace, "SaleCanceled")
    .withArgs(0)
    ;

    // the token should return to seller
    expect(await nft.balanceOf(seller.address)).to.be.equal(1);
    expect(await nft.balanceOf(marketplace.address)).to.be.equal(0);
  });
});

describe("Auctions: Marketplace, ERC20 Token, NFT", function () {
  let Marketplace: any, marketplace: any, signers: any[], metamaskSigner: any, decimalPart: number;
  let NFT: any, nft: any;
  let MarketToken: any, marketToken: any;

  beforeEach(async () => {
    NFT = await ethers.getContractFactory("NFT");
    nft = await NFT.deploy();
    await nft.deployed();

    MarketToken = await ethers.getContractFactory("MarketToken");
    marketToken = await MarketToken.deploy( ethers.utils.parseUnits("21000000") );
    await marketToken.deployed();

    Marketplace = await ethers.getContractFactory("Marketplace");
    marketplace = await Marketplace.deploy(nft.address, marketToken.address);
    await marketplace.deployed();

    await nft.setMinter(marketplace.address);

    signers = await ethers.getSigners();
    metamaskSigner = await ethers.getSigner(process.env.METAMASK_PUBLIC_KEY);

    await marketplace.createItem("ipfs://someuri/", signers[1].address);

    await marketToken.connect(signers[0]).transfer(signers[10].address, ethers.utils.parseUnits("1000000"));
    await marketToken.connect(signers[0]).transfer(signers[11].address, ethers.utils.parseUnits("1000000"));
  });

  it("Should list item on auction", async function () {
    expect(await marketplace.listItemOnAuction(0, TEN_HUMAN_READABLE_ERC20_TOKENS))
    .to.emit(marketplace, "AuctionCreated")
    .withArgs(0, TEN_HUMAN_READABLE_ERC20_TOKENS)
    ;
    //auction should exist
    const auction0 = await marketplace.auctionsByTokenId(0, 0);
    expect(auction0.startedBy).to.be.equal(signers[0].address);
  });

  it("Should make bid", async function () {
    await marketplace.listItemOnAuction(0, TEN_HUMAN_READABLE_ERC20_TOKENS);
    
    const seller = signers[1];
    const bidder = signers[0];

    // nft with id0 belongs to signer1
    // allow Marketplace to manage nft0
    await marketToken.connect(bidder).approve(marketplace.address, TEN_HUMAN_READABLE_ERC20_TOKENS);
    await marketplace.makeBid(0, TEN_HUMAN_READABLE_ERC20_TOKENS);

    // bid should be registered
    const auction = await marketplace.auctionsByTokenId(0, 0);
    expect(auction.highestBid).to.be.equal(TEN_HUMAN_READABLE_ERC20_TOKENS);
    expect(auction.highestBidder).to.be.equal(bidder.address);
  });

  it("Should cancel auction", async function () {
    await marketplace.connect(signers[1]).listItemOnAuction(0, TEN_HUMAN_READABLE_ERC20_TOKENS);
    await expect((await marketplace.connect(signers[2])).cancelAuction(0)).to.be.revertedWith("Only auction owner can cancel it");

    // try to finish auction 1 day in
    await network.provider.request({ method: "evm_increaseTime", params: [ONE_DAY_IN_SECONDS] });
    await network.provider.request({ method: "evm_mine", params: [] });
    await expect((await marketplace.connect(signers[1])).cancelAuction(0)).to.be.revertedWith("Too early to cancel");

    // try to finish in two more days
    await network.provider.request({ method: "evm_increaseTime", params: [ONE_DAY_IN_SECONDS * 2] });
    await network.provider.request({ method: "evm_mine", params: [] });

    await expect(marketplace.connect(signers[1]).cancelAuction(0))
      .to.emit(marketplace, "AuctionCanceled")
      .withArgs(0)
    ;
    
    // auction should still exist, but its status sgould be CANCELED
    const auction = await marketplace.auctionsByTokenId(0, 0);
    expect(auction.status).to.be.equal(1); // 1 - CANCELED

    // nft is returned to seller
    expect(await nft.ownerOf(0)).to.be.equal(signers[1].address);
    expect(await nft.balanceOf(marketplace.address)).to.be.equal(0);
  });

  it("Should finish auction with 1 bid", async function () {
    const seller = signers[1];
    const bidder = signers[0];

    await marketplace.connect(seller).listItemOnAuction(0, TEN_HUMAN_READABLE_ERC20_TOKENS);

    const bidderBalanceBeforeBid = await marketToken.balanceOf(bidder.address);
    await marketToken.connect(bidder).approve(marketplace.address, TEN_HUMAN_READABLE_ERC20_TOKENS);
    await marketplace.connect(bidder).makeBid(0, TEN_HUMAN_READABLE_ERC20_TOKENS);
    const bidderBalanceAfterBid = await marketToken.balanceOf(bidder.address);
    expect(bidderBalanceBeforeBid.sub(bidderBalanceAfterBid)).to.equal(TEN_HUMAN_READABLE_ERC20_TOKENS);
    
    // try to finish auction 1 day in
    await network.provider.request({ method: "evm_increaseTime", params: [ONE_DAY_IN_SECONDS] });
    await network.provider.request({ method: "evm_mine", params: [] });
    await expect(marketplace.connect(seller).finishAuction(0)).to.be.revertedWith("Too early to finish");

    // try to finish auction in three more days
    await network.provider.request({ method: "evm_increaseTime", params: [ONE_DAY_IN_SECONDS * 3] });
    await network.provider.request({ method: "evm_mine", params: [] });
    await expect(marketplace.connect(seller).finishAuction(0))
      .to.emit(marketplace, "AuctionFinished")
      .withArgs(0, TEN_HUMAN_READABLE_ERC20_TOKENS)
    ;
    
    // fewer than 2 bids end auction with no change in ownership
    const auction = await marketplace.auctionsByTokenId(0, 0);
    expect(parseInt(ethers.utils.formatUnits(auction.bidsCount, 0))).to.be.equal(1);
    
    expect(await nft.balanceOf(seller.address)).to.be.equal(1);
    expect(await marketToken.balanceOf(seller.address)).to.be.equal(0);

    // auction should still exist, but its status should be FINISHED
    expect(auction.status).to.be.equal(2); // 2 - FINISHED
  });

  it("Should finish auction with 2 bids", async function () {
    const seller = signers[1];
    const bidder1 = signers[10];
    const bidder2 = signers[11];

    await nft.connect(seller).approve(marketplace.address, 0);
    await marketplace.connect(seller).listItemOnAuction(0, TEN_HUMAN_READABLE_ERC20_TOKENS);

    await marketToken.connect(bidder1).approve(marketplace.address, TEN_HUMAN_READABLE_ERC20_TOKENS);
    await marketplace.connect(bidder1).makeBid(0, TEN_HUMAN_READABLE_ERC20_TOKENS);
    await marketToken.connect(bidder2).approve(marketplace.address, TWENTY_HUMAN_READABLE_ERC20_TOKENS);
    await marketplace.connect(bidder2).makeBid(0, TWENTY_HUMAN_READABLE_ERC20_TOKENS);

    // fast forward seven days
    await network.provider.request({ method: "evm_increaseTime", params: [ONE_DAY_IN_SECONDS * 7] });
    await network.provider.request({ method: "evm_mine", params: [] });
    expect(await marketplace.connect(seller).finishAuction(0))
      .to.emit(marketplace, "AuctionFinished")
      .withArgs(0, TWENTY_HUMAN_READABLE_ERC20_TOKENS)
    ;

    // auction results
    expect(await marketToken.balanceOf(seller.address)).to.be.equal(TWENTY_HUMAN_READABLE_ERC20_TOKENS);
    expect(await nft.ownerOf(0)).to.be.equal(bidder2.address);
  });
});