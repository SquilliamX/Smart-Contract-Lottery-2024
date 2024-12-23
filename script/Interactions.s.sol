// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

// to use chainLink VRF, we need to create a subscription so that we are the only ones that can call our vrf.
// this is how you do it programically.

// we made this interactions file because it makes our codebase more modular and if we want to create more subscriptions in the future, we can do it right from the command line

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        // deploys a new helperConfig contract so we can interact with it
        HelperConfig helperConfig = new HelperConfig();
        // calls `getConfig` function from HelperConfig contract, this returns the networkConfigs struct, by but doing `getConfig().vrfCoordinator` it only grabs the vrfCoordinator from the struct. Then we save it as a variable named vrfCoordinator in this contract
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        // runs the createSubscription with the `vrfCoordinator` that we just saved as the parameter address and saves the return values of subId.
        // (uint256 subId,) = createSubscription(vrfCoordinator, account);

        return createSubscription(vrfCoordinator, account);
    }

    // created another function so that it can be even more modular
    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
        console.log("Creating Subscription on chain Id:", block.chainid);
        // everything between startBroadcast and stopBroadcast will be broadcasted to the blockchain and from the account that is passed into it.
        vm.startBroadcast(account);
        // VRFCoordinatorV2_5Mock inherits from SubscriptionAPI.sol where the createSubscription lives
        // calls the VRFCoordinatorV2_5Mock contract with the vrfCoordinator as the input parameter and calls the createSubscription function within the VRFCoordinatorV2_5Mock contract.
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your subscription Id is: ", subId);
        console.log("Please update the subscription Id in your HelperConfig.s.sol");

        return (subId, vrfCoordinator);
    }

    function run() external returns (uint256, address) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    // this says ether, but it really is (chain)LINK, since there are 18 decimals in the (CHAIN)LINK token as well
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        // deploys a new helperConfig contract so we can interact with it
        HelperConfig helperConfig = new HelperConfig();
        // calls `getConfig` function from HelperConfig contract, this returns the networkConfigs struct, by but doing `getConfig().vrfCoordinator` it only grabs the vrfCoordinator from the struct. Then we save it as a variable named vrfCoordinator in this contract
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        // in our DeployRaffle, we are updating the subId with the new subscription id we are generating. Here, we call the subId that we are updating the network configs with(in the deployment script).
        uint256 subId = helperConfig.getConfig().subId;
        // calls the getConfig function from helperConfig and gets the link address and saves it as a variable named link
        address link = helperConfig.getConfig().link;
        //
        address account = helperConfig.getConfig().account;

        if (subId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint256 updatedSubId, address updatedVRFv2) = createSub.run();
            subId = updatedSubId;
            vrfCoordinator = updatedVRFv2;
            console.log("New SubId Created! ", subId, "VRF Address: ", vrfCoordinator);
        }
        // runs `fundSubscription` function (below) and inputs the following parameters (we just defined these variables in this function)
        fundSubscription(vrfCoordinator, subId, link, account);
    }

    function fundSubscription(address vrfCoordinator, uint256 subId, address link, address account) public {
        console.log("Funding subscription: ", subId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On Chain: ", block.chainid);

        // if we are on Anvil (local fake blockchain) then deploy a mock and pass it our vrfCoordinator address
        if (block.chainid == LOCAL_CHAIN_ID) {
            // everything between startBroadcast and stopBroadcast will be broadcasted to the blockchain.
            vm.startBroadcast(account);
            // call the fundSubscription function with the subId and the value amount. This
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            console.log(LinkToken(link).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkToken(link).balanceOf(address(this)));
            console.log(address(this));
            // everything between startBroadcast and stopBroadcast will be broadcasted to the blockchain and the account passed in will be the one making the transactions.
            vm.startBroadcast(account);
            // otherwise, if we are on a real blockchain call `transferAndCall` function from the link token contract and pass the vrfCoordinator address, the value amount we are funding it with and encode our subId so no one else sees it.
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        // deploys a new helperConfig contract so we can interact with it
        HelperConfig helperConfig = new HelperConfig();
        // calls for the `subId` from the networkConfigs struct that getConfig returns from the HelperConfig contract
        uint256 subId = helperConfig.getConfig().subId;
        // calls for the `vrfCoordinator` from the networkConfigs struct that getConfig returns from the HelperConfig contract
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        // calls for the `account` from the networkConfigs struct that getConfig returns from the HelperConfig contract and saves it as an a variable named account.
        address account = helperConfig.getConfig().account;
        // calls `addConsumer` and passes the mostRecentlyDeployed, vrfCoordinator, subId as parameters. we just identified `vrfCoordinator` and `subId`. `mostRecentlyDeployed` get passed in when the run function is called.
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId, account);
    }

    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subId, address account) public {
        console.log("Adding consumer contract: ", contractToAddToVrf);
        console.log("To vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainId: ", block.chainid);
        // everything between startBroadcast and stopBroadcast will be broadcasted to the blockchain and will broadcast it from the account passed(this account will make the transactions).
        vm.startBroadcast(account);
        // calls `addConsumer` from the `VRFCoordinatorV2_5Mock` and it takes the parameters of the subId and consumer (so we pass the subId and contractToAddToVrf.)
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function run() external {
        // calls the `get_most_recent_deployment` function from the DevOpsTools library in order to get the most recently deployed version of our Raffle smart contract.
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        // calls the `addConsumerUsingConfig` and passed the most recently deployed raffle contract as its parameter.
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
