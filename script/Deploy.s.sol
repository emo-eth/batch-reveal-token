// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {Example} from "../src/Example.sol";

contract Deployer is Test {
  Example example;

  function run() public {
    address deployer = vm.envAddress("DEPLOYER_ADDRESS");
    vm.startBroadcast(deployer);
    example = new Example();
    example.setDefaultURI("abcdefg");
    example.devMint(3, deployer);
  }
}
