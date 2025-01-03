// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        // deploy a new helpconfig contract that grabs the chainid and networkConfigs
        HelperConfig helperConfig = new HelperConfig();
        // grab the network configs of the chain we are deploying to and save them as `config`.
        // its also the same as doing ` HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);`
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // if the subscription id does not exist, create one
        if (config.subId == 0) {
            // deploys a new CreateSubscription contract from Interactions.s.sol and save it as a variable named createSubscription
            CreateSubscription createSubscription = new CreateSubscription();
            // calls the createSubscription contract's createSubscription function and passes the vrfCoordinator from the networkConfigs dependent on the chain we are on. This will create a subscription for our vrfCoordinator. Then we save the return values of the subId and vrfCoordinator and vrfCoordinator as the subId and values in our networkConfig.
            (config.subId, config.vrfCoordinator) =
                createSubscription.createSubscription(config.vrfCoordinator, config.account);

            // creates and deploys a new FundSubscription contract from the Interactions.s.sol file.
            FundSubscription fundSubscription = new FundSubscription();
            // calls the `fundSubscription` function from the FundSubscription contract we just created and pass the parameters that it takes.
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subId, config.link, config.account);
        }

        // everything between startBroadcast and stopBroadcast is broadcasted to a real chain and the account from the helperConfig is the one making the transactions
        vm.startBroadcast(config.account);
        // create a new raffle contract with the parameters that are in the Raffle's constructor. This HAVE to be in the same order as the constructor!
        Raffle raffle = new Raffle(
            // we do `config.` before each one because our helperConfig contract grabs the correct config dependent on the chain we are deploying to
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subId,
            config.callBackGasLimit
        );
        vm.stopBroadcast();

        // creates and deploys a new AddConsumer contract from the Interactions.s.sol file.
        AddConsumer addConsumer = new AddConsumer();
        // calls the `addConsumer` function from the `AddConsumer` contract we just created/deplyed and pass the parameters that it takes.
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subId, config.account);

        // returns the new raffle and helperconfig that we just defined and deployed so that these new values can be used when this function `deployContracts` is called
        return (raffle, helperConfig);
    }
}
