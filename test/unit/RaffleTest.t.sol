// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {LinkToken} from "../mocks/LinkToken.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Vm} from "forge-std/Vm.sol";

contract RaffleTest is Test, CodeConstants {
    // variable named raffle of type Contract Raffle
    Raffle public raffle;
    // variable named helperConfig of type contract HelperConfig
    HelperConfig public helperConfig;

    // making a fake user named `PLAYER`
    address public PLAYER = makeAddr("player");
    // the ammount we are going to give `PLAYER`
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;
    uint256 public constant LINK_BALANCE = 100 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callBackGasLimit;
    uint256 subscriptionId;
    LinkToken link;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        // deploy a new deployRaffle script named `deployer`
        DeployRaffle deployer = new DeployRaffle();
        // call `deployContract` from `DeployRaffle` script/contract and it returns the raffle contract and the helperconfig contract.
        (raffle, helperConfig) = deployer.deployContract();
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);

        //grab the network configs of the chain we are deploying to and save them as `config`.
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        // initializing the variables from the constructor dependent on the chain that we are on.
        subscriptionId = config.subscriptionId;
        gasLane = config.gasLane;
        interval = config.interval;
        entranceFee = config.entranceFee;
        callBackGasLimit = config.callBackGasLimit;
        vrfCoordinator = config.vrfCoordinator;
        link = LinkToken(config.link);

        vm.startPrank(msg.sender);
        if (block.chainid == LOCAL_CHAIN_ID) {
            link.mint(msg.sender, LINK_BALANCE);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, LINK_BALANCE);
        }
        link.approve(vrfCoordinator, LINK_BALANCE);
        vm.stopPrank();
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

    /* CHECK UPKEEP */

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // vm.warp allows us to warp time ahead so that foundry knows time has passed.
        vm.warp(block.timestamp + interval + 1); // current timestamp + the interval of how long we can wait before starting another audit plus 1 second.
        // vm.roll rolls the blockchain forward to the block that you assign. So here we are only moving it up 1 block to make sure that enough time has passed to start the lottery winner picking in raffle.sol
        vm.roll(block.number + 1);
        // calling checkUpkeep in the raffle contract and grabbing its true or false state.
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // asserting the checkUpkeep is false/ is not needed
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
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

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    /* PERFORM UPKEEP TESTS */

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        // next transaction will come from the PLAYER address that we made
        vm.prank(PLAYER);
        // PLAYER pays the entrance fee and enters the raffle
        raffle.enterRaffle{value: entranceFee}();
        // vm.warp allows us to warp time ahead so that foundry knows time has passed.
        vm.warp(block.timestamp + interval + 1); // current timestamp + the interval of how long we can wait before starting another audit plus 1 second.
        // vm.roll rolls the blockchain forward to the block that you assign. So here we are only moving it up 1 block to make sure that enough time has passed to start the lottery winner picking in raffle.sol
        vm.roll(block.number + 1);

        // Act / Assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        // start the current balance of the raffle contract at 0
        uint256 currentBalance = 0;
        // the raffle has 0 players
        uint256 numPlayers = 0;
        // we get the raffle state, which should be open since no one is in the raffle yet
        Raffle.RaffleState rState = raffle.getRaffleState();

        // the next transaction will be by PLAYER
        vm.prank(PLAYER);
        // the player enters the raffle and pays the entrance fee
        raffle.enterRaffle{value: entranceFee}();
        // the balance is now updated with the new entrance fee
        currentBalance = currentBalance + entranceFee;
        // PLAYER is the one person in the raffle
        numPlayers = 1;

        // Act / Assert
        // we expect the next call to fail with the custom error of Raffle__UpkeepNotNeeded
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, rState)
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRafflesStateAndEmitsRequestId() public {
        // Arrange
        vm.prank(PLAYER);
        // PLAYER pays the entrance fee and enters the raffle
        raffle.enterRaffle{value: entranceFee}();
        // vm.warp allows us to warp time ahead so that foundry knows time has passed.
        vm.warp(block.timestamp + interval + 1); // current timestamp + the interval of how long we can wait before starting another audit plus 1 second.
        // vm.roll rolls the blockchain forward to the block that you assign. So here we are only moving it up 1 block to make sure that enough time has passed to start the lottery winner picking in raffle.sol
        vm.roll(block.number + 1);

        // Act
        // record all logs(including event data) from the next call
        vm.recordLogs();
        // call performUpkeep
        raffle.performUpkeep("");
        // take the recordedLogs from `performUpkeep` and stick them into the entries array
        Vm.Log[] memory entries = vm.getRecordedLogs();
        // entry 0  is for the VRF coordinator
        // entry 1 is for our event data
        // topic 0 is always resevered for
        // topic 1 is for our indexed parameter
        bytes32 requestId = entries[1].topics[1];

        // Assert
        // gets the raffleState and saves it in a variable named raffleState
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        // assert that the requestId was indeed sent, if it was zero then no request Id was sent.
        assert(uint256(requestId) > 0);
        // this is asserting that the raffle state is `calculating` instead of `OPEN`
        assert(uint256(raffleState) == 1);
        // this is the same as saying what is below:
        // assert(raffleState == Raffle.RaffleState.CALCULATING);
        //         enum RaffleState {
        //     OPEN,      // index 0
        //     CALCULATING // index 1
        // }
    }
}