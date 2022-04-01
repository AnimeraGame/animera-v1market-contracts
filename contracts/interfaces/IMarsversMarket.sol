// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMarsversMarket {
    event SellExecuted(
        uint256 indexed saleId,
        address indexed seller,
        address indexed buyer,
        address nftAddress,
        uint256 nftId,
        uint256 quantity
    );
    event OfferExecuted(
        uint256 indexed offerId,
        address indexed seller,
        address indexed buyer,
        address nftAddress,
        address quoteToken,
        uint256 nftId,
        uint256 offerPrice,
        uint256 quantity
    );
    event AddQuoteToken(address indexed asset, address user);
    event RemoveQuoteToken(address indexed asset, address user);
}
