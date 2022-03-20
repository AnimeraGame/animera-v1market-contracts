// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library MarsversHelper {
    function hashOrder(address _tokenAddr, uint256 _tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_tokenAddr, _tokenId));
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}
