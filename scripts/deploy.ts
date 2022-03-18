/* eslint-disable node/no-missing-import */
/* eslint-disable prettier/prettier */

import { ethers } from "hardhat";

const main = async () => {
  // 1
  const MarketToken = await ethers.getContractFactory("MarketToken");
  const marketToken = await MarketToken.deploy();
  await marketToken.deployed();

  // 2
  const NFT = await ethers.getContractFactory("NFT");
  const nft = await NFT.deploy();
  await nft.deployed();

  // 3
  const Marketplace = await ethers.getContractFactory("Marketplace");
  const marketplace = await Marketplace.deploy(nft.address, marketToken.address);
  await marketplace.deployed();

  console.log("MarketToken deployed to:", marketToken.address, "by", await marketToken.signer.getAddress());
  console.log("NFT deployed to:", nft.address, "by", await nft.signer.getAddress());
  console.log("Marketplace deployed to:", marketplace.address, "by", await marketplace.signer.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});