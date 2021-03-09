const { chai, expect, should } = require("chai");
const { BigNumber, Contract } = require('ethers');
const { ethers } = require('hardhat');

let owner
let addr1
let addrs
let owner_e
let addr1_e
let addrs_e
let f1
let f2
let nf1
let nf2
let nff1
let nff2
let metaExchange
let verifySignature

before(async() => {
    console.log("===================Deploying Contracts, Setting Up=====================");

    [owner, addr1, ...addrs] = await web3.eth.getAccounts();
    [owner_e, addr1_e, ...addrs_e] = await ethers.getSigners();
    const initial_mint = web3.utils.toWei('100000', 'ether');
    const MetaExchange = await ethers.getContractFactory("MetaExchange");
    metaExchange = await MetaExchange.deploy();
    await metaExchange.deployed();
    const VerifySignature = await ethers.getContractFactory("VerifySignature");
    verifySignature = await VerifySignature.deploy();
    await verifySignature.deployed();
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    f1 = await MockERC20.deploy("F1", "F1");
    await f1.deployed();

    await f1.mint(owner, initial_mint);
    await f1.mint(addr1, initial_mint);

    f2 = await MockERC20.deploy("F2", "F2");
    await f2.deployed();

    await f2.mint(owner, initial_mint);
    await f2.mint(addr1, initial_mint);

    await f1.connect(owner_e).approve(metaExchange.address, await f1.balanceOf(owner));
    await f1.connect(addr1_e).approve(metaExchange.address, await f1.balanceOf(addr1));

    await f2.connect(owner_e).approve(metaExchange.address, await f2.balanceOf(owner));
    await f2.connect(addr1_e).approve(metaExchange.address, await f2.balanceOf(addr1));

    const MockERC721 = await ethers.getContractFactory("MockERC721");
    nf1 = await MockERC721.deploy("NF1", "NF1");
    await nf1.deployed();

    await nf1.mint(owner, 1);
    await nf1.mint(addr1, 2);

    nf2 = await MockERC721.deploy("NF2", "NF2");
    await nf2.deployed();

    await nf2.mint(owner, 1);
    await nf2.mint(addr1, 2);

    //approvals
    await nf1.connect(owner_e).approve(metaExchange.address, 1);
    await nf1.connect(addr1_e).approve(metaExchange.address, 2);

    await nf2.connect(owner_e).approve(metaExchange.address, 1);
    await nf2.connect(addr1_e).approve(metaExchange.address, 2);

    const MockERC1155 = await ethers.getContractFactory("MockERC1155");
    nff1 = await MockERC1155.deploy("NFF1");
    await nff1.deployed();

    await nff1.mint(owner, 1, 10, "0x");
    await nff1.mint(addr1, 2, 10, "0x");

    nff2 = await MockERC1155.deploy("NFF2");
    await nff2.deployed();

    await nff2.mint(owner, 1, 10, "0x");
    await nff2.mint(addr1, 2, 10, "0x");
    //approvals
    await nff1.connect(owner_e).setApprovalForAll(metaExchange.address, true);
    await nff1.connect(addr1_e).setApprovalForAll(metaExchange.address, true);

    await nff2.connect(owner_e).setApprovalForAll(metaExchange.address, true);
    await nff2.connect(addr1_e).setApprovalForAll(metaExchange.address, true);

    console.log("Maker Address: " + owner);
    console.log("Taker Address: " + addr1);

    console.log("Initial balance of ERC20 F1 for User1: " + web3.utils.fromWei((await f1.balanceOf(owner)).toString(), 'ether'));
    console.log("Initial balance of ERC20 F1 for User2: " + web3.utils.fromWei((await f1.balanceOf(addr1)).toString(), 'ether'));
    console.log("Initial balance of ERC20 F2 for User1: " + web3.utils.fromWei((await f2.balanceOf(owner)).toString(), 'ether'));
    console.log("Initial balance of ERC20 F2 for User2: " + web3.utils.fromWei((await f2.balanceOf(addr1)).toString(), 'ether'));

    console.log("Initial owner of ERC721 NFT1 ID1: " + (await nf1.ownerOf(1)));
    console.log("Initial owner of ERC721 NFT2 ID2: " + (await nf2.ownerOf(2)));

    console.log("Initial balance of ERC1155 NFT1 ID1 for User1: " + (await nff1.balanceOf(owner, 1)));
    console.log("Initial balance of ERC1155 NFT1 ID2 for User1: " + (await nff1.balanceOf(owner, 2)));
    console.log("Initial balance of ERC1155 NFT1 ID1 for User2: " + (await nff1.balanceOf(addr1, 1)));
    console.log("Initial balance of ERC1155 NFT1 ID2 for User2: " + (await nff1.balanceOf(addr1, 2)));
    console.log("Initial balance of ERC1155 NFT2 ID1 for User1: " + (await nff2.balanceOf(owner, 1)));
    console.log("Initial balance of ERC1155 NFT2 ID2 for User1: " + (await nff2.balanceOf(owner, 2)));
    console.log("Initial balance of ERC1155 NFT2 ID1 for User2: " + (await nff2.balanceOf(addr1, 1)));
    console.log("Initial balance of ERC1155 NFT2 ID2 for User2: " + (await nff2.balanceOf(addr1, 2)));

    console.log("=====================================================================\n\n")
})

describe("Do a transaction of basket of assets of different types", function() {

    it("Should fail if transaction is made by maker", async() => {
        let makerAddress = owner;
        let takerAddress = addr1;
        let makerErc20Addresses = [f1.address];
        let makerErc20Amounts = [web3.utils.toWei('250', 'ether')];
        let makerErc721Addresses = [nf1.address];
        let makerErc721Ids = [1];
        let makerErc1155Addresses = [nff1.address];
        let makerErc1155Ids = [1];
        let makerErc1155Amounts = [4];
        let takerErc20Addresses = [f2.address];
        let takerErc20Amounts = [web3.utils.toWei('750', 'ether')];
        let takerErc721Addresses = [nf2.address];
        let takerErc721Ids = [2];
        let takerErc1155Addresses = [nff2.address];
        let takerErc1155Ids = [2];
        let takerErc1155Amounts = [2];

        let expiration = new Date().getTime() + 60000;
        let nonce = 1;

        let makerArgs = [makerAddress, makerErc20Addresses,
            makerErc20Amounts, makerErc721Addresses, makerErc721Ids,
            makerErc1155Addresses, makerErc1155Ids, makerErc1155Amounts, expiration, nonce];
        let takerArgs = [makerAddress, takerErc20Addresses,
            takerErc20Amounts, takerErc721Addresses, takerErc721Ids,
            takerErc1155Addresses, takerErc1155Ids, takerErc1155Amounts, expiration, nonce];

        const makerMsgHash = await verifySignature.getMessageHash(...makerArgs);
        const signedMakerMsg = await web3.eth.sign(makerMsgHash, owner, console.log);

        const takerMsgHash = await verifySignature.getMessageHash(...takerArgs);
        const signedTakerMsg = await web3.eth.sign(takerMsgHash, owner, console.log);

        let order = {
            'makerErc20Addresses': makerErc20Addresses,
            'makerErc20Amounts': makerErc20Amounts,
            'makerErc721Addresses': makerErc721Addresses,
            'makerErc721Ids': makerErc721Ids,
            'makerErc1155Addresses': makerErc1155Addresses,
            'makerErc1155Ids': makerErc1155Ids,
            'makerErc1155Amounts': makerErc1155Amounts,
            'takerErc20Addresses': takerErc20Addresses,
            'takerErc20Amounts': takerErc20Amounts,
            'takerErc721Addresses': takerErc721Addresses,
            'takerErc721Ids': takerErc721Ids,
            'takerErc1155Addresses': takerErc1155Addresses,
            'takerErc1155Ids': takerErc1155Ids,
            'takerErc1155Amounts': takerErc1155Amounts,
            'expiration': expiration
        };

        await expect(metaExchange.connect(owner_e).
            fill(makerAddress, takerAddress, order, signedMakerMsg, signedTakerMsg, nonce)).to.be.revertedWith("Order cannot be executed by maker");
    })

    it("Should succeed if transaction is made by taker", async() => {
        let makerAddress = owner;
        let takerAddress = addr1;
        let makerErc20Addresses = [f1.address];
        let makerErc20Amounts = [web3.utils.toWei('250', 'ether')];
        let makerErc721Addresses = [nf1.address];
        let makerErc721Ids = [1];
        let makerErc1155Addresses = [nff1.address];
        let makerErc1155Ids = [1];
        let makerErc1155Amounts = [4];
        let takerErc20Addresses = [f2.address];
        let takerErc20Amounts = [web3.utils.toWei('750', 'ether')];
        let takerErc721Addresses = [nf2.address];
        let takerErc721Ids = [2];
        let takerErc1155Addresses = [nff2.address];
        let takerErc1155Ids = [2];
        let takerErc1155Amounts = [2];

        let expiration = new Date().getTime() + 60000;
        let nonce = 1;

        let makerArgs = [makerAddress, makerErc20Addresses,
            makerErc20Amounts, makerErc721Addresses, makerErc721Ids,
            makerErc1155Addresses, makerErc1155Ids, makerErc1155Amounts, expiration, nonce];
        let takerArgs = [makerAddress, takerErc20Addresses,
            takerErc20Amounts, takerErc721Addresses, takerErc721Ids,
            takerErc1155Addresses, takerErc1155Ids, takerErc1155Amounts, expiration, nonce];

        const makerMsgHash = await verifySignature.getMessageHash(...makerArgs);
        const signedMakerMsg = await web3.eth.sign(makerMsgHash, owner, console.log);

        const takerMsgHash = await verifySignature.getMessageHash(...takerArgs);
        const signedTakerMsg = await web3.eth.sign(takerMsgHash, owner, console.log);

        let order = {
            'makerErc20Addresses': makerErc20Addresses,
            'makerErc20Amounts': makerErc20Amounts,
            'makerErc721Addresses': makerErc721Addresses,
            'makerErc721Ids': makerErc721Ids,
            'makerErc1155Addresses': makerErc1155Addresses,
            'makerErc1155Ids': makerErc1155Ids,
            'makerErc1155Amounts': makerErc1155Amounts,
            'takerErc20Addresses': takerErc20Addresses,
            'takerErc20Amounts': takerErc20Amounts,
            'takerErc721Addresses': takerErc721Addresses,
            'takerErc721Ids': takerErc721Ids,
            'takerErc1155Addresses': takerErc1155Addresses,
            'takerErc1155Ids': takerErc1155Ids,
            'takerErc1155Amounts': takerErc1155Amounts,
            'expiration': expiration
        };
        //console.log(order);
        await expect(metaExchange.connect(addr1_e).
            fill(makerAddress, takerAddress, order, signedMakerMsg, signedTakerMsg, nonce)).to.not.be.reverted;
    })

    it("User balances should have updated values after swap", async() => {
        expect(web3.utils.fromWei((await f1.balanceOf(owner)).toString())).to.equal('99750');
        expect(web3.utils.fromWei((await f1.balanceOf(addr1)).toString())).to.equal('100250');
        expect(web3.utils.fromWei((await f2.balanceOf(owner)).toString())).to.equal('100750');
        expect(web3.utils.fromWei((await f2.balanceOf(addr1)).toString())).to.equal('99250');

        expect(await nf1.ownerOf(1)).to.equal(addr1);
        expect(await nf2.ownerOf(2)).to.equal(owner);

        expect(await nff1.balanceOf(owner, 1)).to.equal(6);
        expect(await nff1.balanceOf(owner, 2)).to.equal(0);
        expect(await nff1.balanceOf(addr1, 1)).to.equal(4);
        expect(await nff1.balanceOf(addr1, 2)).to.equal(10);
        expect(await nff2.balanceOf(owner, 1)).to.equal(10);
        expect(await nff2.balanceOf(owner, 2)).to.equal(2);
        expect(await nff2.balanceOf(addr1, 1)).to.equal(0);
        expect(await nff2.balanceOf(addr1, 2)).to.equal(8);

        console.log("Final balance of ERC20 F1 for User1: " + web3.utils.fromWei((await f1.balanceOf(owner)).toString(), 'ether'));
        console.log("Final balance of ERC20 F1 for User2: " + web3.utils.fromWei((await f1.balanceOf(addr1)).toString(), 'ether'));
        console.log("Final balance of ERC20 F2 for User1: " + web3.utils.fromWei((await f2.balanceOf(owner)).toString(), 'ether'));
        console.log("Final balance of ERC20 F2 for User2: " + web3.utils.fromWei((await f2.balanceOf(addr1)).toString(), 'ether'));

        console.log("Final owner of ERC721 NFT1 ID1: " + (await nf1.ownerOf(1)));
        console.log("Final owner of ERC721 NFT2 ID2: " + (await nf2.ownerOf(2)));

        console.log("Final balance of ERC1155 NFT1 ID1 for User1: " + (await nff1.balanceOf(owner, 1)));
        console.log("Final balance of ERC1155 NFT1 ID2 for User1: " + (await nff1.balanceOf(owner, 2)));
        console.log("Final balance of ERC1155 NFT1 ID1 for User2: " + (await nff1.balanceOf(addr1, 1)));
        console.log("Final balance of ERC1155 NFT1 ID2 for User2: " + (await nff1.balanceOf(addr1, 2)));
        console.log("Final balance of ERC1155 NFT2 ID1 for User1: " + (await nff2.balanceOf(owner, 1)));
        console.log("Final balance of ERC1155 NFT2 ID2 for User1: " + (await nff2.balanceOf(owner, 2)));
        console.log("Final balance of ERC1155 NFT2 ID1 for User2: " + (await nff2.balanceOf(addr1, 1)));
        console.log("Final balance of ERC1155 NFT2 ID2 for User2: " + (await nff2.balanceOf(addr1, 2)));
    })
})
