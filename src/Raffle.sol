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
contract Raffle {
    /* CUSTOM ERRORS */
    error Raffle__SendMoreToEnterRaffle(); // custom errors save gas

    // this varibale is private so we need to make a getter function for it.
    uint256 private immutable i_entranceFee; // we made this private to save gas.

    // address array(list) of players who enter the raffle
    address payable[] private s_players; // this array is NOT constant because this array will be updated everytime a new person enters the raffle.
    // ^ this is payable because someone in this raffle will win the money and they will need to be able to receive the payout

    /* Events */
    // events are a way to allow the smart contract to listen for updates.
    event RaffleEntered(address indexed player); // the player is indexed because this means
    // ^ the player is indexed because events are logged to the EVM. Indexed data in events are essentially the important information that can be easily queried on the blockchain. Non-Indexed data are abi-encoded and difficult to decode.

    constructor(uint256 entranceFee) {
        // entranceFee gets set in the deployment script of the contract
        i_entranceFee = entranceFee;
    }

    function enterRaffle() external payable {
        // users must send more than or equal to the entranceFee or the function will revert
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!"); // this is no good because string revert messages cost TOO MUCH GAS!

        // if a user sends less than the entranceFee, it will revert with the custom error
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        } // this is the best way to write conditionals because they are so gas efficent.

        // when someone enters the raffle, `push` them into the array
        s_players.push(payable(msg.sender)); // we need the payable keyword to allow the address to receive eth when they will the payout

        // an event is emitted the msg.sender is added the the array/when a user successfully calls enterRaffle()
        emit RaffleEntered(msg.sender); // everytime we update storage, we always want to emit an event
    }

    function pickWinner() external {}

    ////////////////////////
    /*  Getter Functions */
    ///////////////////////

    // gets the i_entranceFee variable.
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    // function getPlayers(address ) external view returns (address) {
    //     return s_players
    // }
}
