// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const eutil = require('ethjs-util');
// const Web3 = require("Web3");
// const Wallet = ethers.Wallet;
// const utils = ethers.utils;
//
// mnemonic = "announce room limb pattern dry unit scale effort smooth jazz weasel alcohol"
// wallet = Wallet.fromMnemonic(mnemonic)
const sliceSignature = (signature) => {
    // console.log(signature);
    let r = signature.slice(0, 66);
    let s = "0x" + signature.slice(66, 130);
    let v = "0x" + signature.slice(130, 132);
    v = web3.utils.toDecimal(v);
    v = v + 27;
    // console.log(r,s,v)
    return {r, s, v};
}

const signTest = async function(){

    // Using eth.sign()

    let accounts = await web3.eth.getAccounts();
    let msg = "Some data"

    let prefix = "\x19Ethereum Signed Message:\n" + msg.length
    let msgHash1 = web3.utils.sha3(prefix+msg)

    let sig1 = await web3.eth.sign(msg, accounts[0]);

    console.log(sig1);
}

async function main() {
    // let web3 = new Web3(Web3.givenProvider || "ws://localhost:8545");
    [owner, addr1, addr2, ...addrs] = await web3.eth.getAccounts();
    [owner_e, addr1_e, ...addrs_e] = await ethers.getSigners();

    console.log(owner);
    console.log(addr1);
    console.log(addr2);
    const initial_mint = web3.utils.toWei('100000', 'ether');

    const MetaExchange = await hre.ethers.getContractFactory("MetaExchange");
    const metaExchange = await MetaExchange.deploy();
    await metaExchange.deployed();

    const VerifySignature = await hre.ethers.getContractFactory("VerifySignature");
    const verifySignature = await VerifySignature.deploy();
    await verifySignature.deployed();

    const MockERC20 = await hre.ethers.getContractFactory("MockERC20");
    const f1 = await MockERC20.deploy("F1", "F1");
    await f1.deployed();

    f1.mint(owner, initial_mint);
    f1.mint(addr1, initial_mint);

    const f2 = await MockERC20.deploy("F2", "F2");
    await f2.deployed();

    f2.mint(owner, initial_mint);
    f2.mint(addr1, initial_mint);

    //approvals
    await f1.connect(owner_e).approve(metaExchange.address, await f1.balanceOf(owner));
    await f1.connect(addr1_e).approve(metaExchange.address, await f1.balanceOf(addr1));

    await f2.connect(owner_e).approve(metaExchange.address, await f2.balanceOf(owner));
    await f2.connect(addr1_e).approve(metaExchange.address, await f2.balanceOf(addr1));

    console.log(web3.utils.fromWei( (await f1.balanceOf(owner)).toString(), 'ether'));
    console.log(web3.utils.fromWei( (await f1.balanceOf(addr1)).toString(), 'ether'));
    console.log(web3.utils.fromWei( (await f2.balanceOf(owner)).toString(), 'ether'));
    console.log(web3.utils.fromWei( (await f2.balanceOf(addr1)).toString(), 'ether'));

    let makerAddress = owner;
    let takerAddress = addr1;
    let makerErc20Addresses = [f1.address];
    let makerErc20Amounts = [web3.utils.toWei('250', 'ether')];
    let makerErc721Addresses = [f1.address];
    let makerErc721Amounts = [web3.utils.toWei('250', 'ether')];
    let makerErc1155Addresses = [f1.address];
    let makerErc1155Amounts = [web3.utils.toWei('250', 'ether')];
    let takerErc20Addresses = [f2.address];
    let takerErc20Amounts = [web3.utils.toWei('750', 'ether')];
    let takerErc721Addresses = [f2.address];
    let takerErc721Amounts = [web3.utils.toWei('750', 'ether')];
    let takerErc1155Addresses = [f2.address];
    let takerErc1155Amounts = [web3.utils.toWei('750', 'ether')];

    let expiration = new Date().getTime() + 60000;
    let nonce = 1;

    let args = [makerAddress, takerAddress, makerErc20Addresses,
        makerErc20Amounts, takerErc20Addresses, takerErc20Amounts,
        expiration, nonce];
    let makerArgs = [makerAddress, takerAddress, makerErc20Addresses,
        makerErc20Amounts, makerErc721Addresses, makerErc721Amounts,
        makerErc1155Addresses, makerErc1155Amounts, expiration, nonce];
    let takerArgs = [makerAddress, takerAddress, takerErc20Addresses,
        takerErc20Amounts, takerErc721Addresses, takerErc721Amounts,
        takerErc1155Addresses, takerErc1155Amounts, expiration, nonce];
    // let argTypes = ['address', 'address', 'address[]', 'uint256[]',
    //     'address[]', 'uint256[]', 'uint256', 'uint256'];

    // console.log(...args);
    // const msghash = await verifySignature.getMessageHash("0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C",
    //     123,
    //     "coffee and donuts",
    //     1);
    const makerMsgHash = await verifySignature.getMessageHash(...makerArgs);
    const signedMakerMsg = await web3.eth.sign(makerMsgHash, owner, console.log);
    console.log(signedMakerMsg);
    const takerMsgHash = await verifySignature.getMessageHash(...takerArgs);
    const signedTakerMsg = await web3.eth.sign(takerMsgHash, owner, console.log);
    console.log(signedTakerMsg);
    // const (r,s,v) = await verifySignature.splitSignature(signedMsg);
    //const signedMsgHash = await verifySignature.getEthSignedMessageHash();
    // const verify = await verifySignature.verify(owner,
    //     "0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C", 123, "coffee and donuts", 1,
    //     signedMsg);
    // const verify = await verifySignature.verify(owner,
    //     ...args,
    //     signedMsg);
    // console.log(verify);

    let order = {
        'makerErc20Addresses': makerErc20Addresses,
        'makerErc20Amounts': makerErc20Amounts,
        'makerErc721Addresses': makerErc721Addresses,
        'makerErc721Amounts': makerErc721Amounts,
        'makerErc1155Addresses': makerErc1155Addresses,
        'makerErc1155Amounts': makerErc1155Amounts,
        'takerErc20Addresses': takerErc20Addresses,
        'takerErc20Amounts': takerErc20Amounts,
        'takerErc721Addresses': takerErc721Addresses,
        'takerErc721Amounts': takerErc721Amounts,
        'takerErc1155Addresses': takerErc1155Addresses,
        'takerErc1155Amounts': takerErc1155Amounts,
        'expiration': expiration
    }
    await metaExchange.connect(addr1_e).
        fill(makerAddress, takerAddress, order, signedMakerMsg, signedTakerMsg, nonce);

    console.log(web3.utils.fromWei( (await f1.balanceOf(owner)).toString(), 'ether'));
    console.log(web3.utils.fromWei( (await f1.balanceOf(addr1)).toString(), 'ether'));
    console.log(web3.utils.fromWei( (await f2.balanceOf(owner)).toString(), 'ether'));
    console.log(web3.utils.fromWei( (await f2.balanceOf(addr1)).toString(), 'ether'));
    // let args = [makerAddress, takerAddress, makerErc20Addresses,
    //     makerErc20Amounts, takerErc20Addresses, takerErc20Amounts,
    //     expiration, nonce];
    //
    // let argTypes = ['address', 'address', 'address[]', 'uint256[]',
    //     'address[]', 'uint256[]', 'uint256', 'uint256'];
    //
    // let valuesEncoded = web3.eth.abi.encodeParameters(argTypes, args);
    //
    // let hash = web3.utils.soliditySha3(valuesEncoded);
    //
    // let signature = await web3.eth.sign(hash, owner);
    //
    // let sigSlices = sliceSignature(signature);

    // const message = "SchoolBus";
    // const h = web3.utils.soliditySha3(message);
    // let signature = await web3.eth.sign(h, owner);
    //
    // var r = signature.slice(0, 66);
    // var s = "0x" + signature.slice(66, 130);
    // var v = "0x" + signature.slice(130, 132);
    // v = web3.utils.toDecimal(v);
    // v = v + 27;
    //
    // const result = await metaExchange.checkSignature(h, v, r, s);
    // console.log(result);
    // await metaExchange.fill(makerAddress, takerAddress, makerErc20Addresses,
    //     makerErc20Amounts, takerErc20Addresses, takerErc20Amounts, expiration, nonce,
    //     sigSlices.v, sigSlices.r, sigSlices.s, {from: addr1});
    // let si = await metaExchange.checkSignature(hash, sigSlices.v, sigSlices.r, sigSlices.s);
    // console.log(si);

    // [owner, addr1, addr2, ...addrs] = await web3.eth.getAccounts();

    // const makerErc20 = [[f1.address, ethers.utils.parseEther('1000')]];
    // const takerErc20 = [[f2.address, ethers.utils.parseEther('2000')]];
    //
    // const valuesEncoded = web3.eth.abi.encodeParameters(['address', 'address[]', 'uint256[]', 'address[]', 'uint256[]'],
    //     [addr1.address, [f1.address], [ethers.utils.parseEther('1000')], [f2.address], [ethers.utils.parseEther('500')]]);
    // const hash = web3.utils.keccak256(valuesEncoded);
    // console.log(hash);
    // let signature = await web3.eth.sign(hash, addr1.address);
    // let sigSlices = sliceSignature(signature);
    //
    // let meta_tx_one = {
    //     sender: addr1.address,
    //     receiver: addr2.address,
    //     v: sigSlices.v,
    //     r: sigSlices.r,
    //     s: sigSlices.s
    // }
    //
    // console.log(meta_tx_one);

    // Order parameters.
    // let makerAddress = owner.address;
    // let takerAddress = addr1.address;
    // let makerErc20Addresses = [f1.address];
    // let makerErc20Amounts = [250];
    // let takerErc20Addresses = [f2.address];
    // let takerErc20Amounts = [750];
    // let expiration = new Date().getTime() + 60000;
    // // let nonce = 1;
    //
    // // Message hash for signing.
    // let message = makerAddress + takerAddress + makerErc20Addresses +
    //     makerErc20Amounts + takerErc20Addresses + takerErc20Amounts +
    //     expiration;
    // signTest();
    //
    // const args = [makerAddress, takerAddress, makerErc20Addresses,
    //     makerErc20Amounts, takerErc20Addresses, takerErc20Amounts,
    //     expiration];
    // const argTypes = ['address', 'address', 'address[]', 'uint256[]',
    //   'address[]', 'uint256[]', 'uint256'];
    // const msg = await web3.utils.keccak256(argTypes, args);
    // console.log(msg);
    // let sig = await web3.eth.sign(msg, makerAddress);
    // //const { v, r, s } = util.fromRpcSig(sig);
    // sigs = sliceSignature(sig);
    // const val = await metaExchange.validate(makerAddress, takerAddress, makerErc20Addresses,
    //     makerErc20Amounts, takerErc20Addresses, takerErc20Amounts,
    //     expiration, sigs.v, sigs.r, sigs.s);
    // console.log(val);
    // exchange.fill(makerAddress, makerAmount, makerToken,
    //   takerAddress, takerAmount, takerToken,
    //   expiration, nonce, v, util.bufferToHex(r), util.bufferToHex(s), {
    //     from: takerAddress,
    //     value: takerAmount,
    //     gasLimit: web3.toHex(200000),
    //     gasPrice: web3.eth.gasPrice
    //   })

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
