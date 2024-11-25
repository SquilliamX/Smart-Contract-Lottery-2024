// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    /* VRF Mock Values */
    // values that are from chainlinks mock constructor
    uint96 public MOCK_BASE_FEE = 0.25 ether; // when we work with chainlink VRF we need to pay a certain amount of link token. The base fee is the flat value we are always going to pay
    uint96 public MOCK_GAS_PRICE_LINK = 1e19; // when the vrf responds, it needs gas, so this is the cost of the gas that we spend to cover for it. This calculation is how much link per eth are we going to use?
    int256 public MOCK_WEI_PER_UNIT_LINK = 4_16; // link to eth price in wei
    // ^ these are just fake values for anvil ^

    // chainId for Sepolia
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    // chainId for anvil
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainID();

    // these are the items that the constructor in DeployRaffle.s.sol takes
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinatior;
        bytes32 gasLane;
        uint32 callBackGasLimit;
        uint256 subscriptionId;
    }

    // creating a variable named localNetworkConfig of type struct NetworkConfig
    NetworkConfig public localNetworkConfig;

    // mapping a chainId to the struct NetworkConfig so that each chainId has its own set of NetworkConfig variables.
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        // mapping the chainId 11155111 to the values in getSepoliaEthConfig
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        // if the if the vrf.coordinator address does exist on the chain we are on,
        if (networkConfigs[chainId].vrfCoordinatior != address(0)) {
            // then return the all the values in the NetworkConfig struct
            return networkConfigs[chainId];
            // if we are on the local chain, return the getOrCreateAnvilEthConfig() function
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
            // otherwise revert with an error
        } else {
            revert HelperConfig__InvalidChainID();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.1 ether, // 1e16 // 16 zeros
            interval: 30, // 30 seconds
            vrfCoordinatior: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B, // got this from the chainlink docs here: https://docs.chain.link/vrf/v2-5/supported-networks
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // // got this keyhash from the chainlink docs here: https://docs.chain.link/vrf/v2-5/supported-networks
            callBackGasLimit: 500000, // 500,000 gas
            subscriptionId: 0
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinatior != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.1 ether, // 1e16 // 16 zeros
            interval: 30, // 30 seconds
            vrfCoordinatior: address(vrfCoordinatorMock), // the address of the vrfCoordinatorMock
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // does not matter since this is on anvil
            callBackGasLimit: 500000, // 500,000 gas, but it does not matter since this is on anvil
            subscriptionId: 0
        });
        return localNetworkConfig;
    }
}
