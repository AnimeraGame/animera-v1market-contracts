// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract ERC721TestVerify is ERC721 {
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint(address _to, uint256 _tokenId) public {
        super._mint(_to, _tokenId);
    }

    function burn(uint256 _tokenId) public {
        super._burn(_tokenId);
    }

    // function getERC721InterfaceId() public view returns(bytes4) {
    //     // 0x80ac58cd
    //     return type(IERC721).interfaceId;
    // }

    // function getERC1155InterfaceId() public view returns(bytes4) {
    //     // 0xd9b67a26
    //     return type(IERC1155).interfaceId;
    // }
}
