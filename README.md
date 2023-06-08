# OTC Swap

### Exercise A:

Write a smart contract for conducting atomic over-the-counter (OTC) swaps of ERC20 tokens. Specifically, the contract you write should support the use case where Alice and Bob agree to an exchange – Alice will trade her M of tokenX for Bob’s N of tokenY, to be completed in a single “atomic” transaction. Additionally:

- Swaps should be able to specify a counterparty – if Alice and Bob agree to a swap, Eve (a third party) should not be able to replace either Alice or Bob in the swap, unless they have explicitly agreed to make the same swap with Eve
- Swaps should expire, i.e. they should only be executable within a specified timeframe

Provide a brief explanation of some of the decisions you made in the process.

### Requirements:

1. Write the Solidity code for the smart contract.
2. Write a few (FOUR or less) test cases for the contract.
   a. YOU DO NOT HAVE TO WRITE THE TESTS THEMSELVES – merely explain how you would test the contract and why you have chosen these tests.
3. Make sure your tests cover key functional aspects of the smart contract (apply judgment).

### Deliverables:

1. Solidity code for the smart contract. Submit a single, flattened file.
2. A document outlining
   a. Test cases (Optional: Code for a few tests)
   b. Explanation of design choices/decisions, and any assumptions you made.
3. [Optional] A README.md file explaining how to run the tests (if you are including code for these tests).

## Setup

1. Clone repository

```
git clone git@github.com:mehtaculous/atomic-swap.git
```

2. Create `.env` file in root

```
DEPLOYER_PRIVATE_KEY=
ETHERSCAN_API_KEY=
GOERLI_RPC_URL=
```

3. Install dependencies

```
npm ci
forge install
```

3. Run all tests (Stack traces: `-vvvvv` | Gas report: `--gas-report`)

```
forge test --mc AtomicSwapTest
forge test --mc AtomicSwapTest -vvvvv
forge test --mc AtomicSwapTest --gas-report
```

4. Run individual tests

```
forge test --mt testInitialize
forge test --mt testExecute
forge test --mt testCancel
```

5. Deploy contracts

```
forge script script/Deploy.s.sol:Deploy --rpc-url $GOERLI_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --verify --etherscan-api-key $ETHERSCAN_API_KEY --broadcast
```

## Implementation

1. I used a struct to store all the information regarding a swap, and attempted to pack a few variables together into the same storage slots. I decided to use `uint88` (11 bytes) for the _expiry_ timestamp so that I could pack it together with the _initialized_ `bool` value (1 byte) and the _initiator_ `address` (20 bytes). I also used `uint128` (16 bytes) for both token _amounts_ in order to pack them together since using anything more seemed a bit excessive and unncessary.

2. I stored all swaps inside a mapping with a `swapId` as the key. Instead of keeping track of a global counter which increments in a predicable manner, I decided to hash the swap info and convert that to a `uint256` value. Doing so prevented the use of an additional storage slot for the counter, as well as additional gas for incrementing the counter each time _initialize_ is called. Also, the info of each swap ensures that every `swapId` will always be unique and there will never be any duplicates.

3. I used _checks, effects and interactions_ to make sure the contract state is first updated before transferring any tokens. This is done to prevent reentrancy attacks, but I could have simply also just added a **Reentrancy Guard**.

4. I considered checking that the token contracts passed in were valid `ERC-20` tokens, but ultimately decided not to since the transfers would simply revert if they didn't support the standard. This was ultimately done to improve optimization but could possibly result in a bad user experience.

5. For testing, I not only tested the implementation of each function to verify the contract state was updated correctly, but I also tested each custom _revert_ to ensure that all errors were flagged accordingly:
   - `initialize` tests will revert when the swap already exists and when the expiration time is before the current time
   - `execute` tests will revert when the swap does not exist, when the caller is not the counterparty of the swap, and when the expiration time has already passed
   - `cancel` tests will revert when the swap does not exist and when the caller is not the initiator of the swap
   - `initialize` and `execute` tests will revert when token allowances for the `AtomicSwap` contract are insufficient

## Gas Report

| src/AtomicSwap.sol:AtomicSwap contract |                 |        |        |        |         |
| -------------------------------------- | --------------- | ------ | ------ | ------ | ------- |
| Deployment Cost                        | Deployment Size |        |        |        |         |
| 611645                                 | 3087            |        |        |        |         |
| Function Name                          | min             | avg    | median | max    | # calls |
| cancel                                 | 1211            | 3353   | 3366   | 5472   | 4       |
| execute                                | 1326            | 14012  | 6560   | 49526  | 5       |
| initialize                             | 1459            | 108040 | 130191 | 130191 | 12      |
| swaps                                  | 1305            | 2257   | 1305   | 11305  | 42      |

## Additional Features

1. A fee switch for initializing and execting swaps

2. Implement admin functionality using `Ownable` or `AccessControl`

3. Allow for One to Many token swaps

4. An Oracle that calculates the token prices and verifies that they are both within a given ratio in order to successfully execute the swap

5. Allow swaps of other token standards, such as `ERC-721` and `ERC-1155` tokens
