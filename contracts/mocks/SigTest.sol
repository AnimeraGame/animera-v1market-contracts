// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../commons/EIP712MetaTransaction.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/Marsverhelper.sol";

import "hardhat/console.sol";

contract SigTest is EIP712MetaTransaction("MarsversMarket", "1"), ReentrancyGuard, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    bytes4 public constant ERC721InterfaceID = bytes4(0x80ac58cd);

    constructor() {}

    function getSellDigest(
        address seller,
        address quoteToken,
        uint256 price,
        uint256 deadline,
        address nftAddress,
        uint256 nftId
    )
        external
        view
        returns (
            // bytes[2] memory sigs
            bytes32 msgHash,
            bytes32 digest
        )
    {
        msgHash = keccak256(abi.encode(seller, quoteToken, price, deadline, nftAddress, nftId)); // checked

        digest = toTypedMessageHash(msgHash);
    }

    function getSellSigner(
        address seller,
        address quoteToken,
        uint256 price,
        uint256 deadline,
        address nftAddress,
        uint256 nftId,
        bytes memory sig
    ) external view returns (address) {
        bytes32 msgHash = keccak256(abi.encode(seller, quoteToken, price, deadline, nftAddress, nftId)); // checked

        bytes32 digest = toTypedMessageHash(msgHash);

        (bytes32 r, bytes32 s, uint8 v) = NFTGalleryHelper.splitSignature(sig);

        address recoverAddress = ecrecover(digest, v, r, s);

        return recoverAddress;
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
        bytes32 msgHash = keccak256(abi.encode(offerProvider, quoteToken, offerPrice, offerDeadline, nftAddress, nftId));

        bytes32 digest = toTypedMessageHash(msgHash);
        (bytes32 r, bytes32 s, uint8 v) = NFTGalleryHelper.splitSignature(sigs[1]);

        address recoverAddress = ecrecover(digest, v, r, s);
        require(recoverAddress == offerProvider, "MarsMarket: Invalid offer provider signature.");

        (r, s, v) = NFTGalleryHelper.splitSignature(sigs[0]);
        msgHash = keccak256(abi.encode(offerProvider, quoteToken, offerPrice, saleDeadline, nftAddress, nftId));
        recoverAddress = ecrecover(digest, v, r, s);
        require(recoverAddress == msg.sender, "MarsMarket: Invalid seller signature.");

        TransferHelper.safeTransferFrom(quoteToken, offerProvider, msg.sender, offerPrice);
        // emit OfferExecuted(offerProvider, nftAddress, quoteToken, nftId, offerPrice, 1);
    }

    function _requireERC721(address nftAddress) private view {
        require(
            IERC721(nftAddress).supportsInterface(ERC721InterfaceID),
            "The NFT contract has an invalid ERC721 implementation"
        );
    }
}
