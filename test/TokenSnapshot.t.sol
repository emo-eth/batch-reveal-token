// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Token} from "../src/Token.sol";
import {Test} from "forge-std/Test.sol";
import {ERC721Holder} from "openzeppelin-contracts/token/ERC721/utils/ERC721Holder.sol";

contract TokenSnapshotTest is Test, ERC721Holder {
    Token test;

    bytes32[] proof;
    uint96 mintPrice = 0.1 ether;
    uint96 allowListMintPrice = 0.01 ether;
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
            309,
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
        test.setAllowListMintPrice(allowListMintPrice);
        test.setSaleState(Token.SaleState.PUBLIC);

        vm.deal(address(1), 2**128);
        vm.deal(address(100), 2**128);
        vm.prank(address(1));
        test.mint{value: mintPrice * 2}(2);
        vm.prank(address(100));
        test.mint{value: mintPrice * 2}(2);
        vm.prank(address(1));
        test.transferFrom(address(1), address(2), 1);

        // test.devMint(2, address(this));

        vm.deal(address(10), 2**128);
    }

    function test_snapshotDevMint_309() public {
        test.devMint(309, address(this));
    }

    function test_snapshotReveal() public {
        test.addReveal(100, "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/");
    }

    function test_snapshotTransfer_new() public {
        vm.prank(address(100));
        test.transferFrom(address(100), address(3), 2);
    }

    function test_snapshotTransfer_transferred() public {
        vm.prank(address(2));
        test.transferFrom(address(2), address(this), 1);
    }

    function test_snapshotAllowListMint_1() public {
        test.allowListMint{value: allowListMintPrice}(1, proof);
    }

    function test_snapshotMint_1() public {
        test.mint{value: mintPrice}(1);
    }

    function test_snapshotAllowListMint_5() public {
        test.allowListMint{value: allowListMintPrice * 5}(5, proof);
    }

    function test_snapshotMint_5() public {
        test.mint{value: mintPrice * 5}(5);
    }
}
