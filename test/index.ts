/* eslint-disable spaced-comment */
/* eslint-disable no-unused-expressions */
/* eslint-disable node/no-missing-import */
/* eslint-disable node/no-extraneous-import */
/* eslint-disable prettier/prettier */
/* eslint-disable no-unused-vars */

import { expect } from "chai";
import { ethers, network } from "hardhat";

// describe("Market Token", function () {
//   it("Should mint initial supply", async function () {
//     const MarketToken = await ethers.getContractFactory("MarketToken");
//     const marketToken = await MarketToken.deploy( ethers.utils.parseUnits("21000000") );
//     await marketToken.deployed();

//     console.log(await marketToken.totalSupply())

//     expect( parseInt(ethers.utils.formatEther(await marketToken.totalSupply())) ).to.equal(21000000);
//   });
// });

describe("Marketplace", function () {
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

    //const marketTokenDecimals = await marketToken.decimals();

    await network.provider.request({ method: "hardhat_impersonateAccount", params: [process.env.METAMASK_PUBLIC_KEY] });
  });

  it("Should see Marketplace as minter for NFT", async function () {
    expect(await nft.minter()).to.be.equal(marketplace.address);
  });

  it("Marketplace should mint an NFT for signer on demand", async function () {
    await marketplace.createItem("ipfs://someuri/", signers[1].address);

    // minted nft belongs to requester, not marketplace
    expect(await nft.balanceOf(signers[1].address)).to.be.equal(1);
    expect(await nft.balanceOf(marketplace.address)).to.be.equal(0);
  });

  it("Should list NFT for sale", async function () {
    const seller = signers[1];
    await marketplace.createItem("ipfs://someuri/", seller.address);

    // nft with id0 belongs to signer1
    // allow Marketplace to manage nft0
    await nft.connect(seller).approve(marketplace.address, 0);

    // list token0 for 10 ERC20
    await marketplace.connect(seller).listItem(0, ethers.utils.parseUnits("10"));

    // the token should belong to Marketplace
    expect(await nft.balanceOf(seller.address)).to.be.equal(0);
    expect(await nft.balanceOf(marketplace.address)).to.be.equal(1);

    // new sale should be registered
    const newSale = await marketplace.sales(0);
    expect(newSale.startedBy).to.be.equal(seller.address);
  });

  it("Should be able to buy nft", async function () {
    await marketplace.createItem("ipfs://someuri/", signers[1].address);

    // nft with id0 belongs to signer1
    // allow Marketplace to manage nft0 of seller
    await nft.connect(signers[1]).approve(marketplace.address, 0);

    // list token0 for 10 ERC20
    await marketplace.connect(signers[1]).listItem(0, ethers.utils.parseUnits("10"));

    // seller (signer[1]) doesn't have erc20tokens, signer[0] does
    expect(await marketToken.balanceOf(signers[1].address)).to.be.equal(0);
    expect(await marketToken.balanceOf(signers[0].address)).to.be.equal(ethers.utils.parseUnits("21000000"));

    // allow Marketplace to manage erc20 of buyer
    await marketToken.connect(signers[0]).approve(marketplace.address, ethers.utils.parseUnits("10"));

    await marketplace.connect(signers[0]).buyItem(0);

    expect(await nft.ownerOf(0)).to.be.equal(signers[0].address);
    expect(await marketToken.balanceOf(signers[1].address)).to.be.equal(ethers.utils.parseUnits("10"));
  });
});