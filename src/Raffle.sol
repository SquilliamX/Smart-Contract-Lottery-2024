// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * Solidty files should be ordered correctly:
 * // solidity version
 * // imports
 * // errors
 * // interfaces, libraries, contracts
 * // Type declarations
 * // State variables
 * // Events
 * // Modifiers
 * // Functions
 *
 * // Layout of Functions:
 * // constructor
 * // receive function (if exists)
 * // fallback function (if exists)
 * // external
 * // public
 * // internal
 * // private
 * // internal & private view & pure functions
 * // external & public view & pure functions
 *
 *
 * /**
 * @title A Raffle Contract written in Solidity
 * @author Squilliam
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */

// importing the Chainlink VRF
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

// inheriting the Chainlink VRF
contract Raffle is VRFConsumerBaseV2Plus {
    /* CUSTOM ERRORS */

    error Raffle__SendMoreToEnterRaffle(); // custom errors save gas
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();

    /* Type Declarations */
    enum RaffleState {
        OPEN, // index 0
        CALCULATING // index 1

    }

    /* State Variables */

    // this is a uint16 because it will be a very small number and will never change.
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // // how many blocks the VRF should wait before sending us the random number

    uint32 private constant NUM_WORDS = 1; // the number of random numbers that we want

    // this is being declared to identify its type of uint256. this will be how much it costs to enter the raffle. it is being initialized in the constructor and will be set when the contract is deployed through the deployment script.
    uint256 private immutable i_entranceFee; // we made this private to save gas. because it is private we need a getter function for it

    // this variable is declared to set the interval of how long each raffle will be. it is being initialized in the constructor and will be set when the contract is deployed through the deployment script.
    // @dev the duration of the lottery in seconds.
    uint256 private immutable i_interval;
    // the amount of gas we are willing to send for the chainlink VRF
    bytes32 private immutable i_keyHash;
    // kinda linke the serial number for the request to Chainlink VRF
    uint256 private immutable i_subscriptionId;
    // Max amount of gas you are willing to spend when the VRF sends the RNG back to you
    uint32 private immutable i_callbackGasLimit;

    // address array(list) of players who enter the raffle
    address payable[] private s_players; // this array is NOT constant because this array will be updated everytime a new person enters the raffle.
    // ^ this is payable because someone in this raffle will win the money and they will need to be able to receive the payout

    //  the last saved block.timestamp.
    uint256 private s_lastTimeStamp;

    // the payable address of the winner of the most recent lottery
    address payable private s_recentWinner;

    // The state of the raffle of type RaffleState(enum)
    RaffleState private s_raffleState;

    /* Events */
    // events are a way to allow the smart contract to listen for updates.
    event RaffleEntered(address indexed player); // the player is indexed because this means
    // ^ the player is indexed because events are logged to the EVM. Indexed data in events are essentially the important information that can be easily queried on the blockchain. Non-Indexed data are abi-encoded and difficult to decode.

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        // entranceFee gets set in the deployment script(when the contract is being deployed).
        i_entranceFee = entranceFee;
        // interval gets set in the deployment script(when the contract is being deployed).
        i_interval = interval;
        // keyHash to chainlink means the amount of max gas we are willing to pay. So we named it gasLane because we like gasLane as the name more
        i_keyHash = gasLane;
        // sets i_subscriptionId equal to the one set at deployment
        i_subscriptionId = subscriptionId;
        // Max amount of gas you are willing to spend when the VRF sends the RNG back to you
        i_callbackGasLimit = callbackGasLimit;

        // sets the s_lastTimeStamp variable to the current block.timestamp when deployed.
        s_lastTimeStamp = block.timestamp;

        // when the contract is deployed it will be open
        s_raffleState = RaffleState.OPEN; // this would be the same as s_raffleState = RaffleState.(0) since open in the enum is in index 0
    }

    // the payable keyword allows users to send money to this function
    function enterRaffle() external payable {
        // users must send more than or equal to the entranceFee or the function will revert
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!"); // this is no good because string revert messages cost TOO MUCH GAS!

        // if a user sends less than the entranceFee, it will revert with the custom error
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        } // this is the best way to write conditionals because they are so gas efficent.

        // if the raffle is not open then any transactions to enterRaffle will revert
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        // when someone enters the raffle, `push` them into the array
        s_players.push(payable(msg.sender)); // we need the payable keyword to allow the address to receive eth when they will the payout

        // an event is emitted the msg.sender is added the the array/when a user successfully calls enterRaffle()
        emit RaffleEntered(msg.sender); // everytime we update storage, we always want to emit an event
    }

    function pickWinner() external {
        // this checks to see if enough time has passed
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
        // when someone calls the pickWinner, users will no longer be able to join the raffle since the state of the raffle has changed to calculating and is no longer open.
        s_raffleState = RaffleState.CALCULATING;

        // calling to Chainlink VRF to get a randomNumber
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash, // how much gas you are willing to pay
                subId: i_subscriptionId, // kinda of like a serial number for the request
                requestConfirmations: REQUEST_CONFIRMATIONS, // how many blocks the VRF should wait before sending us the random number
                callbackGasLimit: i_callbackGasLimit, // Max amount of gas you are willing to spend when the VRF sends the RNG back to you
                numWords: NUM_WORDS, // the number of random numbers that we want
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // randomWords is 0 because we are only calling for 1 Random number from chainlink VRF and the index starts at 0, so this represets the 1 number we called for.
        uint256 indexOfWinner = randomWords[0] % s_players.length; // this says the number that is randomly generated modulo the amount of players in the raffle
        //  ^ modulo means the remainder of the division. So if 52(random Number) % 20(amount of people in the raffle), this will equal 12 because 12 is the remainder! So whoever is in the 12th spot will win the raffle. And this is saved into the variable indexOfWinner ^

        // the remainder of the modulo equation will be identified within the s_players array and saved as the recentWinner
        address payable recentWinner = s_players[indexOfWinner];

        // update the storage variable with the recent winner
        s_recentWinner = recentWinner;

        // the state of the raffle changes to open so players can join again.
        s_raffleState = RaffleState.OPEN;

        // pay the recent winner with the whole amount of the contract
        (bool success,) = s_recentWinner.call{value: address(this).balance}("");
        // if not success then revert
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    ////////////////////////
    /*  Getter Functions */
    ///////////////////////

    // gets the i_entranceFee variable.
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getInterval() external view returns (uint256) {
        return i_entranceFee;
    }

    // function getPlayers(address ) external view returns (address) {
    //     return s_players
    // }
}
