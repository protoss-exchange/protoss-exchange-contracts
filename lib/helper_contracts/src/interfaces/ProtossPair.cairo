%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IProtossPair {
    //
    // ERC20
    //
    func name() -> (name : felt) {
    }

    func symbol() -> (symbol : felt) {
    }

    func decimals() -> (decimals : felt) {
    }

    func totalSupply() -> (totalSupply : Uint256) {
    }

    func balanceOf(account : felt) -> (balance : Uint256) {
    }

    func allowance(owner : felt, spender : felt) -> (remaining : Uint256) {
    }

    func transfer(recipient : felt, amount : Uint256) -> (success : felt) {
    }

    func transferFrom(sender : felt, recipient : felt, amount : Uint256) -> (success : felt) {
    }

    func approve(spender : felt, amount : Uint256) -> (success : felt) {
    }

    //
    // Pair
    //
    func MINIMUM_LIQUIDITY() -> (value : Uint256) {
    }

    func factory() -> (factory : felt) {
    }

    func token0() -> (token0 : felt) {
    }

    func token1() -> (token1 : felt) {
    }

    func getReserves() -> (reserve0 : felt, reserve1 : felt, blockTimestampLast : felt) {
    }

    func price0CumulativeLast() -> (price0 : Uint256) {
    }

    func price1CumulativeLast() -> (price1 : Uint256) {
    }

    func kLast() -> (kLast : Uint256) {
    }

    func mint(to : felt) -> (liquidity : Uint256) {
    }

    func burn(to : felt) -> (amount0 : Uint256, amount1 : Uint256) {
    }

    func swap(amount0Out : Uint256, amount1Out : Uint256, to : felt) -> () {
    }

    // force balances to match reserves
    func skim(to : felt) -> () {
    }

    // force reserves to match balances
    func sync() -> () {
    }

    func initialize(token0 : felt, token1 : felt) -> () {
    }
}