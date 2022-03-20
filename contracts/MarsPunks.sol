// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarsPunks is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter public tokenIds;

    string private _uriUrl;

    event MintMarsPunk(address indexed _creator, uint256 indexed _tokenId);

    constructor(string memory uriUrl_) ERC721("Mars Punks", "MP") {
        _uriUrl = uriUrl_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uriUrl;
    }

    /**
     * TODO it is just demo now
     */
    // function mint() external onlyOwner nonReentrant returns (uint256) {
    function mint() external nonReentrant returns (uint256) {
        tokenIds.increment();
        uint256 newItemId = tokenIds.current();

        _mint(msg.sender, newItemId);

        emit MintMarsPunk(msg.sender, newItemId);
        return newItemId;
    }
}
