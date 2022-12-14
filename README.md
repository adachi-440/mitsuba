![logo](docs/mitsuha_logo.png)

# Mitsuba - Cross Chain Voting System

## Summary

Mitsuba is a cross-chain voting system.
Messaging allows voting from multiple chains to be combined into a single proposal.

## Problem

While many protocols these days are multi-chain deployments, the ability to vote is often limited to one chain. This requires bridging assets to that chain in order to vote, compromising the UX; some products support multiple chains on the web, but the data cannot be managed on-chain and is not well decentralized.

## Solution

Develop an omnichain voting system that allows voting from any chain.
When a user casts a vote, the vote is sent to the chain that submitted the proposal using messaging.

Also, this token adopts Omni Chain FT (OFT) proposed by LayerZero. Therefore, it is easy to move assets, and the UX of cross-chain governance is improved.

### Architecture

Here is the architecture.

![architecture](/docs//cross-voting.jpg)
The base contract for voting is implemented in Mumbai, and when you vote in Mumbai, your vote is based on that base contract.

For the rest of the chain, it will execute the vote request of the VoteRequest contract. In the process, we use a messaging interface that we have developed ourselves (details [here](https://github.com/adachi-440/messaging-interfaces)). This interface binds together the different endpoints of each messaging protocol.

Send this interface to the Mumbai base contract by choosing the best messaging protocol.
Then run the vote on the base contract.

In addition, when voting, we adopt a meta-transaction using Biconomy, so users do not have to pay for gas when voting(However, currently you can only use metatransactions if you vote in Mumbai).

## User Flow

1. Create new proposals
2. Mint multiple chains of tokens for voting
3. Stake token
4. Vote
5. Proposals are tabulated using messaging

## Future Work

In the future, we hope to do two things

1. Integrate many chains
   Integrate more messaging protocols to allow voting from different chains. It will also allow voting to be sent using the most appropriate messaging protocol, comparing security, gas costs, speed of transaction, etc.

2. Providing a gasless solution
   Currently Mumbai only, so other chains will be able to perform metatransactions

## Deployed contract

### Mumbai

| contract |                           contract address |
| :------- | -----------------------------------------: |
| Voting   | 0x2A1b3760d3AEcC8E6b8965404409596084664441 |
| OFT      | 0xBcA9C6f43F2AE64682E92a8404732cC4C26c52FB |

### Moonbase

| contract    |                           contract address |
| :---------- | -----------------------------------------: |
| VoteRequest | 0x7268d5bc5AD0d3E0f333a481a306108A766b0A8C |
| OFT         | 0xDd14C00Aa47b585c06d48F8FaCB6EaB9a20aCdDc |

### Arbitrum Goerli

| contract    |                           contract address |
| :---------- | -----------------------------------------: |
| VoteRequest | 0x26D3Fe47c2948Ff67650dA41AD54cb615504F310 |
| OFT         | 0xB9207fFEf813A97394a814098f37a11B9523D7Ae |

### Optimism Goerli

| contract    |                           contract address |
| :---------- | -----------------------------------------: |
| VoteRequest | 0x79b71573F5c73D89C767717D98693FDd7d6C942B |
| OFT         | 0x88650b018f0F0981d8C136B25d7e12F1e2ffd264 |

## Transactions

The product makes it easy to use Hyperlane, LayerZero, and Axelar messaging through a proprietary messaging protocol interface.
The transaction of each messaging protocol using it is as follows.

Hyperlane: https://explorer.hyperlane.xyz/message/113809

LayerZero: https://moonbase.moonscan.io/tx/0xee9d49943ebd5edc3f7add162910a5c7c7292fe6321fc6b55c6c0603bd7aa742

Axelar: https://testnet.axelarscan.io/gmp/0xa8687aec7fbcbf6f1d4258398afad992b6d64b0256f3e31ec80c8fe2e775eb75

## Others

### The repo of messaging interface

https://github.com/adachi-440/messaging-interfaces

### The repo of frontend

https://github.com/adachi-440/cross-chain-voting-frontend

### Demo movie

https://www.youtube.com/watch?v=pDM4ci3XoFk&feature=youtu.be

### Demo site

https://cross-chain-voting-frontend.vercel.app
