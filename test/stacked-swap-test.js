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
    const initial_mint = web3.utils.toWei('1000', 'ether');
    const MetaExchange = await ethers.getContractFactory("Exchange");
    metaExchange = await MetaExchange.deploy();
    await metaExchange.deployed();
    const VerifySignature = await ethers.getContractFactory("VerifySig");
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

    it("Should succeed if transaction is made by taker", async() => {
        let maker = owner;
        let taker = addr1;
        let actions = [1, 3, 4];
        let erc20Directions = [true, false];
        let erc20TokenAddresses = [f1.address, f2.address];
        let erc20Amounts = [web3.utils.toWei('250', 'ether'), web3.utils.toWei('750', 'ether')];

        let erc721Directions = [true, false];
        let erc721TokenAddresses = [nf1.address, nf2.address];
        let erc721Ids = [1, 2];

        let erc1155Directions = [true, false];
        let erc1155TokenAddresses = [nff1.address, nff2.address];
        let erc1155Ids = [1, 2];
        let erc1155Amounts = [4, 2];

        let expiration = Math.floor(Date.now() / 1000) + 1000;
        let nonce = 1;

        erc20OrderType = ['bool[]', 'address[]', 'uint256[]'];
        erc721OrderType = ['bool[]', 'address[]', 'uint256[]'];
        erc1155OrderType = ['bool[]', 'address[]', 'uint256[]', 'uint256[]'];

        let encodedErc20Order = web3.eth.abi.encodeParameters(erc20OrderType, [erc20Directions, erc20TokenAddresses, erc20Amounts]);
        //console.log("encodedErc20Order: " + encodedErc20Order);
        let encodedErc721Order = web3.eth.abi.encodeParameters(erc721OrderType, [erc721Directions, erc721TokenAddresses, erc721Ids]);
        //console.log("encodedErc721Order: " + encodedErc721Order);
        let encodedErc1155Order = web3.eth.abi.encodeParameters(erc1155OrderType, [erc1155Directions, erc1155TokenAddresses, erc1155Ids, erc1155Amounts]);
        //console.log("encodedErc1155Order: " + encodedErc1155Order);

        let encodedOrder = [encodedErc20Order, encodedErc721Order, encodedErc1155Order];

        const orderHash = await verifySignature.getMessageHash(owner, actions, encodedOrder, nonce, expiration);

        const signedOrderMsg = await web3.eth.sign(orderHash, owner, null);

        await expect(metaExchange.connect(addr1_e).
            fill(maker, taker, actions, encodedOrder, signedOrderMsg, nonce, expiration)).to.not.be.reverted;
    })

    it("User balances should have updated values after swap", async() => {
        expect(web3.utils.fromWei((await f1.balanceOf(owner)).toString())).to.equal('750');
        expect(web3.utils.fromWei((await f1.balanceOf(addr1)).toString())).to.equal('1250');
        expect(web3.utils.fromWei((await f2.balanceOf(owner)).toString())).to.equal('1750');
        expect(web3.utils.fromWei((await f2.balanceOf(addr1)).toString())).to.equal('250');

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
