// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMarsversMarket {
    event SellExecuted(
        address indexed seller,
        address indexed buyer,
        address indexed nftAddress,
        uint256 nftId,
        uint256 quantity
    );
    event OfferApproved(
        address indexed user,
        address indexed nftAddress,
        address quoteToken,
        uint256 nftId,
        uint256 offerPrice,
        uint256 quantity
    );
    event OfferExecuted(
        address indexed to,
        address indexed nftAddress,
        address quoteToken,
        uint256 nftId,
        uint256 offerPrice,
        uint256 quantity
    );
    event OfferCanceled(address indexed user, address indexed nftAddress, uint256 nftId);
    event AddQuoteToken(address indexed asset, address user);
    event RemoveQuoteToken(address indexed asset, address user);
}
