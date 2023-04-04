# Protoss Exchange Contracts

## Introduction

The world of decentralized finance (DeFi) has been evolving rapidly over the past few years, offering new possibilities for financial transactions without intermediaries. One of the most popular use cases in DeFi is the ability to swap tokens. In this project, we present a smart contract that implements a swap feature using the StarkNet chain.

The smart contract is composed of three main contracts: the Factory, Pair, and Router contracts. The Factory contract is responsible for creating new Pair contracts that will allow users to swap tokens. The Pair contract is responsible for maintaining the liquidity of the tokens being swapped. The Router contract is responsible for executing the swaps between different tokens.

The StarkNet chain is a high-throughput, low-latency, and secure blockchain designed to support complex smart contracts. The choice of StarkNet chain ensures that our smart contract is able to handle a large number of transactions while maintaining a high level of security.

In this project, we will explore the design and implementation of our smart contract, including the algorithms used to ensure fair pricing and efficient execution of swaps. We will also discuss the benefits of using the StarkNet chain and the potential applications of our smart contract in the DeFi ecosystem.

Overall, our smart contract provides a reliable and efficient way for users to swap tokens on the StarkNet chain. It is a valuable addition to the DeFi ecosystem and represents an important step forward in the development of decentralized financial systems.

## Verfiy Contract

Use `starkscan` to verify contract.

`npm install -g starkscan`

## [Mainnet] Contract Address / Class Hash

### Class Hash
- Pair: https://starkscan.co/class/0x07f052fb14fc79a77eea424b14ac2126400bed7b4e79b6b01b4dbcf823ec15d0
- Router: https://starkscan.co/class/0x04e30750c4e203e514b5910ad9702d1525f43a04bb03abef45c30fccf6a3437a
- Factory: https://starkscan.co/class/0x07b2dcbbf952e8668b4ab2afe40b99e6a023d5355f332f27644a0cac6537af48

### Contract Address
- Factory: https://starkscan.co/contract/0x04bd9ec70e3ee64fe0adefe0ae4eff797fe07b6fe19d72438db0b6d336ee77c8
- Router: https://starkscan.co/contract/0x07a0922657e550ba1ef76531454cb6d203d4d168153a0f05671492982c2f7741

## [Testnet] Contract Address / Class Hash

### Class Hash
- Pair: https://testnet.starkscan.co/class/0x07f052fb14fc79a77eea424b14ac2126400bed7b4e79b6b01b4dbcf823ec15d0
- Router: https://testnet.starkscan.co/class/0x04e30750c4e203e514b5910ad9702d1525f43a04bb03abef45c30fccf6a3437a
- Factory: https://testnet.starkscan.co/class/0x07b2dcbbf952e8668b4ab2afe40b99e6a023d5355f332f27644a0cac6537af48

### Contract Address
- Factory: https://testnet.starkscan.co/contract/0x0017b7cdbd6dd86b4b9baf572e040e74bd44b419dcbb6f38a2e936aec9327b8e
- Router: https://testnet.starkscan.co/contract/0x005a25278b5b3d935d5871fe8f8cf824840dd7a9082dcbd5d37ab2e74747b2ed
