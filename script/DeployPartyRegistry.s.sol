// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PartyRegistry} from "../src/PartyRegistry.sol";

contract DeployPartyRegistry is Script {
    function run() external returns (PartyRegistry) {
        vm.startBroadcast();
        PartyRegistry partyRegistry = new PartyRegistry();
        vm.stopBroadcast();

        return partyRegistry;
    }
}
