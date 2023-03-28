%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IProtossRouter {
    func factory() -> (factory : felt) {
    }

    func quote(amountA : Uint256, reserveA : felt, reserveB : felt) -> (amountB : Uint256) {
    }

    func getAmountOut(amountIn : Uint256, reserveIn : felt, reserveOut : felt) -> (
        amountOut : Uint256
    ) {
    }

    func getAmountIn(amountOut : Uint256, reserveIn : felt, reserveOut : felt) -> (
        amountIn : Uint256
    ) {
    }

    func getAmountsOut(amountIn : Uint256, path_len : felt, path : felt*) -> (
        amounts_len : felt, amounts : Uint256*
    ) {
    }

    func getAmountsIn(amountOut : Uint256, path_len : felt, path : felt*) -> (
        amounts_len : felt, amounts : Uint256*
    ) {
    }

    func addLiquidity(
        tokenA : felt,
        tokenB : felt,
        amountADesired : Uint256,
        amountBDesired : Uint256,
        amountAMin : Uint256,
        amountBMin : Uint256,
        to : felt,
        deadline : felt,
    ) -> (amountA : Uint256, amountB : Uint256, liquidity : Uint256) {
    }

    func removeLiquidity(
        tokenA : felt,
        tokenB : felt,
        liquidity : Uint256,
        amountAMin : Uint256,
        amountBMin : Uint256,
        to : felt,
        deadline : felt,
    ) -> (amountA : Uint256, amountB : Uint256) {
    }

    func swapExactTokensForTokens(
        amountIn : Uint256,
        amountOutMin : Uint256,
        path_len : felt,
        path : felt*,
        to : felt,
        deadline : felt,
    ) -> (amounts_len : felt, amounts : Uint256*) {
    }

    func swapTokensForExactTokens(
        amountOut : Uint256,
        amountInMax : Uint256,
        path_len : felt,
        path : felt*,
        to : felt,
        deadline : felt,
    ) -> (amounts_len : felt, amounts : Uint256*) {
    }

    func swapExactTokensForTokensSupportingFeeOnTransferTokens(
        amountIn : Uint256,
        amountOutMin : Uint256,
        path_len : felt,
        path : felt*,
        to : felt,
        deadline : felt,
    ) {
    }
}