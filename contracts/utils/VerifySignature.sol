//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;
import "hardhat/console.sol";
contract VerifySignature {
    /* 1. Unlock MetaMask account
    ethereum.enable()
    */

    /* 2. Get message hash to sign
    getMessageHash(
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,
        123,
        "coffee and donuts",
        1
    )

    hash = "0xcf36ac4f97dc10d91fc2cbb20d718e94a8cbfe0f82eaedc6a4aa38946fb797cd"
    */
    /* function getMessageHash(
        address _to, uint _amount, string memory _message, uint _nonce
    )
        public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    } */

    function getMessageHash(
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
        uint256 nonce)
    public pure returns (bytes32) {
        return keccak256(abi.encodePacked(makerAddress, takerAddress, makerErc20Addresses, makerErc20Amounts,
            takerErc20Addresses, takerErc20Amounts, expiration, nonce)
            );

    }

    /* 3. Sign message hash
    # using browser
    account = "copy paste account of signer here"
    ethereum.request({ method: "personal_sign", params: [account, hash]}).then(console.log)

    # using web3
    web3.personal.sign(hash, web3.eth.defaultAccount, console.log)

    Signature will be different for different accounts
    0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    /* 4. Verify signature
    signer = 0xB273216C05A8c0D4F0a4Dd0d7Bae1D2EfFE636dd
    to = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
    amount = 123
    message = "coffee and donuts"
    nonce = 1
    signature =
        0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function verify(
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
    }

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