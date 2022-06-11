// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Example} from "../src/Example.sol";

contract Deployer is Test {
  Example example;

  function run() public {
    address broadcaster = vm.envAddress("BROADCASTER_ADDRESS");
    address exampleAddress = vm.envAddress("EXAMPLE_ADDRESS");
    string memory defaultURI = vm.envString("DEFAULT_URI");
    uint256 maxId = vm.envUint("REVEAL_MAX_ID");
    string memory uri = vm.envString("REVEAL_URI");
    example = Example(exampleAddress);
    vm.startBroadcast(broadcaster);
    example.setDefaultURI(defaultURI);
    example.setMaxMintsPerWallet(1000);
    example.devMint(3, broadcaster);
    example.addReveal(maxId, uri);
  }
}
