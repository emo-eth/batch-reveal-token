// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {Test} from "forge-std/Test.sol";

import {BatchReveal} from "../../src/lib/BatchReveal.sol";
import {ERC721A} from "ERC721A/ERC721A.sol";

contract BatchRevealImpl is BatchReveal {
    constructor(bytes32 _provenanceHash) BatchReveal("", _provenanceHash) ERC721A("name", "name") {}
}

contract BatchRevealTest is Test {
    BatchReveal test;

    function setUp() public {
        test = new BatchRevealImpl(bytes32(0));
        test.setDefaultURI("default1");
    }

    function testConstructor() public {
        test = new BatchRevealImpl(bytes32(uint256(1234)));
        assertEq(bytes32(uint256(1234)), test.provenanceHash());
    }

    function testAddReveal() public {
        test.addReveal(1, "uri1");
        (uint256 maxId, string memory uri) = test.reveals(0);
        assertEq(1, maxId);
        assertEq("uri1", uri);
        test.addReveal(2, "uri2");
        (maxId, uri) = test.reveals(1);
        assertEq(2, maxId);
        assertEq("uri2", uri);
    }

    function testAddReveal_onlyOwner() public {
        test.transferOwnership(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        test.addReveal(1, "uri1");
    }

    function testUpdateReveal() public {
        test.addReveal(1, "uri1");
        test.updateReveal(0, 2, "uri2");
        (uint256 maxId, string memory uri) = test.reveals(0);
        assertEq(2, maxId);
        assertEq("uri2", uri);
    }

    function testUpdateReveal_onlyOwner() public {
        test.addReveal(1, "uri1");
        test.transferOwnership(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        test.updateReveal(0, 2, "uri2");
    }

    function testSetDefaultURI() public {
        test.setDefaultURI("default2");
        assertEq("default2", test.defaultURI());
    }

    function testSetDefaultURI_onlyOwner() public {
        test.transferOwnership(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        test.setDefaultURI("default2");
    }

    function testSetFullyRevealed() public {
        test.addReveal(1, "uri1/");
        test.addReveal(2, "uri2/");
        assertEq(test.tokenURI(0), "uri1/0");
        test.setFullyRevealed();
        assertEq(test.tokenURI(0), "default10");
    }

    function testSetFullyRevealed_onlyOwner() public {
        test.transferOwnership(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        test.setFullyRevealed();
        vm.expectRevert();
        test.reveals(0);
    }

    function testTokenURI() public {
        // all tokens default by default
        assertEq("default1", test.tokenURI(1));
        // reveals up to id non-inclusive
        test.addReveal(2, "uri1/");
        assertEq("uri1/1", test.tokenURI(1));
        assertEq("default1", test.tokenURI(2));
        // update reveal updates tokenURI
        test.updateReveal(0, 3, "uri2/");
        assertEq("uri2/2", test.tokenURI(2));
        // update defaultURI
        test.setDefaultURI("default2/");
        assertEq("default2/", test.tokenURI(3));
        assertEq("uri2/2", test.tokenURI(2));
        test.setFullyRevealed();
        assertEq("default2/1", test.tokenURI(1));
    }
}
