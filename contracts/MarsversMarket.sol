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
        uint256[4] memory uints, // sellId, price, deadline, nftId
        address[3] memory addrs, // seller, quoteToken, nftAddress
        bytes[2] memory sigs
    ) external payable nonReentrant {
        require(uints[2] >= block.timestamp, "MarsMarket: This sale is expired.");
        require(addrs[0] != msg.sender, "MarsMarket: seller can not buy his item.");
        require(_allowedQuoteTokens.contains(addrs[1]), "Not allowed quote token");
        bytes32 msgHash = keccak256(abi.encode(addrs[0], addrs[1], uints[1], uints[2], addrs[2], uints[3]));

        bytes32 digest = toTypedMessageHash(msgHash);

        (bytes32 r, bytes32 s, uint8 v) = MarsversHelper.splitSignature(sigs[0]);

        address recoverAddress = ecrecover(digest, v, r, s);
        require(recoverAddress == addrs[0], "MarsMarket: Invalid seller signature.");

        (r, s, v) = MarsversHelper.splitSignature(sigs[1]);
        recoverAddress = ecrecover(digest, v, r, s);
        require(recoverAddress == msg.sender, "MarsMarket: Invalid buyer signature.");

        if (addrs[1] == address(1)) {
            require(msg.value == uints[1], "Insufficient fund");
            TransferHelper.safeTransferETH(addrs[0], uints[1]);
        } else {
            require(msg.value == 0, "ERC20 token sale");
            TransferHelper.safeTransferFrom(addrs[1], msg.sender, addrs[0], uints[1]);
        }

        IERC721 nftTokenContract = IERC721(addrs[2]);
        nftTokenContract.transferFrom(addrs[0], msg.sender, uints[3]);

        emit SellExecuted(uints[0], addrs[0], msg.sender, addrs[2], uints[3], 1);
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
        uint256[5] memory uints, // offerId, offerPrice, saleDeadline, offerDeadline, nftId
        address[] memory addrs, // offerProvider, quoteToken, nftAddress
        bytes[2] memory sigs
    ) external nonReentrant {
        Order memory orderOffer = Order(addrs[0], addrs[1], addrs[2], uints[1], uints[3], uints[4]);
        require(uints[2] >= block.timestamp || uints[2] == 0, "MarsMarket: This sale is expired");
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
                uints[2],
                orderOffer.nftAddress,
                orderOffer.nftId
            )
        );
        digest = toTypedMessageHash(msgHash);
        recoverAddress = ecrecover(digest, v, r, s);
        require(recoverAddress == msg.sender, "MarsMarket: Invalid seller signature.");

        TransferHelper.safeTransferFrom(orderOffer.quoteToken, orderOffer.maker, msg.sender, orderOffer.price);

        IERC721 nftTokenContract = IERC721(addrs[2]);
        nftTokenContract.transferFrom(msg.sender, orderOffer.maker, orderOffer.nftId);
        emit OfferExecuted(
            uints[0],
            msg.sender,
            orderOffer.maker,
            orderOffer.nftAddress,
            orderOffer.quoteToken,
            orderOffer.nftId,
            orderOffer.price,
            1
        );
    }

    function _requireERC721(address nftAddress) private view {
        require(
            IERC721(nftAddress).supportsInterface(ERC721InterfaceID),
            "The NFT contract has an invalid ERC721 implementation"
        );
    }
}
