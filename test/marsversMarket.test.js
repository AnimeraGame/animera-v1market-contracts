const { expect } = require('chai');
const { BigNumber } = require('ethers');
const { ethers, network, getChainId } = require('hardhat');
const { NFT_GALLERY_NAME, NFT_GALLERY_VERSION } = require('../scripts/shared/const');

const {
  ZERO_ADDRESS,
  getBigNumber,
  getSignatures,
  getDomainSeparator,
  getApprovalDigest,
  getFlatSignature,
  getEIP712Signature
} = require('../scripts/shared/utilities');

const {
  utils: { keccak256, defaultAbiCoder, toUtf8Bytes, solidityPack, hexlify },
  Wallet
} = ethers;

describe('MarsversMarket', function () {
  before(async function () {
    this.NFTGallery = await ethers.getContractFactory('MarsversMarket');
    this.SigTest = await ethers.getContractFactory('SigTest');
    this.MockERC20 = await ethers.getContractFactory('MockERC20');
    this.ERC721Test = await ethers.getContractFactory('ERC721Test');

    this.signers = await ethers.getSigners();

    this.seller = this.signers[1];
    this.buyer = this.signers[2];
  });

  beforeEach(async function () {
    this.nftGallery = await this.NFTGallery.deploy();
    this.quoteToken = await this.MockERC20.deploy('QuoteToken', 'QuoteToken');
    this.nft721 = await this.ERC721Test.deploy('ERC721Test', 'ERC721Test');
    this.sigTest = await this.SigTest.deploy();

    await this.nftGallery.addQuoteToken(this.quoteToken.address);

    for (let ii = 0; ii < 20; ii++) {
      await this.nft721.mint(this.seller.address, ii);
    }

    await this.quoteToken.transfer(this.buyer.address, getBigNumber(1000000));
  });

  describe('ERC721 case', function () {
    beforeEach(async function () {
      await this.nft721.connect(this.seller).setApprovalForAll(this.nftGallery.address, true);
      await this.quoteToken.connect(this.buyer).approve(this.nftGallery.address, ethers.constants.MaxUint256);
    });
    it('Signature test', async function () {
      const chainId = await getChainId();
      const sellPrice = getBigNumber(2);
      const sellDeadline = ~~(new Date().getTime() / 1000 + 1000);
      const nftId = 1;

      const dataTypes = ['address', 'address', 'uint256', 'uint256', 'address', 'uint256'];
      const dataValues = [
        this.seller.address,
        this.quoteToken.address,
        sellPrice,
        sellDeadline,
        this.nft721.address,
        nftId
      ];

      const digest = getApprovalDigest(NFT_GALLERY_NAME, this.sigTest.address, chainId, dataTypes, dataValues);

      const privateKey = Wallet.fromMnemonic(
        config.networks[hre.network.name].accounts.mnemonic,
        "m/44'/60'/0'/0/2"
      ).privateKey;
      const sellerSig = getEIP712Signature(digest, privateKey);

      const signerSC1 = await this.sigTest.getSellSigner(
        this.seller.address,
        this.quoteToken.address,
        sellPrice,
        sellDeadline,
        this.nft721.address,
        nftId,
        sellerSig
      );
      console.log('signerSC1 ===>', signerSC1);
      console.log('this.seller', this.seller.address);
      console.log('this.buyer', this.buyer.address);
    });
    it('Should execute sell', async function () {
      const chainId = await getChainId();
      const sellPrice = getBigNumber(2);
      const sellDeadline = ~~(new Date().getTime() / 1000 + 1000);
      const nftId = 1;

      const dataTypes = ['address', 'address', 'uint256', 'uint256', 'address', 'uint256'];
      const dataValues = [
        this.seller.address,
        this.quoteToken.address,
        sellPrice,
        sellDeadline,
        this.nft721.address,
        nftId
      ];

      const digest = getApprovalDigest(NFT_GALLERY_NAME, this.nftGallery.address, chainId, dataTypes, dataValues);

      const sellerPrivateKey = Wallet.fromMnemonic(
        config.networks[hre.network.name].accounts.mnemonic,
        "m/44'/60'/0'/0/1"
      ).privateKey;
      const sellerSig = getEIP712Signature(digest, sellerPrivateKey);

      const buerPrivateKey = Wallet.fromMnemonic(
        config.networks[hre.network.name].accounts.mnemonic,
        "m/44'/60'/0'/0/2"
      ).privateKey;
      const buyerSig = getEIP712Signature(digest, buerPrivateKey);

      await this.nftGallery
        .connect(this.buyer)
        .executeSell(
          this.seller.address,
          this.quoteToken.address,
          sellPrice,
          sellDeadline,
          this.nft721.address,
          nftId,
          [sellerSig, buyerSig]
        );
    });
    it('Should execute offer', async function () {
      const chainId = await getChainId();
      const offerPrice = getBigNumber(3);
      const sellDeadline = ~~(new Date().getTime() / 1000 + 2000);
      const offerDeadline = ~~(new Date().getTime() / 1000 + 1000);
      const nftId = 2;

      const dataTypesBuyer = ['address', 'address', 'uint256', 'uint256', 'address', 'uint256'];
      const dataValuesBuyer = [
        this.buyer.address,
        this.quoteToken.address,
        offerPrice,
        offerDeadline,
        this.nft721.address,
        nftId
      ];

      const digestBuyer = getApprovalDigest(
        NFT_GALLERY_NAME,
        this.nftGallery.address,
        chainId,
        dataTypesBuyer,
        dataValuesBuyer
      );
      const buyerPrivateKey = Wallet.fromMnemonic(
        config.networks[hre.network.name].accounts.mnemonic,
        "m/44'/60'/0'/0/2"
      ).privateKey;
      const buyerSig = getEIP712Signature(digestBuyer, buyerPrivateKey);

      // msgHash = keccak256(abi.encode(offerProvider, quoteToken, offerPrice, saleDeadline, nftAddress, nftId));
      const dataTypesSeller = ['address', 'address', 'uint256', 'uint256', 'address', 'uint256'];
      const dataValuesSeller = [
        this.buyer.address,
        this.quoteToken.address,
        offerPrice,
        sellDeadline,
        this.nft721.address,
        nftId
      ];
      const digestSeller = getApprovalDigest(
        NFT_GALLERY_NAME,
        this.nftGallery.address,
        chainId,
        dataTypesSeller,
        dataValuesSeller
      );
      const sellerPrivateKey = Wallet.fromMnemonic(
        config.networks[hre.network.name].accounts.mnemonic,
        "m/44'/60'/0'/0/1"
      ).privateKey;

      const sellerSig = getEIP712Signature(digestSeller, sellerPrivateKey);

      await this.nftGallery
        .connect(this.seller)
        .executeOffer(
          this.buyer.address,
          this.quoteToken.address,
          offerPrice,
          sellDeadline,
          offerDeadline,
          this.nft721.address,
          nftId,
          [sellerSig, buyerSig]
        );
    });
  });
});
