# Notes 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Getting Started

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




### Visibility Modifiers:

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

### Variables
The Following variable types must be declared at the contract level (not in any functions):

#### Constants
Variables that will never be updated or changed can be listed as constant. 
For example:
`uint8 public constant DECIMALS = 8; ` - constant veriable should be CAPITALIZED as seen in this example.
Constant variables are directly embedded in the bytecode. This saves gas.


#### Immutable
Variables that are declared at the contract level but initialized in the constructor can be listed as Immutable. This saves gas.
For Example:
```javascript
address public immutable i_owner; // As you can see immutable variables should be named with an `i_` infront of the name

 constructor() {
        i_owner = msg.sender; // As you can see immutable variables should be named with an `i_` infront of the name
    }
``` 
Immutable variables are directly embedded in the bytecode when the contract is deployed and can only be set once during contract construction.

#### Storage Variables
Variables that are not constant or immutable but are declared at the contract level at saved in storage. So these variables should be named with `s_`.
For Example:
```javascript
    address[] public s_funders;
    mapping(address funder => uint256 amountFunded) public s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;
```
State Variables declared at contract level by default ARE stored in storage.


#### Saving Gas with Storage Variables

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

#### Custom Error Variables

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

### Events
When a storage variable is updated, we should always emit an event. This makes migration/version-updates of contracts much easier and events make front-end "indexing" much easier. It allows for the smart contract, front-end, and blockchain to easily know when something has been updated.
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




------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Package Installing:

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

## Remappings in foundry.toml:
Remappings tell foundry to replace the mapping for imports. 
for example:
```javascript
 remappings = ["@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/"]  // in this example, we are telling foundry that everytime it sees @chainlink/contracts/ , it should point to lib/chainlink-brownie-contracts/ as this is where our packages that we just installed stays
 ```


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Writing Tests For Smart Contracts

All Smart Contracts must have tests. You need tests before going for a smart contract audit or you will be turned away.

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
`-vvvvv`=

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



 ### Sending money in tests:
 When writing a test in solidity and you want to pass money to the test, you write it like this:
 ```javascript
  function testFundUpdatesFundedDataStructure() public {
        fundMe.fund{value: 10e18}();
    }
 ```
 because the fund function that we are calling does not take any parameter, it should be written like `fundMe.fund{value: 10e18}();` and not like ``fundMe.fund({value: 10e18});``. This is because the fund function does not take any parameters but is payable. So {value: 10e18} is the value being passed while () is the parameters being passed. IF the fund function was written like `function fund(uint256 value) public payable {}` then the test line of `fundMe.fund({value: 10e18}); ` would indeed work.

 ### GAS INFO IN TESTS
 When working on tests in anvil, the gas price defaults to 0. So for us to simulate transactions in test with actual gas prices, we need to tell our tests to actually use real gas prices. This is where `vm.txGasPrice` comes in. (See `vm.txGasPrice` below in cheatcodes for tests)

 ### CHEATCODES FOR TESTS
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
 ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 ## Chisel

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

## Scripts

### Getting Started with Scripts

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

### Deploying A Script
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


### Interaction Scripts
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

## BroadCast Folder:

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

## DEPLOYING PRODUCTION CONTRACTS


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

### Verifying a Deploying Contract:

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




------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## How to interact with deployed contracts from the command line:

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

## MAKEFILE

A makefile is a way to create your own shortcuts. terminal commands in solidity can be very long, so you can essentially route your own shortcuts for terminal commands. Also, the `Makefile` needs to be `Makefile` and not `MakeFile` (the `f` needs to be lowercase) or `make` commands will not work.

If you want to include the `.env` variables, then at the top of the MakeFile, write `--include .env`. Environment Variables must be have a $ in front of it and be wrapped in parenthesis(). Example: ` $(SEPOLIA_RPC_URL) `

The way to create a short cut in a Makefile is to write the shortcut on the left, and the command that is being rerouted goes on the right in the following format:
`build:; forge build`. OR the shortcut goes on the left, and the command being rerouted goes below and indented with TAB in the format of:
```MakeFile
build:
    forge build 
```

Then to run a Makefile command, run `make <shortcut-name>`. Example: `make build` !!!
For example:
(the .PHONY is to tell the MakeFile that the commands are not folders)
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




--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Everything ZK-SYNC

Zk-sync is a rollup L2.


### Zk-SYNC Foundry
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

### Deploying on ZK-SYNC

#### Running a local zkSync test node using Docker, and deploying a smart contract to the test node.
to learn more, learn more @ https://github.com/Cyfrin/foundry-simple-storage-cu and at the bottom it has a "zn-Sync" intructions

run `foundryup-zksync`
install docker.
to deploy to zksync, use `forge create`.

There are more steps for a local zkSync test node. To find out more watch course "Foundry Fundamentals" section 1, video #29 and #30. 

Will update this later!


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Keyboard Shortcuts:

`ctrl` + `a` = select everything
`ctrl` + `b` = open left side bar
`ctrl` + `c` = copy
`ctrl` + `k`(in terminal) = clears terminal (VSCode)
`ctrl` + `l` = open AI chat 
`ctrl` + `n` = new tab
`ctrl` + `s` = save file
`ctrl` + `v` = paste
`ctrl` + `w` = closes currently active/focused tab
`ctrl` + `y` = redo
`ctrl` + `z` = undo
`ctrl` + `/` = commenting out a line
`ctrl` + ` = toggle terminal
`ctrl` + `shift` + `t` = reopen the last closed tab
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

