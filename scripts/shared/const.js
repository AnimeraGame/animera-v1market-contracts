const { ethers } = require('hardhat');

const WETH = {
  rinkeby: '0xc778417e063141139fce010982780140aa0cd5ab'
};

const USDC = {
  rinkeby: '0xD4D5c5D939A173b9c18a6B72eEaffD98ecF8b3F6'
};

const TWAP_ORACLE_PRICE_FEED_WETH_USDC = {
  rinkeby: '0xc86718f161412Ace9c0dC6F81B26EfD4D3A8F5e0'
};

const NFT_GALLERY_NAME = 'NFTGallery721';
const NFT_GALLERY_VERSION = '1';

module.exports = {
  WETH,
  USDC,
  TWAP_ORACLE_PRICE_FEED_WETH_USDC,
  NFT_GALLERY_NAME,
  NFT_GALLERY_VERSION
};
