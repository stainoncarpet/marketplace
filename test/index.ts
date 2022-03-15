/* eslint-disable spaced-comment */
/* eslint-disable no-unused-expressions */
/* eslint-disable node/no-missing-import */
/* eslint-disable node/no-extraneous-import */
/* eslint-disable prettier/prettier */
/* eslint-disable no-unused-vars */

import { expect } from "chai";
import { ethers, network } from "hardhat";

const TEN_HUMAN_READABLE_ERC20_TOKENS = ethers.utils.parseUnits("21000000");

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
    await marketplace.connect(seller).listItem(0, TEN_HUMAN_READABLE_ERC20_TOKENS);

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

    await marketplace.connect(signers[0]).buyItem(0);

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

    await marketplace.connect(seller).cancel(0);

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
  });

  it("Should list item on auction", async function () {
    await marketplace.listItemOnAuction(0, TEN_HUMAN_READABLE_ERC20_TOKENS);

    await marketplace.auctionsByTokenId(0, 0);

    
  });
});