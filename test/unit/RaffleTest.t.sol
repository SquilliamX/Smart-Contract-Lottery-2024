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

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

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

    function testEnteringRaffleEmitsEvent() public {
        // Arrange
        // next transaction will come from the PLAYER address that we made
        vm.prank(PLAYER);
        // Act
        // because we have an indexed parameter in slot 1 of the event, it is true. However we have no data in slot 2, 3, and 4  so they are false. `address(raffle) is the contract emitting the event`
        // we expect the next event to have these parameters.
        vm.expectEmit(true, false, false, false, address(raffle));
        // the event that should be expected to be emitted from the next transaction
        emit RaffleEntered(PLAYER);
        // Assert
        // PLAYER makes this transaction of entering the raffle and this should emit the event we are testing for.
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // Arrange
        // next transaction will come from the PLAYER address that we made
        vm.prank(PLAYER);
        // PLAYER pays the entrance fee and enters the raffle
        raffle.enterRaffle{value: entranceFee}();
        // vm.warp allows us to warp time ahead so that foundry knows time has passed.
        vm.warp(block.timestamp + interval + 1); // current timestamp + the interval of how long we can wait before starting another audit plus 1 second.
        // vm.roll rolls the blockchain forward to the block that you assign. So here we are only moving it up 1 block to make sure that enough time has passed to start the lottery winner picking in raffle.sol
        vm.roll(block.number + 1);
        // now we can call performUpkeep and this will change the state of the raffle contract from open to calculating, which should mean no one else can join.
        raffle.performUpkeep("");
        // Act / Assert
        // we expect the next transaction to revert with the custom error of `Raffle__RaffleNotOpen`
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        // next transaction will come from the PLAYER address that we made
        vm.prank(PLAYER);
        // we expect this to fail since the raffle is no longer open!
        raffle.enterRaffle{value: entranceFee}();
    }
}
