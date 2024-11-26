// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {
    // variable named raffle of type Contract Raffle
    Raffle public raffle;
    // variable named helperConfig of type contract HelperConfig
    HelperConfig public helperConfig;

    // making a fake user named `PLAYER`
    address public PLAYER = makeAddr("player");
    // the ammount we are going to give `PLAYER`
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinatior;
    bytes32 gasLane;
    uint32 callBackGasLimit;
    uint256 subscriptionId;

    function setUp() external {
        // deploy a new deployRaffle script named `deployer`
        DeployRaffle deployer = new DeployRaffle();
        // call `deployContract` from `DeployRaffle` script/contract and it returns the raffle contract and the helperconfig contract.
        (raffle, helperConfig) = deployer.deployContract();
        //grab the network configs of the chain we are deploying to and save them as `config`.
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        // initializing the variables from the constructor dependent on the chain that we are on.
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinatior = config.vrfCoordinatior;
        gasLane = config.gasLane;
        callBackGasLimit = config.callBackGasLimit;
        subscriptionId = config.subscriptionId;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        // testing to see if the raffle state is open when the raffle starts
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleEvertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER); // the next transaction will be the PLAYER address that we made
        // Act / Assert
        // expect the next transaction to revert with the custom error Raffle__SendMoreToEnterRaffle.
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        // call the Enter Raffle with 0 value (the PLAYER is calling this and we expect it to evert since we are sending 0 value)
        raffle.enterRaffle();
    }

    function testFalleRecordsPlayerWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: entranceFee}();
        // Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }
}
