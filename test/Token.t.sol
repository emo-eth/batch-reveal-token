// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Token} from "../src/Token.sol";
import {Test} from "forge-std/Test.sol";
import {ERC721Holder} from "openzeppelin-contracts/token/ERC721/utils/ERC721Holder.sol";

contract TokenTest is Test, ERC721Holder {
    Token test;

    bytes32[] proof;
    uint64 mintPrice = 0.1 ether;
    bool reentrant;
    string private constant name = "Test";
    string private constant symbol = "TEST";
    string private constant uri1 = "ipfs://1234/";
    string private constant uri2 = "ipfs://5678/";
    bytes32 root;

    bool allowListReentrant;

    function setUp() public {
        test = new Token(
            name,
            symbol,
            5,
            5000,
            5309,
            500,
            0,
            0,
            bytes32(0),
            "",
            bytes32(uint256(1))
        );
        root = bytes32(0x0e3c89b8f8b49ac3672650cebf004f2efec487395927033a7de99f85aec9387c);
        test.setMerkleRoot(root);
        ///@notice this proof assumes DAPP_TEST_ADDRESS is its default value, 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84
        proof = [
            bytes32(0x042a8fd902455b847ec9e1fc2b056c101d23fcb859025672809c57e41981b518),
            bytes32(0x9280e7972fa86597b2eadadce706966b57123d3c9ec8da4ba4a4ad94da59f6bf),
            bytes32(0xfd669bf3d776ba18645619d460a223f8354d8efa5369f99805c2164fd9e63504)
        ];

        test.setMintPrice(mintPrice);
        test.setAllowListMintPrice(mintPrice);
        test.setSaleState(Token.SaleState.PUBLIC);
    }

    //////////
    // mint //
    //////////

    function testDevMint() public {
        test.devMint(1, address(this));
        assertEq(1, test.balanceOf(address(this)));
        // can mint to other addresses, and mint more than max per wallet
        test.devMint(5, address(1));
        assertEq(5, test.balanceOf(address(1)));
        vm.expectRevert(abi.encodeWithSignature("MaxDevMinted()"));
        test.devMint(5309 - 5, address(2));

        test.transferOwnership(address(1));
        vm.prank(address(1));
        test.claimOwnership();
        vm.expectRevert("Ownable: caller is not the owner");
        test.devMint(1, address(this));
    }

    function testSetMintPrice() public {
        test.setMintPrice(5);
        test.setAllowListMintPrice(1);
        assertFalse(test.mintPrice() == test.allowListMintPrice());
        assertEq(5, test.mintPrice());
        test.mint{value: 5}(1);
        test.setMintPrice(0);
        assertEq(0, test.mintPrice());
        test.mint{value: 0}(1);

        test.transferOwnership(address(1));
        vm.prank(address(1));
        test.claimOwnership();
        vm.expectRevert("Ownable: caller is not the owner");
        test.setMintPrice(5);
    }

    function testSetAllowListMintPrice() public {
        test.setMintPrice(1);
        test.setAllowListMintPrice(5);
        assertEq(5, test.allowListMintPrice());
        assertFalse(test.allowListMintPrice() == test.mintPrice());
        test.allowListMint{value: 5}(1, proof);
        test.setAllowListMintPrice(0);
        assertEq(0, test.allowListMintPrice());
        test.allowListMint{value: 0}(1, proof);

        test.transferOwnership(address(1));
        vm.prank(address(1));
        test.claimOwnership();
        vm.expectRevert("Ownable: caller is not the owner");
        test.setAllowListMintPrice(5);
    }

    function testSetSaleState() public {
        test.setSaleState(Token.SaleState.PUBLIC);
        assertEq(uint256(Token.SaleState.PUBLIC), uint256(test.saleState()));
        test.setSaleState(Token.SaleState.PAUSED);
        assertEq(uint256(Token.SaleState.PAUSED), uint256(test.saleState()));
        test.setSaleState(Token.SaleState.ALLOW_LIST);
        assertEq(uint256(Token.SaleState.ALLOW_LIST), uint256(test.saleState()));

        test.transferOwnership(address(1));
        vm.prank(address(1));
        test.claimOwnership();
        vm.expectRevert("Ownable: caller is not the owner");
        test.setSaleState(Token.SaleState.PUBLIC);
    }

    function testSetRoyaltyInfo() public {
        test.setRoyaltyInfo(address(1), 500);
        (address receiver, uint256 amount) = test.royaltyInfo(1, 10000);
        assertEq(500, amount);
        assertEq(address(1), receiver);
        (receiver, amount) = test.royaltyInfo(2, 20000);
        assertEq(address(1), receiver);
        assertEq(1000, amount);

        test.setRoyaltyInfo(address(2), 500);
        (receiver, amount) = test.royaltyInfo(3, 10000);
        assertEq(address(2), receiver);
        assertEq(500, amount);
        (receiver, amount) = test.royaltyInfo(2, 20000);
        assertEq(address(2), receiver);
        assertEq(1000, amount);

        test.setRoyaltyInfo(address(2), 1000);
        (receiver, amount) = test.royaltyInfo(3, 10000);
        assertEq(address(2), receiver);
        assertEq(1000, amount);
        (receiver, amount) = test.royaltyInfo(2, 20000);
        assertEq(address(2), receiver);
        assertEq(2000, amount);

        test.transferOwnership(address(1));
        vm.prank(address(1));
        test.claimOwnership();
        vm.expectRevert("Ownable: caller is not the owner");
        test.setRoyaltyInfo(address(1), 500);
    }

    function testCanMint() public {
        test.mint{value: mintPrice}(1);
        assertEq(1, test.balanceOf(address(this)));
        assertEq(address(this), test.ownerOf(0));
        test.mint{value: mintPrice * 2}(2);
        assertEq(3, test.balanceOf(address(this)));
        assertEq(address(this), test.ownerOf(1));
        assertEq(address(this), test.ownerOf(2));
    }

    // whenNotPaused
    function testMintWhenPaused() public {
        test.setSaleState(Token.SaleState.PAUSED);
        vm.expectRevert(abi.encodeWithSignature("PublicSaleInactive()"));
        test.mint{value: mintPrice}(1);
    }

    function testMintWhenAllowList() public {
        test.setSaleState(Token.SaleState.ALLOW_LIST);
        vm.expectRevert(abi.encodeWithSignature("PublicSaleInactive()"));
        test.mint{value: mintPrice}(1);
    }

    function testMintWhenMaxSupply() public {
        test.setMaxMintsPerWallet(5000);
        test.mint{value: uint256(mintPrice) * 5000}(5000);
        vm.expectRevert(abi.encodeWithSignature("MaxSupply()"));
        test.mint{value: mintPrice}(1);
    }

    function testMintMaxPerWallet() public {
        test.setMaxMintsPerWallet(5);
        test.mint{value: mintPrice * 5}(5);
        vm.expectRevert(abi.encodeWithSignature("MaxMintedForWallet()"));
        test.mint{value: mintPrice}(1);
        test.setMaxMintsPerWallet(6);
        test.mint{value: mintPrice}(1);
    }

    // includesCorrectPayment
    function testMintCorrectPayment() public {
        vm.expectRevert(abi.encodeWithSignature("IncorrectPayment()"));
        test.mint{value: 0.11 ether}(1);
        vm.expectRevert(abi.encodeWithSignature("IncorrectPayment()"));
        test.mint{value: 0.21 ether}(2);
    }

    ///@dev one can mint, and it cycles through token IDs
    function testCanAllowListMint() public {
        test.allowListMint{value: mintPrice}(1, proof);
        assertEq(1, test.balanceOf(address(this)));
        assertEq(address(this), test.ownerOf(0));
        test.allowListMint{value: mintPrice * 2}(2, proof);
        assertEq(3, test.balanceOf(address(this)));
        assertEq(address(this), test.ownerOf(1));
        assertEq(address(this), test.ownerOf(2));
    }

    // whenNotPaused
    function testAllowListMintWhenPaused() public {
        test.setSaleState(Token.SaleState.PAUSED);
        vm.expectRevert(abi.encodeWithSignature("SalePaused()"));
        test.allowListMint{value: mintPrice}(1, proof);
    }

    function testAllowListMintWhenAllowList() public {
        test.setSaleState(Token.SaleState.ALLOW_LIST);
        test.allowListMint{value: mintPrice}(1, proof);
    }

    function testAllowListMintWhenMaxSupply() public {
        test.setMaxMintsPerWallet(5309);
        test.mint{value: uint256(mintPrice) * 5000}(5000);
        vm.expectRevert(abi.encodeWithSignature("MaxSupply()"));
        test.allowListMint{value: mintPrice}(1, proof);
    }

    // includesCorrectPayment
    function testAllowListMintCorrectPayment() public {
        vm.expectRevert(abi.encodeWithSignature("IncorrectPayment()"));
        test.allowListMint{value: 0.11 ether}(1, proof);
        vm.expectRevert(abi.encodeWithSignature("IncorrectPayment()"));
        test.allowListMint{value: 0.21 ether}(2, proof);
    }

    function testAllowListMaxMintsPerWallet() public {
        test.setMaxMintsPerWallet(5);
        test.allowListMint{value: mintPrice * 5}(5, proof);
        vm.expectRevert(abi.encodeWithSignature("MaxMintedForWallet()"));
        test.allowListMint{value: mintPrice}(1, proof);
        test.setMaxMintsPerWallet(6);
        test.allowListMint{value: mintPrice}(1, proof);
    }
}
