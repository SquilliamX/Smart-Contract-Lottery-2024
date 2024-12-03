# Notes 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Getting Started Notes

To start a new foundry project, run `forge init`
To compile a foundry project, run `forge build`
to run tests, run `forge test`
to install packages, run `forge install` with a `--no-commit` at the end

`forge` is used to compile and interact with our contracts
`cast` is used to interact with contracts that have already been deployed.
`anvil` is used to spin up a local blockchain in out terminal for testing. 

every smart contract should start with the following:

```javascript
// SPDX-License-Identifier: MIT // like always
pragma solidity 0.8.18; // like always

contract ThisIsAnExample {/* contract logic goes here */} 
```


### Layout of Solidity Files/Contracts:

Solidty files should be ordered correctly:
 1. solidity version
 2. imports
 3. errors
 4. interfaces
 5. libraries
 6. contracts
 7. Type declarations
 8. State variables
 9. Events
 10. Modifiers
 11. Functions

Layout of Functions:
 1. constructor
 2. receive function (if exists)
 3. fallback function (if exists)
 4. external
 5. public
 6. internal
 7. private
 8. internal & private view & pure functions
 9. external & public view & pure functions


### CEI (Checks, Effects, Interactions) Notes
 When writing smart contacts, you always want to follow the CEI (Checks, Effects, Interactions) pattern in order to prevent reentrancy vulnerabilities and other vulnerabilities.
 This would look like

 ```js
function exampleCEI() public {
    // Checks
    // so this would be like require statements/conditionals

    // Effects
    // this would be updating all variables and emitting events

    // Interactions
    // This would be anything that interacts with users or the world. Examples include sending money to users, sending nfts, etc
}
 ```


### Modifier Notes:

Sometimes you will type alot of the same code over and over. To keep things simple and non-redundant, you can use a modifier.

Modifiers are written with a `_;` before/after the code logic. The `_;` means to execute the code before or after the modifier code logic. The modifier will always execute first in the code function so `_;` represents whether to execute the function logic before or after the modifier.
example:
```js
 modifier raffleEntered() {
        vm.prank(PLAYER);
        // PLAYER pays the entrance fee and enters the raffle
        raffle.enterRaffle{value: entranceFee}();
        // vm.warp allows us to warp time ahead so that foundry knows time has passed.
        vm.warp(block.timestamp + interval + 1); // current timestamp + the interval of how long we can wait before starting another audit plus 1 second.
        // vm.roll rolls the blockchain forward to the block that you assign. So here we are only moving it up 1 block to make sure that enough time has passed to start the lottery winner picking in raffle.sol
        vm.roll(block.number + 1);
        // completes the rest of the function that this modifier is applied to
        _;
    }
```
In this example the `_;` is after the modifier code logic to say that the modifier should be executed first, then the function it is applied to's logic should be execute afterwards. If the `_;` was before the modifier code logic, then it whould mean to execute the function it is applied to's logic before the modifier and then do the modifier logic afterwards 


Modifiers go after the visibility modifiers in the function declaration. 
example:
```js
 function testPerformUpkeepUpdatesRafflesStateAndEmitsRequestId() public raffleEntered {
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
```
In this example, the modifier is `raffleEntered`. 

### Visibility Modifier Notes: 

There are 4 types of visibility modifiers in solidity. Public, Private, External, Internal.

1. Public:
Accessible from anywhere (inside contract, other contracts, and externally)
Automatically creates a getter function for state variables
Most permissive modifier
Example:
```javascript
contract Example {
    uint public myNumber; // Creates automatic getter
    
    function publicFunction() public {
        // Can be called from anywhere
    }
}
```

2. Private: 
Only accessible within the contract where it's defined
Cannot be accessed from derived contracts or externally
Most restrictive modifier
Private variables are still visible on the blockchain
Needs a Getter Function to be used/called outside the contract where it's defined.
Example:
```javascript
contract Example {
    uint private secretNumber; // Only this contract can access
    
    function privateFunction() private {
        // Only callable from within this contract
    }
}
```

3. Internal:
Accessible within the current contract and contracts that inherit from it
Cannot be accessed externally
Default visibility for state variables
Example:
```javascript
contract Base {
    uint internal sharedNumber; // Accessible by inheriting contracts
    
    function internalFunction() internal {
        // Callable from this contract and inherited contracts
    }
}

contract Example is Base {
    function useInternal() public {
        internalFunction(); // Can access internal members
        sharedNumber = 5;   // Can access internal variables
    }
}
```

4. External
Only accessible from outside the contract
Cannot be called internally (except using this.function())
More gas efficient for large data parameters
Only available for functions (not state variables)
Example:
```javascript
contract Example {
    function externalFunction() external {
        // Only callable from outside
    }
    
    function someFunction() public {
        // this.externalFunction(); // Need 'this' to call external function
    }
}
```

*** Key points to remember: ***
1. State Variable Default Visibility:
- If you don't specify visibility, state variables are internal by default

2. Function Default Visibility:
- Functions without specified visibility are public by default
- However, it's considered best practice to always explicitly declare visibility

3. Visibility Access Levels (from most to least restrictive):
    private - internal - external/public

4. Gas Considerations:
- external functions can be more gas-efficient when dealing with large arrays in memory
- public functions create an additional JUMP in the bytecode which costs more gas

5. Security Best Practices:
- Always use the most restrictive visibility possible
- Be explicit about visibility (don't rely on defaults)
- Remember that private doesn't mean secret - data is still visible on the blockchain

### Variable Notes
All of the value types variables are: `boolean`, `unit`(only positive), `int`(postive or negative), `string`, `bytes`, `address`

The reference types of variables are: `arrays`, `structs`, `mappings`. 


The Followings variable must be declared at the contract level (not in any functions):

#### Constant Notes
Variables that will never be updated or changed can be listed as constant. 
For example:
`uint8 public constant DECIMALS = 8; ` - constant veriable should be CAPITALIZED as seen in this example.
Constant variables are directly embedded in the bytecode. This saves gas.
`constant` is a state mutability modifier.

#### Immutable Note
Variables that are declared at the contract level but initialized in the constructor can be listed as Immutable. This saves gas.
For Example:
```javascript
address public immutable i_owner; // As you can see immutable variables should be named with an `i_` infront of the name

 constructor() {
        i_owner = msg.sender; // As you can see immutable variables should be named with an `i_` infront of the name
    }
``` 
Immutable variables are directly embedded in the bytecode when the contract is deployed and can only be set once during contract construction.
`immutable` is a state mutability modifier.

#### Storage Variable Notes
Variables that are not constant or immutable but are declared at the contract level at saved in storage. So these variables should be named with `s_`.
For Example:
```javascript
    address[] public s_funders;
    mapping(address funder => uint256 amountFunded) public s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;
```
State Variables declared at contract level by default ARE stored in storage.
Storage variables are mutable by default (can be changes at anytime), so there isn't a specific state mutability modifier.


#### Saving Gas with Storage Variable Notes

If you have a storage variable or immutable variables (not constant variables), then you can save gas and make the contract more reeadable by making the storage/immutable variables `private` and making a getter function that grabs the storage variable.
Example:
```javascript  

    // an array of addresses called funders.
    address[] private s_funders;

    // a mapping, mapping the addresses and their amount funded.
    // the names "funder" and "amountFunded" is "syntaxic sugar", just makes it easier to read
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;

    // to be used in constructor
    address private immutable i_owner; // variables defined in the constructor, can be marked as immutable if they will not change. This will save gas
    // immutable varibles should use "i_" in their name

  /**
     * View / Pure Functions (These are going to be our Getters)
     * Below are our Getter functions. by making storage variables private, they save more gas. Then by making view/pure functions to get the data within the private storage functions, it also makes the code much more readable.
     * These are called getter functions because all they do is read and return private data from the contracts storage without modifying the contract state.
     */

    // This function allows anyone to check how much eth a specific address has funded to the contract.
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        // takes the fundingAddress parameter that users input and reads and returns the amount that that address has funded. It is accessing the mapping of s_addressToAmountFunded which stores the funding history.
        return s_addressToAmountFunded[fundingAddress];
    }

    //this function allows anyone to input a number(index) and they will see whos address is at that index(number).
    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
```

#### Custom Error Variable Notes

Reverting with strings is not good because it costs too much gas. Instead, save the error as a custome error and revert with the custom error.
Example:
```javascript
contract Raffle {
    error Raffle__SendMoreToEnterRaffle(); // custom errors save gas

    function enterRaffle() public payable {
        // users must send more than or equal to the entranceFee or the function will revert
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!"); // this is no good because string revert messages cost TOO MUCH GAS!

        // if a user sends less than the entranceFee, it will revert with the custom error
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        } // this is the best way to write conditionals because they are so gas efficent.
    }
}
```

To make custome errors even easier for users or devs to read when they get this error, we can let them know why they go this error:
Example
```js
contract Raffle {
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playerslength, uint256 raffleState);


    function performUpkeep(bytes calldata /* performData */ ) external {
        //
        (bool upkeepNeeded,) = checkUpkeep("");
        //
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(
                    s_raffleState /*This could be a Rafflestate raffleState as well. Since enums map to their indexed position it can also be uint256(s_raffleState) since we have this defined as well */
                )
            );
        }
}
```

#### Reference Types Variable Notes

The reference types of variables are: `arrays`, `structs`, `mappings`. 

##### Array Notes

There are two types of Arrays, static and dynamic.
Dynamic array: the size of the array can grow and shrink
Static array: the size is fixed: example: Person[3]


Setting up an array variable:
Examples:
```js
// an array of addresses called funders.
    address[] private s_funders;

// address array(list) of players who enter the raffle
address payable[] private s_players; // this array is NOT constant because this array will be updated everytime a new person enters the raffle.
// ^ this is payable because someone in this raffle will win the money and they will need to be able to receive the payout
```

Pushing items into an array example:
```js
 // You can create your own types by using the "struct" keyword
    struct Person {
        // for every person, they are going to have a favorite number and a name:
        uint256 favoriteNumber; // slot 0
        string name; // slot 1
    }

    //dynamic array of type struct person
    Person[] public listOfPeople; // Gets defaulted to a empty array

     // arrays come built in with the push function that allows us to add elements to an array
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // pushes(adds) a user defined person into the Person array
        listOfPeople.push(Person(_favoriteNumber, _name));

        // adds the created mapping to this function, so that when you look up a name, you get their favorite number back
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
```

To reset an array:
Example:
```js
 function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length; 
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;

        // s_players gets updated to a new address array of size 0 to start(since it removed all items in the array, it starts a 0) that is also payable
        s_players = new address payable[](0); // resets the array

        // updates the current timestamp into the most recent timestamp so we know when this raffle started
        s_lastTimeStamp = block.timestamp;

        (bool success,) = s_recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(s_recentWinner);
    }
```

##### Struct Notes
Structs are custom data types that let you create your own complex data structure by grouping together different variables. They're like creating a template for a custom object.

Example:
```js
 // You can create your own types by using the "struct" keyword
    struct Person {
        // for every person, they are going to have a favorite number and a name:
        uint256 favoriteNumber; // slot 0
        string name; // slot 1
    }

//dynamic array of type struct `person`
Person[] public listOfPeople; // Gets defaulted to a empty array

 // arrays come built in with the push function that allows us to add elements to an array
function addPerson(string memory _name, uint256 _favoriteNumber) public {
// pushes(adds) a user defined person into the Person array
listOfPeople.push(Person(_favoriteNumber, _name));
// adds the created mapping to this function, so that when you look up a name, you get their favorite number back
nameToFavoriteNumber[_name] = _favoriteNumber;
    }
```

##### Mapping Notes
Mappings are key-value pair data structures, similar to hash tables or dictionaries in other languages. They're unique in Solidity because all possible keys exist by default and map to a value of 0/false/empty depending on the value type.

examples:
```js
// mapping types are like a search functionality or dictionary
    mapping(string => uint256) public nameToFavoriteNumber;

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // pushes(adds) a user defined person into the Person array
        listOfPeople.push(Person(_favoriteNumber, _name));

        // adds the created MAPPING to this function, so that when you look up a name, you get their favorite number back
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
```
```js
    // a mapping, mapping the addresses and their amount funded.
    // the names "funder" and "amountFunded" is "syntaxic sugar", just makes it easier to read
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;

    function fund() public payable {
     
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "didn't send enough ETH");

        // this line keeps track of how much each sender has sent
        // you read it like: mapping(check the mapping) address => amount sent of the sender. So how much the sender sent = how much the sender has sent plus how much he is currently sending.
        // addressToAmountFunded[msg.sender] = addressToAmountFunded[msg.sender] + msg.value;
        //above is the old way. below is the shortcut with += . This += means we are adding the new value to the existing value that already exists.
        s_addressToAmountFunded[msg.sender] += msg.value;

        // the users whom successfully call this function will be added to the array.
        s_funders.push(msg.sender);
    }

     function cheaperWithdraw() public onlyOwner {
        uint256 funderLength = s_funders.length;
        for (uint256 funderIndex = 0; funderIndex < funderLength; funderIndex++) {
            address funder = s_funders[funderIndex];
            
            // then we reset this funders amount(this is tracked by the mapping of "addressToAmountFunded") to 0 when he withdraws
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) =
            payable(msg.sender).call{value: address(this).balance}(""); 
        require(callSuccess, "Call Failed");
    }

    /* Getter Function since the mapping is private to save gas */

     // This function allows anyone to check how much eth a specific address has funded to the contract.
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        // takes the fundingAddress parameter that users input and reads and returns the amount that that address has funded. It is accessing the mapping of s_addressToAmountFunded which stores the funding history.
        return s_addressToAmountFunded[fundingAddress];
    }
```


### Constructor Notes
Constructors are special functions that are executed only once when a contract is deployed.

Constructor Facts:
- Called once during contract creation
- Used to initialize state variables
- Cannot be called after contract deployment
- Only one constructor per contract

Example:
```js
contract Raffle {

    uint256 private immutable i_entranceFee; 
    uint256 private immutable i_interval;

    uint256 private s_lastTimeStamp;

    // this constructor takes a entranceFee and interval, so when the owner deploys this contract, he will input what these variables are equal to.
    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        // at contract deployment, the s_lastTimeStamp will record the timestamp of the block in which the contract is deployed. This value will be used as the initial timestamp for the raffle contract.
        s_lastTimeStamp = block.timestamp;
    }
}
```

### Event Notes
When a storage variable is updated, we should always emit an event. This makes migration/version-updates of contracts much easier and events make front-end "indexing" much easier. It allows for the smart contract, front-end, and blockchain to easily know when something has been updated. You can only have 3 indexed events per event and can have non indexed data. Indexed data is basically filtered data that is easy to read from the blockchain and non-indexed data will be abi-encoded on the blockchain and much much harder to read.

The indexed parameter in events are called "Topics".

Example:
```javascript

contract Raffle() {
    error Raffle__SendMoreToEnterRaffle(); 
    uint256 private immutable i_entranceFee; 
    address payable[] private s_players; 


/* Events */
    // events are a way to allow the smart contract to listen for updates.
    event RaffleEntered(address indexed player); // the player is indexed because this means 
    // ^ the player is indexed because events are logged to the EVM. Indexed data in events are essentially the important information that can be easily queried on the blockchain. Non-Indexed data are abi-encoded and difficult to decode.

    function enterRaffle() public payable {   
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        } 

        // when someone enters the raffle, `push` them into the array
        s_players.push(payable(msg.sender)); // we need the payable keyword to allow the address to receive eth when they will the payout

        // an event is emitted the msg.sender is added the the array/ when a user successfully calls enterRaffle()
        emit RaffleEntered(msg.sender); // everytime we update storage, we always want to emit an event
    }
}
```

### Enum Notes

An Enum (enumeration) is a type declaration. An enum is a way to create a user-defined type with a fixed set of constant values or states. It's useful for representing a fixed number of options or states in a more readable way.

Examples:
```js                                   
contract Raffle {

      /* Type Declarations */
        enum RaffleState {
        OPEN, // index 0
        CALCULATING // index 1
    }

    // The state of the raffle of type RaffleState(enum)
    RaffleState private s_raffleState;

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;

        // when the contract is deployed it will be open
        s_raffleState = RaffleState.OPEN; // this would be the same as s_raffleState = RaffleState.(0) since open in the enum is in index 0
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        // if the raffle is not open then any transactions to enterRaffle will revert
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender)); 
        emit RaffleEntered(msg.sender); 
    }

    function pickWinner() external {
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
        // when someone calls the pickWinner, users will no longer be able to join the raffle since the state of the raffle has changed to calculating and is no longer open.
        s_raffleState = RaffleState.CALCULATING;

       ...
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length; 
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        // the state of the raffle changes to open so players can join again.
        s_raffleState = RaffleState.OPEN;

        (bool success,) = s_recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }
}


```

In enums:

- You can only be in ONE state at a time
- Each option has a number behind the scenes (starting at index 0)
- You can't make up new options that aren't in the list of the Enum you created.





### Inheritance Notes

To inherit from another contract, import the contract and inherit it with `is` keyword.
Example:
```js
// importing the Chainlink VRF
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

// inheriting the Chainlink VRF
contract Raffle is VRFConsumerBaseV2Plus {}
```
After inheriting contracts, you can use variables from the parent contract in the child contract.



#### Inheriting Constructor Notes

If the contract you are inheriting from has a constructor, then the child contract(contract that is inheriting from the parent) needs to add that constructor.
Example:

Before Inheritance:
```js
contract Raffle {

    uint256 private immutable i_entranceFee; 
    uint256 private immutable i_interval;

    uint256 private s_lastTimeStamp;

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }
}

```


Parent Contract we are inheriting from's constructor:
```js
abstract contract VRFConsumerBaseV2Plus is IVRFMigratableConsumerV2Plus, ConfirmedOwner {
  error OnlyCoordinatorCanFulfill(address have, address want);
  error OnlyOwnerOrCoordinator(address have, address owner, address coordinator);
  error ZeroAddress();

  // s_vrfCoordinator should be used by consumers to make requests to vrfCoordinator
  // so that coordinator reference is updated after migration
  IVRFCoordinatorV2Plus public s_vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) ConfirmedOwner(msg.sender) {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
  }
```

After Child Contract Inherits:
```js
contract Raffle is VRFConsumerBaseV2Plus {
     uint256 private immutable i_entranceFee; 
    uint256 private immutable i_interval;

    uint256 private s_lastTimeStamp;

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator)
    // `VRFConsumerBaseV2Plus` is the name of the contract we are inheriting from
    VRFConsumerBaseV2Plus(vrfCoordinator) // here we are going to define the vrfCoordinator address during this contracts deployment, and this will pass the address to the VRFConsumerBaseV2Plus constructor.
    
    {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }
}

```

### Override Notes

Functions tagged with `virtual` are overrided by functions with the same name but with the `override` keyword.

### Modulo Notes

The ` % ` is called the modulo operation. It's kinda like divison, but it represents the remainder. 
For example: 

`10` / `2` = `5`                                           Key: ` / ` = divison  
but 10 % 2 = 0 as there is no remainder                         ` % ` = modulo

10 % 3 = 1 (because 10 divided by 3 leaves a remainder of 1)

20 % 7 = 6 (because the remainder is 6)
(^ this is read `20 mod 7 equals 6`)
 


### Sending Money in Solidity Notes

There are three ways to transfer the funds: transfer, send, and call

Transfer (NOT RECOMMENDED):
```js
    // transfers balance from this contract's balance to the msg.sender
    payable(msg.sender).transfer(address(this).balance); //  this is how you use transfer
    // ^there is an issue with using transfer, as if it uses more than 2,300 gas it will throw and error and revert. (sending tokens from one wallet to another is already 2,100 gas)
```

Send (NOT RECOMMENDED) :
```js
    // we need to use "bool" when using `send` because if the call fails, it will not revert the transaction and the user would not get their money. ("send" also fails at 2,300 gas)
    bool sendSuccess = payable(msg.sender).send(address(this).balance);
    // require sendSuccess to be true or it reverts with "Send Failed"
    require(sendSuccess, "Send failed");
```

Call (RECOMMENDED) :
    Using `call` is lower level solidity and is very powerful, is the best one to use most of the time.

    `call` can be used to call almost every function in all of ethereum without having an ABI!

     Using `call` returns a boolean and bytes data. The bytes aren't important in the example below, so we commented it out and left the comma. (but really we would delete it if this was a production contract and we would leave the comma. however if we were calling a function we would keep the bytes data) (bytes objects are arrays which is why we use the memory keyword).
    
```js
        (bool callSuccess, /* bytes memory dataReturned */ ) = payable(msg.sender).call{value: address(this).balance}(
            "" /*<- this is where we would put info of another function if we were calling another function(but we arent here so we leave it blank) */
        );
        //        calls the value to send to the payable(msg.sender)^

        // require callSuccess to be true or it reverts with "Call Failed"
        require(callSuccess, "Call Failed");
```

Here is another example for the recommended `Call` to transfer funds:
```js
contract Raffle {
    address payable private s_recentWinner;

    ...

     function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // randomWords is 0 because we are only calling for 1 Random number from chainlink VRF and the index starts at 0, so this represets the 1 number we called for.
        uint256 indexOfWinner = randomWords[0] % s_players.length; // this says the number that is randomly generated modulo the amount of players in the raffle
        //  ^ modulo means the remainder of the division. So if 52(random Number) % 20(amount of people in the raffle), this will equal 12 because 12 is the remainder! So whoever is in the 12th spot will win the raffle. And this is saved into the variable indexOfWinner ^

        // the remainder of the modulo equation will be identified within the s_players array and saved as the recentWinner
        address payable recentWinner = s_players[indexOfWinner];

        // update the storage variable with the recent winner
        s_recentWinner = recentWinner;

        // pay the recent winner with the whole amount of the contract. 
        (bool success,) = s_recentWinner.call{value: address(this).balance}("");
        // if not success then revert
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }
}
```

### Console.log Notes

To use console.log, import the following into your contract:

```js
import {console} from "forge-std/console.log";
```

Then to use console.log, follow the format below:

```js
function exampleLog() external {
    console.log("Hello!");

    uint256 dog = 3;
    // this will say "Dog is equal to 3"
    console.log("Dog is equal to: ", dog); 
}
```


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Package Installing Notes:

to install packages, run `forge install` with a `--no-commit` at the end.
for example:
`forge install https://github.com/smartcontractkit/chainlink-brownie-contracts --no-commit` 
(you can also do it without the github link: 
`forge install smartcontractkit/chainlink-brownie-contracts --no-commit` as it does the same thing)

if you want to install a certain version, then install the version number at the end of the link:
exmaple:
`forge install https://github.com/smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit`
(you can also do it without the github link: 
`forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit` as it does the same thing)


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Remappings in foundry.toml Notes:
Remappings tell foundry to replace the mapping for imports. 
for example:
```javascript
 remappings = ["@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/"]  // in this example, we are telling foundry that everytime it sees @chainlink/contracts/ , it should point to lib/chainlink-brownie-contracts/ as this is where our packages that we just installed stays
 ```

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Smart Contract Tests Notes

All Smart Contracts must have tests. You need tests before going for a smart contract audit or you will be turned away. 


You can see the test coverage by running:
 `forge coverage`: shows you how many lines of code have been tested.
 `forge coverage --report debug`: outputs a coverage report and tells you which lines have not been tested.
 `forge coverage --report debug > coverage.txt`: creates a coverage report/file named `coverage.txt` and it will have all the output of the terminal command `forge coverage --report debug`.


When writing tests, following this order:
1. Write deploy scripts to use in our tests so we can test the exact same way we are going to deploy these smart contracts
    - Note these deployment scripts will not work on zkSync. zkSync needs scripts written in Bash (for now)
2. Then Write tests in this order:
    3. Local Chain (Foundry's Anvil)
    4. Forked testnet
    5. Forked mainnet
  

THe convention for test files is that all test files should end in `.t.sol`.

Example of a test file:
```javascript
// SPDX-License-Identifier: MIT // like always
pragma solidity 0.8.18; // like always

import {Test, console} from "forge-std/Test.sol"; // import the test and console package from foundry. the test package is for testing. the console package is for console.logging. To see the logs, run `-vv` after forge test
import {FundMe} from "../src/FundMe.sol"; // import the contract we are testing


// the test contract should always inherit from the Test package we import
contract FundMeTest is Test {

    // to test functions in the FundMe contract, we need to declare the fundMe variable of type FundMe contract at the contract level and initialize it in the setup function. (This makes the variable a storage or state variable )
    FundMe fundMe;
    // ^ we declare this at the contract level so it can be in scope to all functions in this contract ^


     // every test contract needs to have a setup function. in this setup function, we deploy the contract that we are testing.
    // when we run `forge test`, the setup function always get called before any test function
    function setUp() external {
        // the fundMe variable of type FundMe contract is gonna be a new FundMe contract. The constructor takes no input parameters so we don't pass any parameters.
        fundMe = new FundMe();
        // ^ we deploy a new contract in a testing environment to test the contract ^
    }

 // testing to make sure that the minimum deposit is indeed $5
    function testMinimumDollarisFive() public {
        // assertEq is from the test foundry package
        // this line says that we are assert that the minimum USD variable in the fundMe contract is equal to 5e18.
        assertEq(fundMe.MINIMUM_USD(), 5e18); // the test passes. if you change it to 6e18 then the test fails.
    }

    function testOwnerIsMsgSender() public {
        // console.log(fundMe.i_owner());
        // console.log(msg.sender);
        // this line fails. we can console.log above it to find out why.
        // assertEq(fundMe.i_owner(), msg.sender);
        // ^this line fails because in the setup function, this contract of `FundMeTest` is the one that deployed the FundMe Contract and so the FundMeTest is the owner.

        // so the correct line is:
        assertEq(fundMe.i_owner(), address(this));
        // this line passes because it is asserting that the owner of the FundMe contract is indeed the owner of the deployed contract as the constructor is FundMe says it should be.
    }
    
} 

```

you don't need to declare or deploy the libraries in your test setup. This is because:
1. Libraries are different from contracts - they are not deployed independently in the same way contracts are.
2. The PriceConverter library is already imported and linked to your FundMe contract
3. Library functions can be called directly using the library name.

In the above example we declared the fundMe variable and deployed a new contract of the fundMe contract in the setup function but this is not needed when testing libraries as libraries are of different type. Just import the library into the test file. Library functions marked as internal become part of the calling contract's code. You can call static library functions directly using the library name


To run Tests: `forge test`
To run tests with a detailed output: `forge test -vvvv`
to run a singular test: `forge test --mt <test-function-name> -vvvv`

you can use `-vv`, `-vvv`, `-vvvv`, `-vvvvv` after at the end of your `forge test` command.

`-vv` = console.logs
`-vvv` = stack traces and console.logs
`-vvvv` = more detailed stack trace, console.logs and bytes.

There are 4 different test types:
1. Unit: Testing a specific part of our code
2. Integration: Testing how our code works with other parts of our code
3. Forked: Testing our code on a simulated real environment
4. Staging: Testing our code in a real environment that is not production (testnet or sometimes mainnet for testing)

If we need to test a part of our code that is outside of our system(example: pricefeed from chainlink) then we can write a test to test it, then we can fork a testnet or mainnet to check if it really works. You can do this by running:
 `forge test --mt <test-function-name> -vvv --fork-url $ENV_RPC_URL` - you can learn more about this and keeping it modular by looking at [the  section 7 Foundry FundMe course](https://updraft.cyfrin.io/courses/foundry/foundry-fund-me/refactoring-helper) and your codebase of foundry-fund-me-f23.

 for example: `forge test --mt testPriceFeedVersionIsAccurate -vvv --fork-url $SEPOLIA_RPC_URL`. Of course to use this you would have the RPC URL(that you can get from a node provider such as Alchemy) in your .env file. After adding a .env making sure to run `source .env` to add the environment variables. Also make sure you fork the correct chain where the logic is.

 run `forge coverage` to see how many lines of code have been tested.

 you only want to deploy mocks when you are working on a local chain like anvil.

### Local Chain Tests Don't Work on Forked Chain Tests?

If you have a test that passes on the local chain, but fails on a forked chain, this could be happening for several reasons.
First off, you want to make sure that you are deploying the tests from some sort of burner metamask wallet when deploying on a forked chain. When you write a test on a local chain, it just spins us a fake and local chain and account to run the the tests on. To make sure you are correctly deploying from a burner metamask on a local chain, review the `vm.startBroadcast` section in the `Getting Started With Scripts` section of this notes file.

Second off, some tests may fail on a forked chain instead of a local chain if the test is using mocks. So when running tests on a forked chain, we must skip over these tests that are meant for a local chain(tests with mocks). We can do this by creating a modifier that skips over the tests with this modifier.
example:
```js
   modifier skipFork() {
    // if the blockchain that we are deploying these tests on is not the local anvil chain, then return. When a function hits `return` it will not continue the rest of the logic 
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

     function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId)
        public
        raffleEntered
        skipFork
    {
        // Arrange / Act / Assert
        // we expect the following call to revert with the error of `VRFCoordinatorV2_5Mock`;
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }
```
As you can see this test has the `skipFork` modifier that we made.





### Testing Events

To test an event, you need to copy and paste the events from the codebase to the test file in order to test them.

Once you have the events in your test file, the logic for testing them is `vm.expectEmit(true/false, true/false, true/false, true/false, contractEmittingEvent)`

These 3 first true/false statements will only be true when there is an indexed parameter, and the 4th one is for any data that is not indexed within the event. For example:
```js
contract RaffleTest is Test {
    ...
    // we copy and paste the event from the smart contract into our test
    // as you can see there is only one indexed event and no other data.
    event RaffleEntered(address indexed player, /* No Data */, /* No Data */, /* No Data */); // events can have up to 3 indexed parameters and other data that is not indexed.
    ...
    function setUp() external {
        ...
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
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


}
```


### Tests with Custom error notes

When writing a test with a custom error, you need to expect the revert with `vm.expectRevert()` and you need to end it with `.selector` after the custom error.

Example:
```js
 function testRaffleEvertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER); // the next transaction will be the PLAYER address that we made
        // Act / Assert
        // expect the next transaction to revert with the custom error Raffle__SendMoreToEnterRaffle.
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        // call the Enter Raffle with 0 value (the PLAYER is calling this and we expect it to evert since we are sending 0 value)
        raffle.enterRaffle();
    }
```

If the customr error has parameters, then the custom error needs to be abi.encoded and the parameters need to be apart of the error.
Example:

`Raffle.sol`:
```js
contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playerslength, uint256 raffleState);
}
```
`test/Raffle.t.sol`:
```js
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
```






 ### Sending money in tests Notes:
 When writing a test in solidity and you want to pass money to the test, you write it like this:
 ```javascript
  function testFundUpdatesFundedDataStructure() public {
        fundMe.fund{value: 10e18}();
    }
 ```
 because the fund function that we are calling does not take any parameter, it should be written like `fundMe.fund{value: 10e18}();` and not like ``fundMe.fund({value: 10e18});``. This is because the fund function does not take any parameters but is payable. So {value: 10e18} is the value being passed while () is the parameters being passed. IF the fund function was written like `function fund(uint256 value) public payable {}` then the test line of `fundMe.fund({value: 10e18}); ` would indeed work.

 ### GAS INFO IN TESTS Notes
 When working on tests in anvil, the gas price defaults to 0. So for us to simulate transactions in test with actual gas prices, we need to tell our tests to actually use real gas prices. This is where `vm.txGasPrice` comes in. (See `vm.txGasPrice` below in cheatcodes for tests)

 ### FUZZ TESTING NOTES

 For most of your testing, ideally you do most of your tests as fuzz tests. You should always try to default all of your tests to some type of fuzz testing.

 Stateless fuzz testing:

 Stateful fuzz testing:

Fuzz testing gets defaulted to 256 runs. To change the amount of tests foundry does in a fuzz test, in your `foundry.toml` change the runs number:
```js
[fuzz]
runs = 256 // change this number
```
You can learn more about fuzzing (and foundry.toml commands in general) at` https://github.com/foundry-rs/foundry/tree/master/config ` and scroll down to the fuzz section.


 ### CHEATCODES FOR TESTS Notes
 `makeAddr()` : This cheatcode creates a fake address for a fake person for testing Purposes.
 For example:
 ```javascript
// creating a user so that he can send the transactions in our tests. "MakeAddr" is a cheatcode from foundry that allows use to make a fake address for someone for testing purposes (we named the address being made "user" and the person is called USER).
    address USER = makeAddr("user");
 ```

`vm.deal()` : After we make a new fake person (see `makeAddr` above) the fake persons address/wallet needs funds in it in order for them to make transactions in our tests. So we `deal` them some fake money.
For Example:
```javascript
// this is the amount that we are going to pass to the "USER" saved as a variable to avoid magic numbers.
uint256 constant STARTING_BALANCE = 10 ether;

function setup() public {
 // we need to give the fake person "USER" some money so he has money in his wallet to make transactions with. This needs to go in the setup function because the setup function is always called before the tests when we run `forge test`
        vm.deal(USER, STARTING_BALANCE);}
```

 `vm.prank()` : This cheatcode allows for the next call to be made by the user passed into it.
 For example:
 ```javascript
 function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // the next transaction will be sent by "USER".
        fundMe.fund{value: SEND_VALUE}(); // so this value is sent by the "USER"
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }
 ```
 
   `vm.expectRevert()` : This cheatcode tells foundry that the next line in the test function is expected to revert. If the test/transaction reverts, then the test passes since we expect it to revert.
 For Example:
 ```javascript
    // this test is making sure that if a user sends less than the minimum amount, the contract will revert and not allow it.
    function testFundFailsWithoutEnoughEth() public {
        // this is a cheat code in foundry. it is telling foundry that the next line should revert.
        vm.expectRevert();

        fundMe.fund(); // send zero value. this fails because there is a minimum that needs to be sent.
            // so because we used expectRevert, this test passes.
    }
 ```

 `hoax` : This is vm.prank and vm.deal combined. (This is not a cheatcode but instead is apart of the Forge Standard library(slightly different from the cheatcodes)).
 For Example:
 ```javascript
 function testWithdrawFromMultipleSenders() public funded {
        // Arrange
        uint160 numberofFunders = 10; // This is a uint160 because we use `hoax` here. and if you use `hoax` then to use number to generate address you must use uint160s. this is because uint160s have the same amount of bytes as addresses.
        uint160 startingFundingIndex = 1;

        for (uint160 i = startingFundingIndex; i <= numberofFunders; i++) {
            hoax(address(i), SEND_VALUE); // hoax is vm.deal and vm.prank combined.
            fundMe.fund{value: SEND_VALUE}();
        }
 }
 ```
As you can see from the example, `hoax` dealt money to the accounts in the loop and made it so that the next transactions would be from the accounts in the loop.


`vm.startPrank` - `vm.stopPrank` : These cheat codes are like `vm.prank` except instead of just doing 1 transaction, all transactions between `vm.startPrank` and `vm.stopPrank` are simulated from an account.
For example:
```javascript
vm.startprank(fundMe.getOwner()); // next transaction is from the owner
fundMe.withdraw(); // owner withdraws
vm.stopPrank;
```

`vm.txGasPrice` : Sets the gas factor since when working on anvil the gas factor is always 0. meaning that transactions will always cost not gas unless you tell anvil to use a gas factor.
```javascript
    // This is the gas price that we tell anvil to use with the cheat code `vm.txGasPrice`. We can set this number to anything.
    uint256 constant GAS_PRICE = 1;
    // ^ tells solidity to use gas of a factor by 1 because on anvil it is always set to 0 ^
function ...
   //In order to see how much gas a function is going to spend, we need to calculate the gas spend before and after.
        // here we are checking how much gas is left before we call the withdraw function(which is the main thing we are testing).
        uint256 gasStart = gasleft(); // gasleft() is a built in function in solidity.

        vm.txGasPrice(GAS_PRICE); // tells solidity to use gas of a factor by 1 because on anvil it is always set to 0.
        vm.prank(fundMe.getOwner()); // next transaction is from the owner
        fundMe.withdraw(); // owner withdraws

        // getting the balance of the gas after we finish calling the withdraw function.
        uint256 gasEnd = gasleft();
        // here we do the math to figure out how much gas we used taking the gasStart and subtracting it from the gasEnd and multiplying that number against the current gas price.
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; //tx.gasprice is built into solidity that tells you the current gas price
        // now when we run this test it will tell us how much gas was used.
...
```

`vm.warp` & `vm.roll`:
`vm.warp`: allows us to warp time ahead so that foundry knows time has passed.
`vm.roll`: rolls the blockchain forward to the block that you assign.
These don't have do be used together, but they should be used together to avoid issues and be technically correct.
Example:
```js
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
```

 ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 ## Chisel Notes

 To run chisel, run `chisel` in your terminal.
 you can run `!help` in chisel to see everything you can do in the chisel terminal.

 Chisel allows us to write solidity in our terminal and execute it line by line so we can quickly see if something works.

For example, if we wrote (in chisel):
`uint256 dog =1` (press ENTER)
then we typed `dog` (PRESS ENTER)
it would return: 
```javascript
Type: uint256
├ Hex: 0x1
├ Hex (full word): 0x1
└ Decimal: 1
```
Another Example following the previous:
```javascript
➜ uint256 dogAndThree = dog + 3;
➜ dogAndThree
Type: uint256
├ Hex: 0x4
├ Hex (full word): 0x4
└ Decimal: 4
➜ 
```

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

*** NEVER USE A .ENV FOR PRODUCTION BUILDS, ONLY USE A .ENV FOR TESTING ***

to deploy a Singular Contract while testing on anvil or a testnet:

to deploy a smart contract to a chain, use the following command of:

forge create <filename> --rpc-url http://<endpoint-url> --private-key <privatekey>.

you can get the endpoint url(PRC_URL)  from alchemy. when getting the url from alchemy, copy the https endpoint. then set up your .env like `.env`


example:
forge create SimpleStorage --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80.

in the exmaple above, we are deploying to anvil's blockchain with a fake private key from anvil. if you want to run anvil, just run the command "anvil" in your terminal.

*** HOWEVER WHEN DEPLOYING TO A REAL BLOCKCHAIN, YOU NEVER WANT TO HAVE YOUR PRIVATE KEY IN PLAIN TEXT ***

*** ALWAYS USE A FAKE PRIVATE KEY FROM ANVIL OR A BURNER ACCOUNT FOR TESTING ***

*** NEVER USE A .ENV FOR PRODUCTION BUILDS, ONLY USE A .ENV FOR TESTING ***

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Script Notes

### Getting Started with Scripts Notes

When writing Scripts, you must import the script directory from foundry. and if you are using console.log, then you must import console.log as well.
For Example:
```javascript
import {Script, console} from "forge-std/Script.sol";
contract DeployFundMe is Script {} // Also the deployment script MUST inherit the Script Directory.
```

All Script functions must have a `run()` function. 
For example:
```javascript
// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// we must import Script.sol to tell foundry that this is a script.
import {Script} from "forge-std/Script.sol"; // we need to import the script package from foundry when working on scripts in foundry/solidity.
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

// this script will deploy our smart contracts. we should always deploy smart contracts this way.
// Script contracts always need to inherit from scripts
contract DeployFundMe is Script {
    // all deployments scripts need to have this "run" function because this will be the main function called when deploying the contract.
    function run() external returns (FundMe) {
        // this says that when we start this `run` function, it will create a new helperconfig of type HelperConfig contract.
        HelperConfig helperConfig = new HelperConfig();
        // because we send this before `vm.startBroadcast`, it is executing this code in a simulated environment. So it is grabbing the chainId that we are deploying to right before we deploy the contracts

        // we get the activeNetwork's pricefeed address and save it as a variable called "ethUsdPriceFeed"
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();
        // `activeNetworkConfig` is a variable of type struct, so if we had more variables in the struct, depending on what we would want we should save it as (address ethUsdPriceFeed, address exampleAddress, , ,)

        // "vm.startBroadcast" is a cheatcode from foundry. it tells foundry "everything after this line should be sent to the rpc"
        vm.startBroadcast();
        // this line says variable name "fundMe" of type contract FundMe is equal to a new FundMe contract that is now being created and the broadcast line deploys it.
        // FundMe fundMe = new FundMe(); // this line throws a warning since we do not use the variable fundMe
        // new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); // this also creates a new FundMe contract

        // we use this because now it will be more modular. All we do is now change this address and it will update our entire codebase.
        FundMe fundMe = new FundMe(ethUsdPriceFeed); // this address gets inputted into the FundMe constructor.
        vm.stopBroadcast();
        return fundMe; // because this returns the deployed fundMe contract, we can make changes and it will always return the change we made. making the testing easier and more modular.
    }
}
```

another example: DeployRaffle.s.sol from foundry-smart-contract-lottery
```js
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() public {}

    function deployContracts() public returns (Raffle, HelperConfig) {
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
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callBackGasLimit
        );
        vm.stopBroadcast();
        // returns the new raffle and helperconfig that we just defined and deployed so that these new values can be used when this function `deployContracts` is called
        return (raffle, helperConfig);
    }
}

```

`vm.startBroadcast` & `vm.stopBroadcast`: All logic inbetween these two cheatcodes will be broadcasted/executed directly onto the blockchain.
example: (from `foundry-smart-contract-lottery/script/DeployRaffle.s.sol`)
```js
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
        if (config.subscriptionId == 0) {
            // deploys a new CreateSubscription contract from Interactions.s.sol and save it as a variable named createSubscription
            CreateSubscription createSubscription = new CreateSubscription();
            // calls the createSubscription contract's createSubscription function and passes the vrfCoordinator from the networkConfigs dependent on the chain we are on. This will create a subscription for our vrfCoordinator. Then we save the return values of the subscriptionId and vrfCoordinator and vrfCoordinator as the subscriptionId and values in our networkConfig.
            (config.subscriptionId, config.vrfCoordinator) =
                createSubscription.createSubscription(config.vrfCoordinator);

            // creates and deploys a new FundSubscription contract from the Interactions.s.sol file.
            FundSubscription fundSubscription = new FundSubscription();
            // calls the `fundSubscription` function from the FundSubscription contract we just created and pass the parameters that it takes.
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link);
        }

        // everything between startBroadcast and stopBroadcast is broadcasted to a real chain
        vm.startBroadcast();
        // create a new raffle contract with the parameters that are in the Raffle's constructor. This HAVE to be in the same order as the constructor!
        Raffle raffle = new Raffle(
            // we do `config.` before each one because our helperConfig contract grabs the correct config dependent on the chain we are deploying to
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callBackGasLimit
        );
        vm.stopBroadcast();

        // creates and deploys a new AddConsumer contract from the Interactions.s.sol file.
        AddConsumer addConsumer = new AddConsumer();
        // calls the `addConsumer` function from the `AddConsumer` contract we just created/deplyed and pass the parameters that it takes.
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId);

        // returns the new raffle and helperconfig that we just defined and deployed so that these new values can be used when this function `deployContracts` is called
        return (raffle, helperConfig);
    }
}
```

However, the `vm.startBroadcast` can also be passed in the account that will be sending these transactions
example: from `foundry-smart-contract-lottery-f23`
```js
    // these are the items that the constructor in DeployRaffle.s.sol takes
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callBackGasLimit;
        uint256 subscriptionId;
        address link;
        address account;
    }

    ...

     // everything between startBroadcast and stopBroadcast is broadcasted to a real chain and the account from the helperConfig is the one making the transactions
        vm.startBroadcast(config.account);
        // create a new raffle contract with the parameters that are in the Raffle's constructor. This HAVE to be in the same order as the constructor!
        Raffle raffle = new Raffle(
            // we do `config.` before each one because our helperConfig contract grabs the correct config dependent on the chain we are deploying to
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callBackGasLimit
        );
        vm.stopBroadcast();
```

### HelperConfig Script Notes

We live in a multi-chain world, there are many different chains and often we will want to deploy the same protocol to different chains. To do this smoothly, we can create a `HelperConfig.s.sol` file that can see what chain we are on, and grab the correct network configurations for our deployment script when we are deploying.

For example: HelperConfig.s.sol from foundry-smart-contract-lottery-f23
```js
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
        address vrfCoordinator;
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
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
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

    // calls getConfigByChainId to grab the chainId of the chain we are deployed on and do the logic in getConfigByChainId
    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    // these are the items that are relevant for our raffle constructor if we are on the Sepolia Chain when we deploy.
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.1 ether, // 1e16 // 16 zeros
            interval: 30, // 30 seconds
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B, // got this from the chainlink docs here: https://docs.chain.link/vrf/v2-5/supported-networks
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // // got this keyhash from the chainlink docs here: https://docs.chain.link/vrf/v2-5/supported-networks
            callBackGasLimit: 500000, // 500,000 gas
            subscriptionId: 0
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // if the if the vrf.coordinator address does exist on the anvil chain that we are on,
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            // then return the all the values in the NetworkConfig struct that is has since it already exists
            return localNetworkConfig;
        }

        // if the if the vrf.coordinator address does NOT exist on the anvil chain that we are on, then deploy a mock vrf.coordinator
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
        vm.stopBroadcast();

        // these are the items that are relevant for our raffle constructor if we are on the Anvil Chain when we deploy.
        localNetworkConfig = NetworkConfig({
            entranceFee: 0.1 ether, // 1e16 // 16 zeros
            interval: 30, // 30 seconds
            vrfCoordinator: address(vrfCoordinatorMock), // the address of the vrfCoordinatorMock
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // does not matter since this is on anvil
            callBackGasLimit: 500000, // 500,000 gas, but it does not matter since this is on anvil
            subscriptionId: 0
        });
        // then return the all the values in the NetworkConfig struct when this function is called
        return localNetworkConfig;
    }
}
```






### Deploying A Script Notes
If you have a script, you can run a simulation of deploying to a blockchain with the command in your terminal of `forge script script/<file-name> --rpc-url http://<endpoint-url>` 

example:
`forge script script/DeploySimpleStorage.s.sol --rpc-url http://127.0.0.1:8545`

this will create a broadcast folder, and all deployments will be in your deployment folder in case you want to view any information about your deployment.

to deploy to a testnet or anvil run the command of `forge script script/<file-name> --rpc-url http://<endpoint-url> --broadcast --private-key <private-key>`  

example: 
` forge script script/DeploySimpleStorage.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 `

if you have multiple contracts in a file and only want to send one, you can send the one by running `forge script script/<file-name>:<contract-Name> --rpc-url http://<endpoint-url> --broadcast --private-key <private-key>`

example: 
` forge script script/Interactions.s.sol:FundFundMe --rpc-url http://127.0.0.1:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 `

*** HOWEVER WHEN DEPLOYING TO A REAL BLOCKCHAIN, YOU NEVER WANT TO HAVE YOUR PRIVATE KEY IN PLAIN TEXT ***

*** ALWAYS USE A FAKE PRIVATE KEY FROM ANVIL OR A BURNER ACCOUNT FOR TESTING ***

*** NEVER USE A .ENV FOR PRODUCTION BUILDS, ONLY USE A .ENV FOR TESTING ***


### Interaction Script Notes
(its most likely easier to just use Cast Send to interact with deployed contracts.)

You can write a script to interact with your deployed contract. This way, if you want to repeatedly call a function of interact with your contract for any reason, a script is a great way to do so as it makes these interactions reproducible. These interaction scripts should be saved in the script/Interactions folder!

A great package to use is `Cyfrin Foundry DevOps` as it grabs your latest version of a deployed contract to interact with. Install it with `forge install Cyfrin/Foundry-devops --no-commit`.
This package has a function that allows you to grab your lastest version of a deployed contract.
For Example:
```javascript
// this is going to be our script for funding the fundMe contract
contract FundFundMe is Script {
    // amount we are funding with
    uint256 constant SEND_VALUE = 0.01 ether;

    function fundFundMe(address mostRecentlyDeplyed) public {
        // `startBroadcast` sends all transactions between startBroadcast and stopBroadcast
        vm.startBroadcast();

        // takes an input parameter of an address, which is going to be the mostRecentlyDeplyed address of our contract and funds it with the amount we want.
        FundMe(payable(mostRecentlyDeplyed)).fund{value: SEND_VALUE}();

        vm.stopBroadcast();

        console.log("Funded FundMe with %s", SEND_VALUE); // import the console.log from the script directory
            // this console.log also lets us know when the transaction goes through because it pops up when the transaction goes through.
    }

    function run() external {
        // grabs the most recent deployment from the broadcast folder. takes the name of the contract and the blockchain so it knows what to do
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        // calls the fundFundMe function to deploy funds to the most recently deployed contract
        fundFundMe(mostRecentlyDeployed);
    }
}
```
Always write tests for scripts as getting them wrong and deploying them is a waste of money. Save the money and write the tests! But its most likely easier to just use Cast Send to interact with deployed contracts.


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## BroadCast Folder Notes:

the `dry-run` folder is where the transactions with no blockchain specified go.

`run-latest.json` is the latest transaction sent. the transaction data will look like: 
# I am adding comments to explain what is going on here:
```javascript
  "transactions": [
    {
        
      "hash": "0x8677435aa38539f85122ff0f9f6a30f0bb1587d6f08837b13b0dea2a8b8d217d", // the serial number of the transaction is called the hash
      "transactionType": "CREATE", // we are creating/deploying the contract onto the blockchain
      "contractName": "SimpleStorage", // name of contract 
      "contractAddress": "0x5fbdb2315678afecb367f032d93f642f64180aa3", // address the contract is deployed on
      "function": null,
      "arguments": null,
      "transaction": { // this transaction section is what is actually being sent on chain.
        "from": "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266", // the address i sent this transaction from
        "gas": "0x71556", // we can decode this by running the command `cast --to-base 0x71556 dec`. "dec" stands for decimal. it represents the type of format we want to decode the data to.
        "value": "0x0", // you can add value when deploying a contract by making the constructor payable in the contract being deployed and adding `SimpleStorage simpleStorage = new SimpleStorage{value: 1 ether}();` in the deploy script. 
        "input": "0x608060405234801561001057600080fd5b5061057f8061...", // this is the contract deployment code and the contract being deployed code. This holds all the opcodes/EVM bytecode
        "nonce": "0x0", // In Solidity and Ethereum, a nonce is a number that keeps track of the number of transactions sent from an address. This increments everytime we send a transaction.
        "chainId": "0x7a69"
      },
      "additionalContracts": [],
      "isFixedGasLimit": false
    }
  ],
```
  When you send a transaction, you are signing it and sending it.

  # cast is a very helpful tool. run `cast --help` to see all the helpful things it can do. 

  Watch the video about this @ https://updraft.cyfrin.io/courses/foundry/foundry-simple-storage/what-is-a-transaction . if that does not work, then it is the foundry fundamentals course, section 1, lesson 18: "What is a transaction"

Nonce Main purpose:


Prevent transaction replay attacks (same transaction being executed multiple times)
Ensure transactions are processed in the correct order
Track the number of transactions sent by an account
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



*** NEVER USE A .ENV FOR PRODUCTION BUILDS, ONLY USE A .ENV FOR TESTING ***

when using a .env, after adding the variables into the .env, run `source .env` in your terminal to added the environment variables.

then run `echo $<variable>` to check it it was added properly. example: `echo $PRIVATE_KEY` or `echo $RPC_URL`. 

this way, when testing, instead of typing our rpc-url and private key into the terminal each time, we can instead run ` forge script script/<file-Name> --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY ` 


example:
` forge script script/DeploySimpleStorage.s.sol --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY ` 

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## DEPLOYING PRODUCTION CONTRACT Notes


*** DEPLOYING PRODUCTION CONTRACTS ***
 to deploy production contracts, you must encrypt your private key. this will result in you also creating a password for your private key, so don't lose it. to encrypt a private key run the following commands in your terminal, NOT in VS-Code or Cursor:
 
 ```javascript
`cast wallet import <your-account-name> --interactive` // pass an account name to name this wallet and do not forget the account name!
Enter private key: // it will prompt you to enter your private key to encrypt it
Enter password: // it will prompt you to enter a password. Don't forget the password!
`your-account-name` keystore was saved successfully. Address: address-corresponding-to-private-key
 ```

 Then deploy with:
`forge script <script> --rpc-url <rpc_url> --account <account_name> --sender <address> --broadcast`

After you deploy with this command, it will prompt you for your password. Do not lose your account name, public address, password, and obviously, do not lose your private key!. 

you can of course add a RPC_URL to your .env and run `forge script <script> --rpc-url $RPC_URL --account <account_name> --sender <address> --broadcast` as well. NEVER PUT YOUR PRIVATE KEY IN YOUR .env !!

you can run `cast wallet list` and it will show you all a list of the names you choose for the wallets you have encrpted.

after encrypting your private key clear your terminal's history with `history -c`

After deploying a contract copy the hash and input it into its blockchain's etherscan, then click on the "to" as this will be the contract. (The hash created is the hash of the transaction and the "to" is the contract itself.)

### Verifying a Deploying Contract Notes:

Manually (Not Recommended):
1. When on the contract on etherscan, click the "Verify and Publish" button in the "Contract" tab of the contract on etherscan. This will take you to a different page on etherscan.
2. Select the correct options that define what you just deployed. (it will ask for info such as: address, Compiler type and version, and License type.)
3. Then copy the code of the contract and paste it in the "Enter Solidity Contract Code below" section and define the contrustor args if you have them(if you dont then leave it blank).
4. Select "yes" for the "Optimization" button.
5. If done correctly, you will now be able to see your contracts that have been deployed in the contracts "read" tab.

Programatically (Recommended):
To programtically verify a contract, you must do it while deploying. When deploying, the command must end with `--verify --etherscan-api-key $ETHERSCAN_API_KEY -vvvv`. Make sure to have the `$ETHERSCAN_API_KEY` in your .env file!

Example:
`forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $SEPOLIA_RPC_URL --account <accountName> --sender <address> --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vvvv`

#### If a Deployed Contract does not Verify Correctly


If a deployed contract does not verify correctly during deployment, we can then do the following to verify a contract:

1. Run `forge verify-contract <contract-address> <contract> --etherscan-api-key $ETHERSCAN_API_KEY --rpc-url $SEPOLIA_RPC_URL --show-standard-json-input > json.json`

Arguments:
  <ADDRESS>
          The address of the contract to verify

  [CONTRACT]
          The contract identifier in the form `<path>:<contractname>`

example: `forge verify-contract 0x123456789 src/Raffle.sol:Raffle --etherscan-api-key $ETHERSCAN_API_KEY --rpc-url $SEPOLIA_RPC_URL --show-standard-json-input > json.json` 

Make sure you have a ETHERSCAN_API_KEY and SEPOLIA_RPC_URL in your .env file.

This command will create a new json.json in your root directory.

2. Go to the file and press `ctrl` + `shift` + `p` and search for and select `format`. This json.json file is what is known as the standard json and is what verifiers will use to actually verify a contract.

3. Go back to etherscan, in your contract tab where your contract should be verified. Click `Verify and publish`. This will take you to a page to select/fill details about your contract, such as the address of the contract, the compiler type and version and Open Source License Type (probably MIT). For the Compiler type, choose `Solidity (Standard-Json-Input)` and the compiler version you are using in your contract(s). 

4. Click COntinue and on the next page it will ask you to select the `Standard-Json-Input` file to upload, here is where you will upload the json.json file we just made earlier. 

5. Click `I'm not a robot` and verify and publish!



#### ALL --VERIFY OPTIONS NOTES

To see all the options of verifying a contract with forge, run `forge verify-contract --help`


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## How to interact with deployed contracts from the command line Notes:

After you deploy a contract, you can interact with it:

if you type `cast --help` you will see a bunch of commands. One of the commands we are going to work with is going to be `send`. To see the arguments that `send` takes, run `cast send --help`; the arguments are:
`TO`: The destination of the transaction. If not provided, you must use cast send --create.
`SIG`: The signature of the function to call.
`ARGS`: The arguments of the function to call.

For example, if we want to call our store function in SimpleStorage.sol, we would run the following:
`cast send 0x5fbdb2315678afecb367f032d93f642f64180aa3 "store(uint256)" 123 --rpc-url $RPC_URL --account <accountName>`.

Explantion:
`cast send`: command to interact with the contract.
`0x5fbdb2315678afecb367f032d93f642f64180aa3`: address of the contract. if you forget what the address is, it can be found in the broadcast folder (check notes above).
` "store(uint256)" `: we want to interact with the store function, and it takes a uint256 as its parameter.
`123`: the values(arguments) that we want to pass.

Another example: `cast send 0x6c4791c3a9E9Bc5449045872Bd1b602d6385E3E1 "solveChallenge(string,string)" "chocolate" "Squilliam" --rpc-url $SEPOLIA_RPC_URL --account SepoliaBurner` - As you can see, here we put the name of the parameters as well as its type, this is how you would do it. as you can see we are passing the arugments of "chocolate" and "Squilliam". 

Running this command will return a bunch of data, to read the data, run `cast call --help`. This will show you the arguments that `call` takes. The arguments are `TO`, `SIG`, and `ARGS` again! The difference is, `call` is calling a transaction to read data, whereas `send` is sending a transaction to modify the blockchain!

To use `call` run: `cast call <contract address> <function name> <input parameters>`

example:
`cast call 0x5fbdb2315678afecb367f032d93f642f64180aa3 "retrieve()" ` (the retrieve function has no input parameters so we leave it blank.)

this command will return hex data, and needs to be decoded. so to decode it, run `cast --to-base <hex-data> dec`

example: the hex data returned is: `0x000000000000000000000000000000000000000000000000000000000000007b` so the command is `cast --to-base 0x000000000000000000000000000000000000000000000000000000000000007b dec` ("dec" stands for decimal. it represents the type of format we want to decode the data to.)

This returns the data that we submitted of `123`. (NOTE: This returns the data we submitted because it is the only data submitted and the contract function "retrieve" is written to return the most recent number.)

### CAST SIG NOTES

When interacting with a contract on the internet from metamask, metamask will prompt you with a confirm transaction. In this confirm window on metamask, it will tell you what function you are calling at the top of the window and there will be a `HEX DATA: 4 BYTES` section at the bottom of the window that has the function selector hex data of the function you are calling.

In your terminal, if you run `cast sig "<function-Name>()" ` and it will return the hex data so we can make sure it is the same hex data as the function we are calling in our transaction to make sure it is calling the correct function and we are not getting scammed.
Example:
```js
/* (Command): */ cast sig "createSubscription()"
/* (Terminal returns): */ 0xa21a23e4
```

Sometimes you will not know what the function's hex is. But there are function signature databases that we can use (like `openChain.xyz` and we go to signature database). If you paste in the function selector/ hex data and press search, it has a database of different hashes/hex data and the name of the function associated with it. So this way we can see what hex data is associated with what functions. These databases only work if someone actually updates them. Foundry has a way to automatically update these databases (Check foundry docs).

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## TIPS AND TRICKS

run `forge fmt` to auto format your code.

run `forge coverage` to see how many lines of code have been tested.

run `forge snapshot --mt <test-function-name>` to create a `.gas-snapshot` file to tell us exactly how much gas a test function uses. you could also run `forge snapshot` and it will create a `.gas-snapshot` file to tell us exactly how much gas each function in the contracts cost.

run `forge inspect <Contract-Name> storagelayout` and it will tell you the exact layout of storage that your contract has.

run `cast storage <contract-address> <index-of-storage>` and it will tell you exactly what is in that storage slot. For example: `cast storage 0x12345..88 2`. (mapping and arrays take up a storage slot but they are blank because they are dynamic and can change lengths). if you dont add an index number than it will tell you the whole storage layout of the contract from etherscan (make sure you are connected to etherscan if you want this!).


Reading and writing from storage is 33x more expensive than reading and writing from memory. Try to keep reading and writing to memory at a minimum by reading and writing to memory instead.
For example:
```javascript
  function cheaperWithdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) { // this is repeatedly reading from storage and will cost a ton, Especially as the array gets longer.
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) =
            payable(msg.sender).call{value: address(this).balance}(""); 
        require(callSuccess, "Call Failed");
    }
```

```javascript
  function cheaperWithdraw() public onlyOwner {
        uint256 funderLength = s_funders.length; // this way we are only reading from the storage array `funders` one time and saving it as a memory variable
        for (uint256 funderIndex = 0; funderIndex < funderLength; funderIndex++) { // then here we loop through the memory instead of the storage
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) =
            payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }
```



------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## ChainLink Notes:

### Chainlink Functions
Chainlink functions allow you to make any API call in a decentralized context through decentralized nodes. Chainlink functions will be the future of DeFi and smart contracts. If you want to make something novel and something that has never been done before, you should check out chainlink functions. You can learn more about chainlink functions at `docs.chain.link/chainlink-functions`.

### Aggregator PriceFeeds Notes
Smart Contracts by themselves cannot access data outside of their own contracts. They cannot tell what the price of tokens are, what day it is, or who the president is. This is where chainlink datafeeds come in. Chainlink datafeeds take in data from many decentralized sources and their decentralized chainlink nodes decide what data is true based off their many decentralized sources. You can learn more about chainlink datafeeds in the chaink docs at `docs.chain.link` or at `https://updraft.cyfrin.io/courses/solidity/fund-me/real-world-price-data`.

Pricefeeds are a type of datafeed from chainlink. You can see examples at data.chain.link. To use pricefeeds, you will need the address of the pricefeed and the interface of the AggregatorV3Interface.

To get the address of the PriceFeed, go to `https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1`, click on the chain you are looking to get data from, then scroll down to the contract pair that you want to get the price of and copy that address.

To use the interface of the AggregatorV3Interface, run `forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit` in your terminal. Then in your `foundry.toml` create/add a remapping of ` remappings = ["@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/"] `

If you need the interface of the AggregatorV3Interface from github for any reason, you can go to `https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol` - (this link may change, if so, the AggregatorV3Interface will still be in the smartcontractkit/chainlink github, but under a different file. If you cannot find it, then you can find the correct link in `https://github.com/Cyfrin/foundry-full-course-cu?tab=readme-ov-file#solidity-101-section-1-simple-storage` in Solidity 101 Section 3: Remix Fund Me, under `Interfaces`. The link should say something like `For reference - ChainLink Interface's Repo` and the link will be here.)


Once you import the AggregatorV3Interface, you can pass the pricefeed address into the AggregatorV3Interface and it will return any data that you want from the AggregatorV3Interface interface. 

AggregatorV3Interface at the time of this writing:
```js
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable-next-line interface-starts-with-i
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

```

So for example, if you want to get the version of the pricefeed, you would call the function within the AggregatorV3Interface in one of your own functions in your contract. Example:
```js
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
// to attach the Price Converter functions to all uint256s:
    using PriceConverter for uint256;

// this variable is of type AggregatorV3Interface, and is used in the constructor. So that when deployed, the contract will read what chain we are on and use the correct pricefeed.
    AggregatorV3Interface private s_priceFeed;

     // the constructor is a function that gets immediately called when the contract is deployed.
    // the priceFeed parameter means that it takes a pricefeed address, and this will depend on the chain we are deploying to. This way the codebase is much more modular.
    constructor(address priceFeed) {
        // this pricefeed address is set in the deployment script input!
        // makes the deployer of this contract the "owner" of this contract.
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

  function getVersion() public view returns (uint256) {
        // this works because the address defined is correlated the functions "AggregatorV3Interface" and "version". We also imported the "AggregatorV3Interface" from chainlink.
        // return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
        // ^ we refactored this code because it was hardcoded to sepolia, to make it more modular, we change it to (below): ^
        return s_priceFeed.version();
        // ^this is more modular because now it will get the address of the pricefeed dependant on the chain we deployed to. ^
    }
}
```

If for any reason you get stuck, watch the video Cyfrin Updraft, Course: Foundry Fundamentals, Section 2: Foundry Fund Me.


example (The following 4 snippets are from foundry-fund-me-f23):
create a library that uses the AggregatorV3Interface from chainlink: 
```js
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // libraries cannot have any state variables. State Variables are variables declared on the contract level.
    //  this function will get the price of the naive blockchain token(in this case its eth) in terms of USD
    function getPrice(AggregatorV3Interface dataFeed) internal view returns (uint256) {
        // to reach out to this contract, we need the Address and the ABI
        // address: 0x694AA1769357215DE4FAC081bf1f309aDC325306 ✅ (This is the address of the ETH/USD datafeed from chainlink)
        // ABI: Chainlink's AggregatorV3Interface ✅(the interface acts like an ABI). when we combine a contracr address with the interface, we can easily call the functions in that contract
        // the formating of this code comes from the docs of chainlink which can be found at https://docs.chain.link/data-feeds/using-data-feeds
        // the formating of this code comes from the docs of chainlink which can be found at https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol
        (, int256 answer,,,) = dataFeed.latestRoundData();
        // ^ because we dont need the other items, we can just remove them and keep the commas.
        // this will return the price of ETH in terms of USD
        // so if the value is $3k, it will show as 300000000000 (8decimals).
        return uint256(answer * 1e10);
        // ^ we multiply this by 1e10 to get 18 decimals instead of 8!
        // ^^ we typecast this with uint256 because the answer returned is in int and we need it in uint. This is because int can be negative and this can lead to bugs. Uint can never be negative. Also, we typecasted because our msg.value is type uint and answer is type int, so we need to convert it.
        // to typecast means we did that uint256() around the answer * 1e10 to convert it to a different type.
    }

    // this function will convert the msg.value price(in the fund function) of eth into USD
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface dataFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(dataFeed);
        // we divide this by 1e18 because both eth price and ethAmount have 18 zeros, so the outcome would be 36 zeros if we dont divide.
        // you always want to multiply before you divide.
        // the user inputs in ethAmount
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}

```

Use the library in the main contract to get price of assets:
```js
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


error FundMe__NotOwner(); // custom errors save a ton of gas

contract FundMe {
    // to attach the Price Converter functions to all uint256s:
    using PriceConverter for uint256;

    // uint256 public minimumUsd = 5 * (10 ** 18); // you can do this
    uint256 public constant MINIMUM_USD = 5e18; // this is the same as above. 

    // an array of addresses called funders.
    address[] private s_funders;

    // a mapping, mapping the addresses and their amount funded.
    // the names "funder" and "amountFunded" is "syntaxic sugar", just makes it easier to read
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;

    // to be used in constructor
    address private immutable i_owner; // variables declared in the contract level but defined in the constructor, can be marked as immutable if they will not change. This will save gas
    // immutable varibles should use "i_" in their name

    // this variable is of type AggregatorV3Interface, and is used in the constructor. So that when deployed, the contract will read what chain we are on and use the correct pricefeed.
    AggregatorV3Interface private s_priceFeed;

    // the constructor is a function that gets immediately called when the contract is deployed.
    // the priceFeed parameter means that it takes a pricefeed address, and this will depend on the chain we are deploying to. This way the codebase is much more modular.
    constructor(address priceFeed) {
        // this pricefeed address is set in the deployment script input!
        // makes the deployer of this contract the "owner" of this contract.
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    // the "payable" keyword is allows functions to be sent $ from users
    function fund() public payable {
        // Allow users to send $
        // Have a minimum $ sent
        // 1e18 is equal to 1 ETH(which is also 1,000,000,000,000,000,000 wei(18-zeros)(which is also 1 * 10 ** 18(in solidity,  ** means exponent)))
        // require means if <first section> is false, then revert with the message of <second section>
        // because we are using the PriceConverter for all uint256, all uint256s now have access to getConversionRate. This way, when we write "msg.value.getConversionRate", the first value will be the first parameter, which is msg.value. So msg.value is ethAmount in the getConversionRate function. If we had a second parameter in the getConversaionRate, the second paramter would be whatever input would be passed into msg.value.getConversionRate() (in this case there is no second value).
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "didn't send enough ETH"); // "didn't send enough ETH" is the revert message if it reverts if the user does not send more than 1 eth.
        // msg.value is always in terms of ETH/wei
        // if the require statement fails, then all actions or code that have been executed in that function will revert as well.
        // if you send a failed transaction, you will still spend all as up to that failed transaction, if any remaining gas will be returned to the user.

        // this line keeps track of how much each sender has sent
        // you read it like: mapping(check the mapping) address => amount sent of the sender. So how much the sender sent = how much the sender has sent plus how much he is currently sending.
        // addressToAmountFunded[msg.sender] = addressToAmountFunded[msg.sender] + msg.value;
        //above is the old way. below is the shortcut with += . This += means we are adding the new value to the existing value that already exists.
        s_addressToAmountFunded[msg.sender] += msg.value;

        // the users whom successfully call this function will be added to the array.
        s_funders.push(msg.sender);
    }

    // we are making a cheaper Withdraw function because function `withdraw` is very expensive. When you read and write to storage it is very expensive. Whereas if you read and write to memory it is much much cheaper. Check evm.codes(website) to see how much each opcode cost in gas.
    function cheaperWithdraw() public onlyOwner {
        uint256 funderLength = s_funders.length; // this way we are only reading from the storage array `funders` one time and saving it as a memory variable
        for (uint256 funderIndex = 0; funderIndex < funderLength; funderIndex++) {
            // then here we loop through the memory instead of the storage
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, /* bytes memory dataReturned */ ) =
            payable(msg.sender).call{value: address(this).balance}(""); /*<- this is where we would put info of another function if we were calling another function(but we arent here so we leave it blank) */
        require(callSuccess, "Call Failed");
    }

    function withdraw() public onlyOwner {
        // for loop explanation:
        // [1, 2, 3, 4] elements   <-- below
        //  0, 1, 2, 3  indexes    <- so we would loop through the indexes to get all the elements out of this array

        // in a for loop, you first give it the starting index, then the ending index, and then the step amount
        // for example, if you want to go start at the 0th index, end at the 10th index, and increase by 1 every time, then it would be for (uint256 i = 0; i <= 10; i++)
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; /* length of the funders array */ funderIndex++) {
            /*++ means to add 1 after everytime we go through the following code in the brackets: */
            // we get the index position of the funders array, name this element funder
            address funder = s_funders[funderIndex];
            // then we reset this funders amount(this is tracked by the mapping of "addressToAmountFunded") to 0 when he withdraws
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        // there are three ways to transfer the funds: transfer, send, and call

        // msg.sender is of type address
        // payable(msg.sender) is of type payable address

        // transfers balance from this contract's balance to the msg.sender
        // payable(msg.sender).transfer(address(this).balance); //  this is how you use transfer
        // ^there is an issue with using transfer, as if it uses more than 2,300 gas it will throw and error and revert. (sending tokens from one wallet to another is already 2,100 gas)

        // we need to use "bool" here because when using "send", if the call fails, it will not revert the transaction and the user would not get their money. ("send" also fails at 2,300 gas)
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require sendSuccess to be true or it reverts with "Send Failed"
        // require(sendSuccess, "Send failed");

        // using "call" is lower level solidity and is very powerful, is the best one to use most of the time.
        // "call" can be used to call almost every function in all of ethereum without having an ABI!
        // using "call" returns a boolean and bytes data. The bytes arent important here so we commented it out and left the comma. (but really we would delete it if this was a production contract and we would leave the comma. however if we were calling a function we would keep the bytes data) (bytes objects are arrays which is why we use the memory keyword).
        (bool callSuccess, /* bytes memory dataReturned */ ) = payable(msg.sender).call{value: address(this).balance}(
            "" /*<- this is where we would put info of another function if we were calling another function(but we arent here so we leave it blank) */
        );
        //        calls the value to send to the payable(msg.sender)^

        // require callSuccess to be true or it reverts with "Call Failed"
        require(callSuccess, "Call Failed");
    }

    function getVersion() public view returns (uint256) {
        // this works because the address defined is correlated the functions "AggregatorV3Interface" and "version". We also imported the "AggregatorV3Interface" from chainlink.
        // return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
        // ^ we refactored this code because it was hardcoded to sepolia, to make it more modular, we change it to (below): ^
        return s_priceFeed.version();
        // ^this is more modular because now it will get the address of the pricefeed dependant on the chain we deployed to. ^
    }

    function getDecimals() public view returns (uint8) {
        return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).decimals();
    }

    modifier onlyOwner() {
        // requires the owner to be the only person allowed to call this withdraw function or reverts with "Must be Owner!"
        // require(msg.sender == i_owner, "Must be Owner!");

        // changed to use custom errors to save a ton of gas since. This saves alot of gas since we do not need to store and emit the revert Strings if the require statement fails.
        // this says that if the sender of the message is not the owner, then revert with custom error NotOwner.
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }

        // always needs to be in the modifier because modifiers are executed first in functions, then this underscore shows that after the modifier code is executed, to then go on and execute the code in the fucntion with the modifier.
        _;
        // if we had the underscore above the logic in this modifier, this means that we would execute the logic in the function with this modifier first and then execute the modifier's logic. So the order of the underscore matters!!!
    }

    // receive function is called when a transaction is sent to a contract that has no data. it can have not not have funds, but if it has no data, it will be received by the receive function. (the contract needs to have a receive function)
    receive() external payable {
        fund();
    }

    // fallback function is called when a transaction is sent to a contract with data, for example like if a user calls a function that does not exist, then it will be handled by the fallback function. (the contract needs to have a fallback function). the fallback function can also be used if the receive function is not defined.
    fallback() external payable {
        fund();
    }

    // Note: view functions use gas when called by a contract but not when called by a person.

    // if something is "unchecked", then that means when a value hits its max + 1, it will reset to 0.
    // after 0.8.0 of solidity, if a number reaches its max, the number will then fail instead of reseting. instead of overflowing or underflowing, it just fails.

    /**
     * View / Pure Functions (These are going to be our Getters)
     * Below are our Getter functions. by making storage variables private, they save more gas. Then by making view/pure functions to get the data within the private storage functions, it also makes the code much more readable.
     * These are called getter functions because all they do is read and return private data from the contracts storage without modifying the contract state.
     */

    // This function allows anyone to check how much eth a specific address has funded to the contract.
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        // takes the fundingAddress parameter that users input and reads and returns the amount that that address has funded. It is accessing the mapping of s_addressToAmountFunded which stores the funding history.
        return s_addressToAmountFunded[fundingAddress];
    }

    //this function allows anyone to input a number(index) and they will see whos address is at that index(number).
    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}

```

Have an `HelperConfig.s.sol` file that grabs the correct address of the pricefeed dependent on the chain we are deploying to:
```js
// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/* this contract will do the following:
1. Deploy mocks when we are on a local Anvil Chain
2. Keep track of contract addresses across different chains
*/

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // If we are on a local anvil, we deploy mocks.
    // Otherwise, grab the existing address from the live network.

    // we are declaring a variable named activeNetworkConfig of type struct NetworkConfig to use
    NetworkConfig public activeNetworkConfig;

    // to reduce magic numbers we defined these. these are the decimal count and start price of ETH/USD in the mockV3Aggregator.
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    // the items inside the FundMe.sol constructor
    struct NetworkConfig {
        address priceFeed; // ETH/USD pricefeed address
    }

    constructor() {
        // every blockchain has a chainId. The `block.chainid` is a key word from solidity.
        // this is saying "if we the chain we are on has a chainId of 11155111, then use `getSepoliaEthConfig()` (this getSepoliaEthConfig function returns the pricefeed address to use)"
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            // this is saying "if we the chain we are on has a chainId of 1, then use `getMainnetEthConfig()` (this getMainnetEthConfig function returns the pricefeed address to use)"
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            // if the chain is not 11155111, then use `getAnvilEthConfig()` (the getAnvilEthConfig function uses a mock to simulate the pricefeed since its a fake temporary empty blockchain and does not have chainlink pricefeeds)
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // we want to get the price feed address.
        // but what if we want more than just one variable? We create a struct (so we made struct NetworkConfig)!

        // this grabs the pricefeed address that we hardcoded and saves it to a variable named sepoliaConfig
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        // returns the variable sepoliaConfig when this function is called.
        return sepoliaConfig; //  This returns the pricefeed address saved in the variable gets passed to the deployment script to let it know what the address it to pull data from the address.
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        // we want to get the price feed address.
        // but what if we want more than just one variable? We create a struct (so we made struct NetworkConfig)!

        // this grabs the pricefeed address that we hardcoded and saves it to a variable named sepoliaConfig
        NetworkConfig memory ethConfig = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        // returns the variable sepoliaConfig when this function is called.
        return ethConfig; //  This returns the pricefeed address saved in the variable gets passed to the deployment script to let it know what the address it to pull data from the address.
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // we want to get the price feed address, but this is anvils local blockchain, that does not have pricefeeds.
        // so we need to deploy mocks onto the local blockchain(anvil) to simulate pricefeeds.

        // 1. Deploy Mocks
        // 2. Return the Mock addresses

        // this if statement is saying that if we already have deployed a mockV3Aggregator, to use that one instead of deploying a new one everytime.
        // if it is not address 0 then this means we already deployed it and it has an address, otherwise it would be 0 if it didnt exist.
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        } // we do not need an "else" clause here because once a return statement in a function is executed, the function immediately exits and no further code in that function will run.

        // everything inbetween the startBroadcast is being broadcasted to the blockchain. So here we are deploying the mock to anvil.
        vm.startBroadcast();
        // this says to deploy a new MockV3Aggregator and save it in a variable of MockV3Aggregator named mockPriceFeed.
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        // ^ we passed `8` and `2000e8` as parameters because the MockV3Aggregator's constructor asks for decimals and inital price. So here we are saying that the pair price feed that we are mocking(eth/usd) has 8 decimals and the starting price is 2000 with 8 decimals(2000e8). ^
        vm.stopBroadcast();

        // grabs the address of the mock pricefeed (within the struct we declared) and saves it as variable of type struct NetworkConfig named anvilConfig
        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        // returns this variable anvilConfig when this function is called. This returns the pricefeed address saved in the variable gets passed to the deployment script to let it know what the address it to pull data from the address.
        return anvilConfig;
    }
}

```

Have a deployment script that sets the correct pricefeed address dependent on the chain we are on(works with HelperConfig.s.sol):
```js
// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

// we must import Script.sol to tell foundry that this is a script.
import {Script} from "forge-std/Script.sol"; // we need to import the script package from foundry when working on scripts in foundry/solidity.
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

// this script will deploy our smart contracts. we should always deploy smart contracts this way.
// Script contracts always need to inherit from scripts
contract DeployFundMe is Script {
    // all deployments scripts need to have this "run" function because this will be the main function called when deploying the contract.
    function run() external returns (FundMe) {
        // this says that when we start this `run` function, it will create a new helperconfig of type HelperConfig contract.
        HelperConfig helperConfig = new HelperConfig();
        // because we send this before `vm.startBroadcast`, it is executing this code in a simulated environment. So it is grabbing the chainId that we are deploying to right before we deploy the contracts

        // we get the activeNetwork's pricefeed address and save it as a variable called "ethUsdPriceFeed"
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();
        // `activeNetworkConfig` is a variable of type struct, so if we had more variables in the struct, depending on what we would want we should save it as (address ethUsdPriceFeed, address exampleAddress, , ,)

        // "vm.startBroadcast" is a cheatcode from foundry. it tells foundry "everything after this line should be sent to the rpc"
        vm.startBroadcast();
        // this line says variable name "fundMe" of type contract FundMe is equal to a new FundMe contract that is now being created and the broadcast line deploys it.
        // FundMe fundMe = new FundMe(); // this line throws a warning since we do not use the variable fundMe
        // new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); // this also creates a new FundMe contract

        // we use this because now it will be more modular. All we do is now change this address and it will update our entire codebase.
        FundMe fundMe = new FundMe(ethUsdPriceFeed); // this address gets inputted into the FundMe constructor.
        vm.stopBroadcast();
        return fundMe; // because this returns the deployed fundMe contract, we can make changes and it will always return the change we made. making the testing easier and more modular.
    }
}

```



### Chainlink VRF 2.5 Notes
Help: https://updraft.cyfrin.io/courses/foundry/smart-contract-lottery/implementing-chainlink-vrf

The Chainlink VRF(Verifiable Random Function) is a way to generate a random number. Currently, chainlink has 2 ways of using this VRF, the `V2 Subscription Method` and `V2 Direct Funding Method`. The better option to use is `V2 Subscription Method` because it is much more scable. 
`V2 Subscription Method`: Fund the subscription and apply that to as many raffles/contracts/items as we want.
`V2 Direct Funding Method`: Everytime we deploy a new raffle/contract/item we would have to refund it. 

This section will be covering the ``V2 Subscription Method`` as it is better.

Getting a Random Number through Chainlink VRF is a 2-step process.
1. Request RNG (Random Number Generator) - We call the request in a transaction that we send
2. Get RNG (Random Number Generated) - Then the chainlink node is going to give us the random number in a transaction that it sends. It sends it in the callback function(a function that chainlink VRF calls back to.) 

Steps:
1. In the link `https://docs.chain.link/vrf/v2-5/getting-started` you will find a `Open in Remix Button`, click that to see the full code.
2. In `function rollDice` we can see the function calling Chainlink VRF for the RNG.
```javascript
  function rollDice(
        address roller
    ) public onlyOwner returns (uint256 requestId) {
        require(s_results[roller] == 0, "Already rolled");
        // Will revert if subscription is not set and funded.
        // this is the section we want, copy from here ->
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        ); // <- this is the section we want, copy to here

        s_rollers[requestId] = roller;
        s_results[roller] = ROLL_IN_PROGRESS;
        emit DiceRolled(requestId, roller);
    }
```
3. Copy and Paste this section(step 2) that we want into your code where you want to get a random number. Also copy the beginning of `function fulfillRandomWords`.
```js
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {}
```

4. This code will not work at first.  we need to import the chainlink contracts. Run `forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit`.
5. In the Remix Example, copy and paste the `VRFConsumerBaseV2Plus` import.
```javascript
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol"; // remove the version number from the import. Originally it has a @1.1.1 but thats only for remix
```
6. In the `foundry.toml` of your project, put an remapping in of:
```js
remappings = ['@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts']
```
7. Make sure your contract inherits from the import:
```js
contract Raffle is VRFConsumerBaseV2Plus {}
```
8. Update your constructor to inherit from Chainlink's VRF constructor.
Example:

Before Inheritance:
```js
contract Raffle {

    uint256 private immutable i_entranceFee; 
    uint256 private immutable i_interval;

    uint256 private s_lastTimeStamp;

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }
}

```


Chainlink VRF V2.5's constructor:
```js
abstract contract VRFConsumerBaseV2Plus is IVRFMigratableConsumerV2Plus, ConfirmedOwner {
  error OnlyCoordinatorCanFulfill(address have, address want);
  error OnlyOwnerOrCoordinator(address have, address owner, address coordinator);
  error ZeroAddress();

  // s_vrfCoordinator should be used by consumers to make requests to vrfCoordinator
  // so that coordinator reference is updated after migration
  IVRFCoordinatorV2Plus public s_vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) ConfirmedOwner(msg.sender) {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
  }
```

After Child Contract Inherits:
```js
contract Raffle is VRFConsumerBaseV2Plus {
     uint256 private immutable i_entranceFee; 
    uint256 private immutable i_interval;

    uint256 private s_lastTimeStamp;

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator) 
    // `VRFConsumerBaseV2Plus` is the name of the contract we are inheriting from
    VRFConsumerBaseV2Plus(vrfCoordinator) // here we are going to define the vrfCoordinator address during this contracts deployment, and this will pass the address to the VRFConsumerBaseV2Plus constructor.
    
    {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }
}

```

9. Import `VRFV2PlusClient` into your file as this is a file that the VRF needs. (import but do NOT inherit)
```js
import {VRFV2PlusClient} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
```

10. After doing everything above. we need to fill out the data in the pasted section that we copied from chainlink in step 2/3. You can read the comments here or read from the Chainlink docs to find out what the variables in example function `pickWinner` do. (https://docs.chain.link/vrf/v2-5/getting-started)
```js
contract Raffle is VRFConsumerBaseV2Plus {

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
        // sets the s_lastTimeStamp variable to the current block.timestamp when deployed.
        s_lastTimeStamp = block.timestamp;
        // keyHash to chainlink means the amount of max gas we are willing to pay. So we named it gasLane because we like gasLane as the name more
        i_keyHash = gasLane;
        // sets i_subscriptionId equal to the one set at deployment
        i_subscriptionId = subscriptionId;

        // Max amount of gas you are willing to spend when the VRF sends the RNG back to you
        i_callbackGasLimit = callbackGasLimit;
    }

    function pickWinner() external {
        // this checks to see if enough time has passed
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
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

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {}
}
```

11. After you have done all the steps above, you need to get a subscription ID. This way only you will have access to your subscription ID and no one else can use it.

To do this you need to Create the Subscription, Fund the subscription, then add a consumer.

Creating the Subscription:
example (from: `foundry-smart-contract-lottery-f23/Interactions.s.sol`):
```js 
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

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
```

Funding the Subscription:
example (from `foundry-smart-contract-lottery-f23/Interactions.s.sol`):
```js
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";


contract FundSubscription is Script, CodeConstants {
    // this says ether, but it really is (chain)LINK, since there are 18 decimals in the (CHAIN)LINK token as well
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
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
        fundSubscriptionUsingConfig();
    }
}
```

Adding Consumer:
First install foundry devops with `forge install Cyfrin/foundry-devops --no-commit` (or whatever the installtion says in https://github.com/Cyfrin/foundry-devops ).

Then we need to update the `foundry.toml` file to have read permissions on the broadcast folder.
example (from `foundry-smart-contract-lottery-f23/foundry.toml`):
```js
contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        // deploys a new helperConfig contract so we can interact with it
        HelperConfig helperConfig = new HelperConfig();
        // calls for the `subscriptionId` from the networkConfigs struct that getConfig returns from the HelperConfig contract
        uint256 subId = helperConfig.getConfig().subscriptionId;
        // calls for the `vrfCoordinator` from the networkConfigs struct that getConfig returns from the HelperConfig contract
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        // calls `addConsumer` and passes the mostRecentlyDeployed, vrfCoordinator, subId as parameters. we just identified `vrfCoordinator` and `subId`. `mostRecentlyDeployed` get passed in when the run function is called.
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId);
    }

    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subId) public {
        console.log("Adding consumer contract: ", contractToAddToVrf);
        console.log("To vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainId: ", block.chainid);
        // everything between startBroadcast and stopBroadcast will be broadcasted to the blockchain.
        vm.startBroadcast();
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
```

12. Then we need to add the CreateSubscription, FundSubscription and AddConsumer contracts and functions to our deploy script.
example (from DeployRaffle.s.sol):
```js
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
        if (config.subscriptionId == 0) {
            // deploys a new CreateSubscription contract from Interactions.s.sol and save it as a variable named createSubscription
            CreateSubscription createSubscription = new CreateSubscription();
            // calls the createSubscription contract's createSubscription function and passes the vrfCoordinator from the networkConfigs dependent on the chain we are on. This will create a subscription for our vrfCoordinator. Then we save the return values of the subscriptionId and vrfCoordinator and vrfCoordinator as the subscriptionId and values in our networkConfig.
            (config.subscriptionId, config.vrfCoordinator) =
                createSubscription.createSubscription(config.vrfCoordinator);

            // creates and deploys a new FundSubscription contract from the Interactions.s.sol file.
            FundSubscription fundSubscription = new FundSubscription();
            // calls the `fundSubscription` function from the FundSubscription contract we just created and pass the parameters that it takes.
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link);
        }

        // everything between startBroadcast and stopBroadcast is broadcasted to a real chain
        vm.startBroadcast();
        // create a new raffle contract with the parameters that are in the Raffle's constructor. This HAVE to be in the same order as the constructor!
        Raffle raffle = new Raffle(
            // we do `config.` before each one because our helperConfig contract grabs the correct config dependent on the chain we are deploying to
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callBackGasLimit
        );
        vm.stopBroadcast();

        // creates and deploys a new AddConsumer contract from the Interactions.s.sol file.
        AddConsumer addConsumer = new AddConsumer();
        // calls the `addConsumer` function from the `AddConsumer` contract we just created/deplyed and pass the parameters that it takes.
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId);

        // returns the new raffle and helperconfig that we just defined and deployed so that these new values can be used when this function `deployContracts` is called
        return (raffle, helperConfig);
    }
}

```

13. Finally, after we deploy the contract onto a testnet or mainnet, we need to register the new Upkeep with chainlink. To do this, go to vrf.chain.link and connect your wallet that deployed the contract. You should see that you have a new consumer added. Then switch from VRF, to automation and register a new Upkeep.

### Chainlink Automation (Custom Logic) Notes 

Chainlink Automation (formerly called Keeper Network) is a decentralized service that enables the automatic execution of smart contracts and other blockchain tasks when specific conditions are met. Think of it as a highly reliable, blockchain-native scheduling system. It can call any functions for you whenever you want.

help: `https://updraft.cyfrin.io/courses/foundry/smart-contract-lottery/chainlink-automation` & `https://updraft.cyfrin.io/courses/foundry/smart-contract-lottery/implementing-automation-2`

Steps:
1. In `https://docs.chain.link/chainlink-automation/guides/compatible-contracts` click on the "Open in Remix" button. Here you will see the the AutomationCounter example, as you can see, you need a checkUpkeep function and a performUpkeep function.

2. You will need to create a `checkUpkeep` and `performUpkeep` function. 
The `checkUpkeep` function will be called indefinitely by the chain link nodes until the Boolean in the return function of the `checkUpkeep` function returns true. Once it returns true it will trigger `performUpkeep`. The `checkUpkeep` function is the function that has all the requirements that are needed to be true in order to perform the automated task and the automated task that you want is in and performed in `performUpkeep`
Example:
```js
 /**
     * @dev this is the function that the chainlink nodes will call to see
     * if the lottery is ready to have a winner picked.
     * The following should be true in order for upkeepNeeded to be true:
     * 1. The time inteval has passes between raffle runs
     * 2. the lottery is open.
     * 3. The contract has ETH(has players)
     * 4. Implicitly, your subscription has LINK
     * @param - ignored
     * @return upkeepNeeded - true if it's time to restart the lottery
     */
    // checkData being commented out means that it is not being used anywhere in the function but it can be used if we want.
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (
            // variables defined in return function are already initialized. bool upkeepNeeded starts as false until updated otherwise.
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        // this checks to see if enough time has passed
        bool timHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        // the state of the raffle changes to open so players can join again.
        bool isOpen = s_raffleState == RaffleState.OPEN;
        // checks that this raffle contract has some money in it
        bool hasBalance = address(this).balance > 0;
        // checks there is at least 1 player
        bool hasPlayers = s_players.length > 0;
        // if all the above booleans are true, then upkeepNeeded will be set to true as well.
        upkeepNeeded = timHasPassed && isOpen && hasBalance && hasPlayers;
        // when this contract is called it will return whether or not upkeepNeeded is true or not. it will also return the performData but we are not using performData in this function so it is an empty string.
        return (upkeepNeeded, "");
    } // - chainlink nodes will call this function non-stop, and when it returns true, it will call performUpkeep.

    function performUpkeep(bytes calldata /* performData */ ) external {
        //
        (bool upkeepNeeded,) = checkUpkeep("");
        //
        if (!upkeepNeeded) {
            revert();
        }
    
        s_raffleState = RaffleState.CALCULATING;

        // the following is for calling to Chainlink VRF to get a randomNumber and has nothing to do with chainlink automation, this is just the automated task that is being performed in this example.
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
```

In this example, `checkUpkeep` checking to see if all the conditionals return true then if all the conditionals return true then the return boolean in the `checkUpkeep` function declaration returns true as well. Then once the `checkUpkeep` function returns that ` bool upkeepNeeded` is true, It will perform perform upkeep. The `performUpkeep` function makes sure that the `checkUpkeep` is true, then it calls for a random number to be generated from Chainlink VRF. (The Chainlink VRF to get a randomNumber task and has nothing to do with chainlink automation, this task is just the automated task that is being performed in this example. )


3. Finally, after we deploy the contract onto a testnet or mainnet, we need to register the new Upkeep with chainlink. To do this, go to automation.chain.link and register a new Upkeep. Connect your wallet that deployed the contract, and register the new upkeep. Click "Custom Logic" since that is what we are most likely using, then click next and it will prompt you for your contracts address. Input the contract address of the contract that was just deployed tat uses the Chainlink Automation. Then click next and enter the Upkeep details, such as the contract name and starting balance (it will ask for optional items, but you do not need to fill these out.). Then just click `Register Upkeep` and confirm the transaction in your metamask.

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## MAKEFILE Notes

A makefile is a way to create your own shortcuts. terminal commands in solidity can be very long, so you can essentially route your own shortcuts for terminal commands. Also, the `Makefile` needs to be `Makefile` and not `MakeFile` (the `f` needs to be lowercase) or `make` commands will not work.

If you want to include the `.env` variables, then at the top of the MakeFile, write `--include .env`. Environment Variables must be have a $ in front of it and be wrapped in parenthesis(). Example: ` $(SEPOLIA_RPC_URL) `

The way to create a short cut in a Makefile is to write the shortcut on the left, and the command that is being rerouted goes on the right in the following format:
`build:; forge build`. OR the shortcut goes on the left, and the command being rerouted goes below and indented with TAB in the format of:

```MakeFile
-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit && forge install transmissions11/solmate@v6 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy:
	@forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_ARGS)

createSubscription:
	@forge script script/Interactions.s.sol:CreateSubscription $(NETWORK_ARGS)

addConsumer:
	@forge script script/Interactions.s.sol:AddConsumer $(NETWORK_ARGS)

fundSubscription:
	@forge script script/Interactions.s.sol:FundSubscription $(NETWORK_ARGS)



```

Then to run a Makefile command, run `make <shortcut-name>`. Example: `make build` !!!
For example:
(the .PHONY is to tell the MakeFile that the commands are not folders)


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Everything ZK-SYNC Notes

Zk-sync is a rollup L2.


### Zk-SYNC Foundry Notes
When deploying to ZK-sync, you want to use the zk-sync version of foundry. Learn more at https://github.com/matter-labs/foundry-zksync. learn more @ https://updraft.cyfrin.io/courses/foundry/foundry-simple-storage/foundry-zksync. this is course "Foundry Fundamentals" section 1, video #27 - #32

0. run `forge --version`
1. clone the repo in the parent directory. so the parent directory for this file(soundry-simple-storage-F23) would be foundry-23. once in the parent directory, clone the repo with `git clone git@github.com:matter-labs/foundry-zksync.git` or whatever the clone is at the time you are reading this.
2. this will create a new zksync folder that we can cd into. so cd into it. (this would be in the parent directory you just cloned the repo into).
3. then once inside the new directory, run `./install-foundry-zksync` (you have to be on linux or wsl or ubuntu).
4. now go back to the directory you want to deploy to zksync and run `forge --version`, you will see it is now slightly different.
5. in the directory you want to deploy to zksync run `foundryup-zksync`. this will install the latest version of foundry zksync.

Now you are all done! If you run `forge build --help` you will see there is now zksync flags.

 *** If you want to switch back to vanilla/base foundry, run `foundryup` ***
and if you want to switch back to zksync foundry, just run `foundryup-zksync` as you already have the pre-requisites.

when we run `forge build` in vanilla foundry, we get an `out` folder that has all the compilation details. when we run `forge build --zksync` in zksync foundry, we get a `zkout` folder with all the compilation details for zksync.

### Deploying on ZK-SYNC Notes

#### Running a local zkSync test node using Docker, and deploying a smart contract to the test node.
to learn more, learn more @ https://github.com/Cyfrin/foundry-simple-storage-cu and at the bottom it has a "zk-Sync" intructions

run `foundryup-zksync`
install docker.
to deploy to zksync, use `forge create`.

There are more steps for a local zkSync test node. To find out more watch course "Foundry Fundamentals" section 1, video #29 and #30. 

Will update this later!


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


## ERC-20s

ERC = Ethereum Request of Comments

ERC-20s are the industry standard of Tokens. ERC-20s represent tokens, but they are also smart contracts.





------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## EIP Notes 

EIP = Ethereum Improvement Proposal

EIPs are a way for the community to suggest improvements to industry standards.



### EIP status terms
1. Idea - An idea that is pre-draft. This is not tracked within the EIP Repository.

2. Draft - The first formally tracked stage of an EIP in development. An EIP is merged by an EIP Editor into the EIP repository when properly formatted.

3. Review - An EIP Author marks an EIP as ready for and requesting Peer Review.

4. Last Call - This is the final review window for an EIP before moving to FINAL. An EIP editor will assign Last Call status and set a review end date (`last-call-deadline`), typically 14 days later. If this period results in necessary normative changes it will revert the EIP to Review.

5. Final - This EIP represents the final standard. A Final EIP exists in a state of finality and should only be updated to correct errata and add non-normative clarifications.

6. Stagnant - Any EIP in Draft or Review if inactive for a period of 6 months or greater is moved to Stagnant. An EIP may be resurrected from this state by Authors or EIP Editors through moving it back to Draft.

7. Withdrawn - The EIP Author(s) have withdrawn the proposed EIP. This state has finality and can no longer be resurrected using this EIP number. If the idea is pursued at later date it is considered a new proposal.

8. Living - A special status for EIPs that are designed to be continually updated and not reach a state of finality. This includes most notably EIP-1.















------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




## Keyboard Shortcuts:

`ctrl` + `a` = select everything
`ctrl` + `b` = open left side bar
`ctrl` + `c` = copy
`ctrl` + `k`(in terminal) = clears terminal (VSCode)
`ctrl` + `l` = open AI chat 
`ctrl` + `n` = new tab
`ctrl` + `p` = command pallet
`ctrl` + `s` = save file
`ctrl` + `v` = paste
`ctrl` + `w` = closes currently active/focused tab
`ctrl` + `y` = redo
`ctrl` + `z` = undo
`ctrl` + `/` = commenting out a line
`ctrl` + ` = toggle terminal
`ctrl` + `shift` + `t` = reopen the last closed tab
`ctrl` + `shift` + `v` = paste without formating
`ctrl` + <arrowKey> = move cursor to next word
`ctrl` + `shift` + (←/→)<arrowKey> = select word by word
`ctrl` + `shift` + (↑/↓)<arrowKey> = select line by line
`alt` + (←/→)(<arrowKey>) = return to previous line in code
`alt` + (↑/↓)<arrowKey> = move lines of code up or down
`ctrl` + `alt` + (↑/↓)<arrowKey> = new cursor to edit many code lines simultaneously
`crtl` + `alt` + (←/→)(<arrowKey>) = splitScreen view of code files
`shift` + `alt` + (↑/↓)(<arrowKey>) = duplicate current line  
`shift` + `alt` + (←/→)(<arrowKey>) = expanding or shrinking your text selection blocks
`ctrl` + `shift` + `alt` + (←/→)(<arrowKey>) = selecting letter by letter
`ctrl` + `shift` + `alt` + (↑/↓)(<arrowKey>) = new cursor to edit many code lines simultaneously
`fn` + (←/→)(<arrowKey>) = beginning or end of text
`ctrl` + `fn` + (←/→)(<arrowKey>) = beginning or end of page/file
`ctrl` + `fn` + (↑/↓)(<arrowKey>) = switch through open tabs
`fn` + `alt` + (↑/↓)(<arrowKey>) = scroll up or down
`shift` + `fn` + (↑/↓)(<arrowKey>) = selects 1 page of items above or below
`shift` + `fn` + (←/→)(<arrowKey>) = select everything on current line from cursor position.
`ctrl` + `shift` + `fn` + (↑/↓)(<arrowKey>) = moves tab location
`ctrl` + `shift` + `fn` + (←/→)(<arrowKey>) = selects all text to beginning or end from your cursor position.
`ctrl` + `shift` + `alt` + `fn` + (↑/↓)(<arrowKey>) = new cursors created up to 1 page above or below

