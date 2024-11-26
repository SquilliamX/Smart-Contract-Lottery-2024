// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() public {}

    function deployContract() public returns (Raffle, HelperConfig) {
        // deploy a new helpconfig contract that grabs the chainid and networkConfigs
        HelperConfig helperConfig = new HelperConfig();
        // grab the network configs of the chain we are deploying to and save them as `config`.
        // its also the same as doing ` HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);`
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // everything between startBroadcast and stopBroadcast is broadcasted to a real chain
        vm.startBroadcast();
        // create a new raffle contract with the parameters that are in the Raffle's constructor. This HAVE to be in the same order as the constructor!
        Raffle raffle = new Raffle(
            // we do `config.` before each one because our helperConfig contract grabs the correct config dependent on the chain we are deploying to
            config.entranceFee,
            config.interval,
            config.vrfCoordinatior,
            config.gasLane,
            config.subscriptionId,
            config.callBackGasLimit
        );
        vm.stopBroadcast();
        // returns the new raffle and helperconfig that we just defined and deployed so that these new values can be used when this function `deployContracts` is called
        return (raffle, helperConfig);
    }
}
