// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VoterRegistry} from "../src/VoterRegistry.sol";

contract DeployVoterRegistry is Script {
    function run() external returns (VoterRegistry) {
        vm.startBroadcast();
        VoterRegistry voterRegistry = new VoterRegistry();
        vm.stopBroadcast();

        return voterRegistry;
    }
}
