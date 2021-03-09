//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

contract VerifySignature {

    function getMessageHash(
        address makerAddress,
        address[] memory erc20Addresses,
        uint256[] memory erc20Amounts,
        address[] memory erc721Addresses,
        uint256[] memory erc721Ids,
        address[] memory erc1155Addresses,
        uint256[] memory erc1155Ids,
        uint256[] memory erc1155Amounts,
        uint256 expiration,
        uint256 nonce)
    public pure returns (bytes32) {
        return keccak256(abi.encodePacked(makerAddress, erc20Addresses,
            erc20Amounts, erc721Addresses, erc721Ids, erc1155Addresses, erc1155Ids,
            erc1155Amounts, expiration, nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(
        address makerAddress,
        address[] memory erc20Addresses,
        uint256[] memory erc20Amounts,
        address[] memory erc721Addresses,
        uint256[] memory erc721Ids,
        address[] memory erc1155Addresses,
        uint256[] memory erc1155Ids,
        uint256[] memory erc1155Amounts,
        uint256 expiration,
        uint256 nonce,
        bytes memory signature
    )
        public pure returns (bool)
    {
        //bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
        /* bytes32 messageHash = getMessageHash(makerAddress, takerAddress, erc20Addresses,
            erc20Amounts, erc721Addresses, erc721Amounts, erc1155Addresses,
            erc1155Amounts, expiration, nonce); */
        //bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(getEthSignedMessageHash(
            getMessageHash(makerAddress, erc20Addresses,
                erc20Amounts, erc721Addresses, erc721Ids, erc1155Addresses,
                erc1155Ids, erc1155Amounts, expiration, nonce)
                ),
            signature) == makerAddress;
    }

    /* function verify(
        address _signer,
        address makerAddress,
        address takerAddress,
        address[] memory makerErc20Addresses,
        uint256[] memory makerErc20Amounts,
        //address[] memory makerErc721Addresses,
        //uint256[] memory makerErc721Amounts,
        //address[] memory makerErc1155Addresses,
        //uint256[] memory makerErc1155Amounts,
        address[] memory takerErc20Addresses,
        uint256[] memory takerErc20Amounts,
        //address[] memory takerErc721Addresses,
        //uint256[] memory takerErc721Amounts,
        //address[] memory takerErc1155Addresses,
        //uint256[] memory takerErc1155Amounts,
        uint256 expiration,
        uint256 nonce,
        bytes memory signature
    )
        public pure returns (bytes32, bool)
    {
        //bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
        bytes32 messageHash = getMessageHash(makerAddress, takerAddress, makerErc20Addresses, makerErc20Amounts,
            takerErc20Addresses, takerErc20Amounts, expiration, nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return (messageHash, recoverSigner(ethSignedMessageHash, signature) == _signer);
    } */

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

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
