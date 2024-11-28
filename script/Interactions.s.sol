// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

// to use chainLink VRF, we need to create a subscription so that we are the only ones that can call our vrf.
// this is how you do it programically.

// we made this interactions file because it makes our codebase more modular and if we want to create more subscriptions in the future, we can do it right from the command line

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        // deploys a new helperConfig contract so we can interact with it
        HelperConfig helperConfig = new HelperConfig();
        // calls `getConfig` function from HelperConfig contract, this returns the networkConfigs struct, by but doing `getConfig().vrfCoordinator` it only grabs the vrfCoordinator from the struct. Then we save it as a variable named vrfCoordinator in this contract
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        // runs the createSubscription with the `vrfCoordinator` that we just saved as the parameter address and saves the return values of subId.
        (uint256 subId,) = createSubscription(vrfCoordinator);

        return (subId, vrfCoordinator);
    }

    // created another function so that it can be even more modular
    function createSubscription(address vrfCoordinator) public returns (uint256, address) {
        console.log("Creating Subscription on chain Id:", block.chainid);
        // everything between startBroadcast and stopBroadcast will be broadcasted to the blockchain.
        vm.startBroadcast();
        // VRFCoordinatorV2_5Mock inherits from SubscriptionAPI.sol where the createSubscription lives
        // calls the VRFCoordinatorV2_5Mock contract with the vrfCoordinator as the input parameter and calls the createSubscription function within the VRFCoordinatorV2_5Mock contract.
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your subscription Id is: ", subId);
        console.log("Please update the subscription Id in your HelperConfig.s.sol");

        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundScription is Script, CodeConstants {
    // this says ether, but it really is (chain)LINK, since there are 18 decimals in the (CHAIN)LINK token as well
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundScriptionUsingConfig() public {
        // deploys a new helperConfig contract so we can interact with it
        HelperConfig helperConfig = new HelperConfig();
        // calls `getConfig` function from HelperConfig contract, this returns the networkConfigs struct, by but doing `getConfig().vrfCoordinator` it only grabs the vrfCoordinator from the struct. Then we save it as a variable named vrfCoordinator in this contract
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        // in our DeployRaffle, we are updating the subscriptionId with the new subscription id we are generating. Here, we call the subscriptionId that we are updating the network configs with(in the deployment script).
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        // calls the getConfig function from helperConfig and gets the link address and saves it as a variable named linkToken
        address linkToken = helperConfig.getConfig().link;
        // runs `fundSubscription` function (below) and inputs the following parameters (we just defined these variables in this function)
        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
        console.log("Funding subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On Chain: ", block.chainid);

        // if we are on Anvil (local fake blockchain) then deploy a mock and pass it our vrfCoordinator address
        if (block.chainid == LOCAL_CHAIN_ID) {
            // everything between startBroadcast and stopBroadcast will be broadcasted to the blockchain.
            vm.startBroadcast();
            // call the fundSubscription function with the subscriptionId and the value amount. This
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            // everything between startBroadcast and stopBroadcast will be broadcasted to the blockchain.
            vm.startBroadcast();
            // otherwise, if we are on a real blockchain call `transferAndCall` function from the link token contract and pass the vrfCoordinator address, the value amount we are funding it with and encode our subscriptionID so no one else sees it.
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundScriptionUsingConfig();
    }
}
