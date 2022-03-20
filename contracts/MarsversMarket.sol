// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./commons/EIP712MetaTransaction.sol";
import "./interfaces/IMarsversMarket.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/MarsversHelper.sol";

import "hardhat/console.sol";

contract MarsversMarket is EIP712MetaTransaction("MarsversMarket", "1"), ReentrancyGuard, Ownable, IMarsversMarket {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    /**
     * address(1) means QTUM native coin
     */
    EnumerableSet.AddressSet private _allowedQuoteTokens;

    bytes4 public constant ERC721InterfaceID = bytes4(0x80ac58cd);

    constructor() {
        _allowedQuoteTokens.add(address(1));
    }

    function allowedQuoteTokens() external view returns (address[] memory) {
        return _allowedQuoteTokens.values();
    }

    function isAllowedQuoteToken(address _token) external view returns (bool) {
        return _allowedQuoteTokens.contains(_token);
    }

    function addQuoteToken(address _asset) external onlyOwner {
        require(!_allowedQuoteTokens.contains(_asset), "Asset was already added in white list");
        _allowedQuoteTokens.add(_asset);
        emit AddQuoteToken(_asset, msgSender());
    }

    function removeQuoteToken(address _asset) external onlyOwner {
        require(_allowedQuoteTokens.contains(_asset), "Asset is not in white list");
        _allowedQuoteTokens.remove(_asset);
        emit RemoveQuoteToken(_asset, msgSender());
    }

    function executeSell(
        address seller,
        address quoteToken,
        uint256 price,
        uint256 deadline,
        address nftAddress,
        uint256 nftId,
        bytes[2] memory sigs
    ) external payable nonReentrant {
        require(deadline >= block.timestamp, "MarsMarket: This sale is expired.");
        require(seller != msg.sender, "MarsMarket: seller can not buy his item.");
        require(_allowedQuoteTokens.contains(quoteToken), "Not allowed quote token");
        bytes32 msgHash = keccak256(abi.encode(seller, quoteToken, price, deadline, nftAddress, nftId));

        bytes32 digest = toTypedMessageHash(msgHash);

        (bytes32 r, bytes32 s, uint8 v) = MarsversHelper.splitSignature(sigs[0]);

        address recoverAddress = ecrecover(digest, v, r, s);
        require(recoverAddress == seller, "MarsMarket: Invalid seller signature.");

        (r, s, v) = MarsversHelper.splitSignature(sigs[1]);
        recoverAddress = ecrecover(digest, v, r, s);
        require(recoverAddress == msg.sender, "MarsMarket: Invalid buyer signature.");

        if (quoteToken == address(1)) {
            require(msg.value == price, "Insufficient fund");
            TransferHelper.safeTransferETH(seller, price);
        } else {
            require(msg.value == 0, "ERC20 token sale");
            TransferHelper.safeTransferFrom(quoteToken, msg.sender, seller, price);
        }

        IERC721 nftTokenContract = IERC721(nftAddress);
        nftTokenContract.transferFrom(seller, msg.sender, nftId);

        emit SellExecuted(seller, msg.sender, nftAddress, nftId, 1);
    }

    struct Order {
        address maker;
        address quoteToken;
        address nftAddress;
        uint256 price;
        uint256 deadline;
        uint256 nftId;
    }

    /**
     * @param sigs The signatures of seller and buyer. sigs[0]: seller signature, sigs[1]: buyer signature
     */
    function executeOffer(
        address offerProvider,
        address quoteToken,
        uint256 offerPrice,
        uint256 saleDeadline,
        uint256 offerDeadline,
        address nftAddress,
        uint256 nftId,
        bytes[2] memory sigs
    ) external nonReentrant {
        Order memory orderOffer = Order(offerProvider, quoteToken, nftAddress, offerPrice, offerDeadline, nftId);
        require(saleDeadline >= block.timestamp || saleDeadline == 0, "MarsMarket: This sale is expired");
        require(orderOffer.deadline >= block.timestamp || orderOffer.deadline == 0, "MarsMarket: This offer is expired");
        require(_allowedQuoteTokens.contains(orderOffer.quoteToken), "Not allowed quote token");
        require(orderOffer.maker != msg.sender, "MarsMarket: Can not offer your own item.");

        bytes32 msgHash = keccak256(
            abi.encode(
                orderOffer.maker,
                orderOffer.quoteToken,
                orderOffer.price,
                orderOffer.deadline,
                orderOffer.nftAddress,
                orderOffer.nftId
            )
        );

        bytes32 digest = toTypedMessageHash(msgHash);
        (bytes32 r, bytes32 s, uint8 v) = MarsversHelper.splitSignature(sigs[1]);

        address recoverAddress = ecrecover(digest, v, r, s);
        require(recoverAddress == orderOffer.maker, "MarsMarket: Invalid offer provider signature.");

        (r, s, v) = MarsversHelper.splitSignature(sigs[0]);
        msgHash = keccak256(
            abi.encode(
                orderOffer.maker,
                orderOffer.quoteToken,
                orderOffer.price,
                saleDeadline,
                orderOffer.nftAddress,
                orderOffer.nftId
            )
        );
        digest = toTypedMessageHash(msgHash);
        recoverAddress = ecrecover(digest, v, r, s);
        require(recoverAddress == msg.sender, "MarsMarket: Invalid seller signature.");

        TransferHelper.safeTransferFrom(orderOffer.quoteToken, orderOffer.maker, msg.sender, orderOffer.price);

        IERC721 nftTokenContract = IERC721(nftAddress);
        nftTokenContract.transferFrom(msg.sender, orderOffer.maker, orderOffer.nftId);
        emit OfferExecuted(orderOffer.maker, orderOffer.nftAddress, orderOffer.quoteToken, orderOffer.nftId, orderOffer.price, 1);
    }

    function _requireERC721(address nftAddress) private view {
        require(
            IERC721(nftAddress).supportsInterface(ERC721InterfaceID),
            "The NFT contract has an invalid ERC721 implementation"
        );
    }
}
