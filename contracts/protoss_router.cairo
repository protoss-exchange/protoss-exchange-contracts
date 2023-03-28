%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_le_felt, is_not_zero
from starkware.cairo.common.bitwise import bitwise_or, bitwise_and
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_lt
from starkware.cairo.common.math import assert_nn, assert_not_equal, assert_not_zero
from starkware.starknet.common.syscalls import (
    deploy,
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)
from starkware.cairo.common.hash import hash2

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.security.safemath.library import SafeUint256

from interfaces.ProtossFactory import IProtossFactory
from interfaces.ProtossPair import IProtossPair
from libraries.protoss_library import ProtossLibrary

@storage_var
func _factory() -> (factory : felt) {
}

@storage_var
func _pairClass() -> (pairClass : felt) {
}

//
// Constructor
//

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    factory : felt, pairClass : felt
) {
    _factory.write(factory);
    _pairClass.write(pairClass);
    return ();
}

//
// Getters
//

@view
func factory{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    factory : felt
) {
    let (value) = _factory.read();
    return (factory=value);
}

@view
func quote{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amountA : Uint256, reserveA : felt, reserveB : felt
) -> (amountB : Uint256) {
    let (amountB : Uint256) = ProtossLibrary.quote(amountA, reserveA, reserveB);
    return (amountB=amountB);
}

@view
func getAmountOut{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amountIn : Uint256, reserveIn : felt, reserveOut : felt
) -> (amountOut : Uint256) {
    let (amountOut : Uint256) = ProtossLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    return (amountOut=amountOut);
}

@view
func getAmountIn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amountOut : Uint256, reserveIn : felt, reserveOut : felt
) -> (amountIn : Uint256) {
    let (amountIn : Uint256) = ProtossLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    return (amountIn=amountIn);
}

@view
func getAmountsOut{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amountIn : Uint256, path_len : felt, path : felt*
) -> (amounts_len : felt, amounts : Uint256*) {
    let (factory) = _factory.read();
    let (pairClass) = _pairClass.read();

    let (amounts_len, amounts : Uint256*) = ProtossLibrary.getAmountsOut(
        factory, pairClass, amountIn, path_len, path
    );
    return (amounts_len=amounts_len, amounts=amounts);
}

@view
func getAmountsIn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amountOut : Uint256, path_len : felt, path : felt*
) -> (amounts_len : felt, amounts : Uint256*) {
    let (factory) = _factory.read();
    let (pairClass) = _pairClass.read();

    let (amounts_len, amounts : Uint256*) = ProtossLibrary.getAmountsIn(
        factory, pairClass, amountOut, path_len, path
    );
    return (amounts_len=amounts_len, amounts=amounts);
}

//
// Externals
//

@external
func addLiquidity{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(
    tokenA : felt,
    tokenB : felt,
    amountADesired : Uint256,
    amountBDesired : Uint256,
    amountAMin : Uint256,
    amountBMin : Uint256,
    to : felt,
    deadline : felt,
) -> (amountA : Uint256, amountB : Uint256, liquidity : Uint256) {
    alloc_locals;

    _ensure(deadline);

    let (factory) = _factory.read();
    let (pairClass) = _pairClass.read();
    let (caller) = get_caller_address();

    let (amountA : Uint256, amountB : Uint256) = _addLiquidity(
        tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin
    );
    let (pair) = ProtossLibrary.pairFor(factory, pairClass, tokenA, tokenB);

    // TODO. Not implemented safeTransferFrom
    IERC20.transferFrom(contract_address=tokenA, sender=caller, recipient=pair, amount=amountA);
    IERC20.transferFrom(contract_address=tokenB, sender=caller, recipient=pair, amount=amountB);

    let (liquidity : Uint256) = IProtossPair.mint(contract_address=pair, to=to);

    return (amountA=amountA, amountB=amountB, liquidity=liquidity);
}

@external
func removeLiquidity{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenA : felt,
    tokenB : felt,
    liquidity : Uint256,
    amountAMin : Uint256,
    amountBMin : Uint256,
    to : felt,
    deadline : felt,
) -> (amountA : Uint256, amountB : Uint256) {
    alloc_locals;

    _ensure(deadline);

    let (amountA : Uint256, amountB : Uint256) = _removeLiquidity(tokenA, tokenB, liquidity, to);

    // Insufficient_a_amount
    with_attr error_message("ProtossSwapRouter: IAA") {
        let (lt0) = uint256_lt(amountA, amountAMin);
        assert lt0 = FALSE;
    }

    // Insufficient_b_amount
    with_attr error_message("ProtossSwapRouter: IBA") {
        let (lt0) = uint256_lt(amountB, amountBMin);
        assert lt0 = FALSE;
    }

    return (amountA=amountA, amountB=amountB);
}

@external
func swapExactTokensForTokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amountIn : Uint256,
    amountOutMin : Uint256,
    path_len : felt,
    path : felt*,
    to : felt,
    deadline : felt,
) -> (amounts_len : felt, amounts : Uint256*) {
    alloc_locals;

    _ensure(deadline);

    let (factory) = _factory.read();
    let (pairClass) = _pairClass.read();
    let (caller) = get_caller_address();

    let (amounts_len, amounts : Uint256*) = ProtossLibrary.getAmountsOut(
        factory, pairClass, amountIn, path_len, path
    );

    // Insufficient output amount
    with_attr error_message("ProtossSwapRouter: IOA") {
        // amounts[amounts_len - 1] >= amountOutMin
        let (le) = uint256_le(amountOutMin, amounts[amounts_len - 1]);
        assert le = TRUE;
    }

    let (pair) = ProtossLibrary.pairFor(factory, pairClass, path[0], path[1]);

    // TODO. Not implemented safeTransferFrom
    IERC20.transferFrom(contract_address=path[0], sender=caller, recipient=pair, amount=amounts[0]);

    _swap(amounts_len, amounts, path_len, path, to);

    return (amounts_len=amounts_len, amounts=amounts);
}

@external
func swapTokensForExactTokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amountOut : Uint256,
    amountInMax : Uint256,
    path_len : felt,
    path : felt*,
    to : felt,
    deadline : felt,
) -> (amounts_len : felt, amounts : Uint256*) {
    alloc_locals;

    _ensure(deadline);

    let (factory) = _factory.read();
    let (pairClass) = _pairClass.read();
    let (caller) = get_caller_address();

    let (amounts_len, amounts : Uint256*) = ProtossLibrary.getAmountsIn(
        factory, pairClass, amountOut, path_len, path
    );

    // Excessive input amount
    with_attr error_message("ProtossSwapRouter: EIA") {
        // amounts[0] <= amountInMax
        let (le) = uint256_le(amounts[0], amountInMax);
        assert le = TRUE;
    }

    let (pair) = ProtossLibrary.pairFor(factory, pairClass, path[0], path[1]);

    // TODO. Not implemented safeTransferFrom
    IERC20.transferFrom(contract_address=path[0], sender=caller, recipient=pair, amount=amounts[0]);

    _swap(amounts_len, amounts, path_len, path, to);

    return (amounts_len=amounts_len, amounts=amounts);
}

@external
func swapExactTokensForTokensSupportingFeeOnTransferTokens{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(
    amountIn : Uint256,
    amountOutMin : Uint256,
    path_len : felt,
    path : felt*,
    to : felt,
    deadline : felt,
) {
    alloc_locals;

    _ensure(deadline);

    let (factory) = _factory.read();
    let (pairClass) = _pairClass.read();
    let (caller) = get_caller_address();

    let (pair) = ProtossLibrary.pairFor(factory, pairClass, path[0], path[1]);

    // TODO. Not implemented safeTransferFrom
    IERC20.transferFrom(contract_address=path[0], sender=caller, recipient=pair, amount=amountIn);

    let (balanceBefore : Uint256) = IERC20.balanceOf(
        contract_address=path[path_len - 1], account=to
    );
    _swapSupportingFeeOnTransferTokens(path_len, path, to);

    // Insufficient output amount
    with_attr error_message("ProtossSwapRouter: IOA") {
        let (balanceAfter : Uint256) = IERC20.balanceOf(
            contract_address=path[path_len - 1], account=to
        );
        let (balanceDiff) = SafeUint256.sub_le(balanceAfter, balanceBefore);
        let (r_le) = uint256_le(amountOutMin, balanceDiff);
        assert r_le = TRUE;
    }

    return ();
}

//
// Internal
//

func _ensure{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(deadline : felt) {
    alloc_locals;

    // Expired
    with_attr error_message("ProtossSwapRouter: E") {
        let (block_timestamp) = get_block_timestamp();
        let le = is_le_felt(block_timestamp, deadline);
        assert le = TRUE;
    }

    return ();
}

func _addLiquidity{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(
    tokenA : felt,
    tokenB : felt,
    amountADesired : Uint256,
    amountBDesired : Uint256,
    amountAMin : Uint256,
    amountBMin : Uint256,
) -> (amountA : Uint256, amountB : Uint256) {
    alloc_locals;

    let (factory) = _factory.read();
    let (pairClass) = _pairClass.read();

    let (pair) = IProtossFactory.getPair(contract_address=factory, tokenA=tokenA, tokenB=tokenB);
    if (pair == 0) {
        IProtossFactory.createPair(contract_address=factory, tokenA=tokenA, tokenB=tokenB);
    }

    let (reserveA, reserveB) = ProtossLibrary.getReserves(factory, pairClass, tokenA, tokenB);

    let rA_neq0 = is_not_zero(reserveA);
    let rB_neq0 = is_not_zero(reserveB);
    let (b0) = bitwise_and(1 - rA_neq0, 1 - rB_neq0);
    if (b0 == TRUE) {
        return (amountA=amountADesired, amountB=amountBDesired);
    } else {
        let (amountBOptimal) = ProtossLibrary.quote(amountADesired, reserveA, reserveB);
        let (le1) = uint256_le(amountBOptimal, amountBDesired);
        if (le1 == TRUE) {
            // Insufficient_b_amount
            with_attr error_message("ProtossSwapRouter: IBA") {
                let (lt2) = uint256_lt(amountBOptimal, amountBMin);
                assert lt2 = FALSE;
            }

            return (amountA=amountADesired, amountB=amountBOptimal);
        } else {
            let (amountAOptimal) = ProtossLibrary.quote(amountBDesired, reserveB, reserveA);

            let (le2) = uint256_le(amountAOptimal, amountADesired);
            assert le2 = TRUE;

            // Insufficient_a_amount
            with_attr error_message("ProtossSwapRouter: IAA") {
                let (lt2) = uint256_lt(amountAOptimal, amountAMin);
                assert lt2 = FALSE;
            }

            return (amountA=amountAOptimal, amountB=amountBDesired);
        }
    }
}

func _removeLiquidity{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenA : felt, tokenB : felt, liquidity : Uint256, to : felt
) -> (amountA : Uint256, amountB : Uint256) {
    alloc_locals;

    let (factory) = _factory.read();
    let (pairClass) = _pairClass.read();
    let (caller) = get_caller_address();

    let (pair) = ProtossLibrary.pairFor(factory, pairClass, tokenA, tokenB);

    // send liquidity to pair
    IProtossPair.transferFrom(contract_address=pair, sender=caller, recipient=pair, amount=liquidity);

    let (amount0 : Uint256, amount1 : Uint256) = IProtossPair.burn(contract_address=pair, to=to);

    let (token0, _) = ProtossLibrary.sortTokens(tokenA, tokenB);

    if (tokenA == token0) {
        return (amountA=amount0, amountB=amount1);
    } else {
        return (amountA=amount1, amountB=amount0);
    }
}

// requires the initial amount to have already been sent to the first pair
func _swap{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amounts_len : felt, amounts : Uint256*, path_len : felt, path : felt*, _to : felt
) {
    alloc_locals;

    let (factory) = _factory.read();
    let (pairClass) = _pairClass.read();

    // *** Start loop ***
    // Equal to: for (uint i; i < path_len - 1; i++);
    tempvar next = 1;
    tempvar i = 0;

    loop:
    tempvar input = path[i];
    tempvar output = path[i + 1];
    let (token0, _) = ProtossLibrary.sortTokens(input, output);
    tempvar amountOut = amounts[i + 1];

    let (amount0Out : Uint256, amount1Out : Uint256) = _swap_amountOuts(input, token0, amountOut);
    let (to) = _swap_to(factory, pairClass, i, path_len, path, output, _to);

    let (pair) = ProtossLibrary.pairFor(factory, pairClass, input, output);
    IProtossPair.swap(contract_address=pair, amount0Out=amount0Out, amount1Out=amount1Out, to=to);

    tempvar i = i + 1;
    tempvar next = path_len - 1 - i;

    jmp loop if next != 0;
    // *** End loop ***

    return ();
}

func _swap_amountOuts{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    input : felt, token0 : felt, amountOut : Uint256
) -> (amount0Out : Uint256, amount1Out : Uint256) {
    if (input == token0) {
        return (amount0Out=Uint256(0, 0), amount1Out=amountOut);
    } else {
        return (amount0Out=amountOut, amount1Out=Uint256(0, 0));
    }
}

func _swap_to{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    factory : felt,
    pairClass : felt,
    i : felt,
    path_len : felt,
    path : felt*,
    output : felt,
    _to : felt,
) -> (to : felt) {
    alloc_locals;

    let r_le = is_le_felt(path_len - 2, i);

    // If i < path.length - 2
    if (r_le == FALSE) {
        let (pair) = ProtossLibrary.pairFor(factory, pairClass, output, path[i + 2]);
        return (to=pair);
    } else {
        return (to=_to);
    }
}

// **** SWAP (supporting fee-on-transfer tokens) ****
// requires the initial amount to have already been sent to the first pair
// There is a vulnerability. danger level: low. https://www.btcfans.com/article/63438
func _swapSupportingFeeOnTransferTokens{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(path_len : felt, path : felt*, _to : felt) {
    alloc_locals;

    let (factory) = _factory.read();
    let (pairClass) = _pairClass.read();

    // *** Start loop ***
    // Equal to: for (uint i; i < path.length - 1; i++);
    tempvar next = 1;
    tempvar i = 0;

    loop:
    tempvar input = path[i];
    tempvar output = path[i + 1];
    let (token0, _) = ProtossLibrary.sortTokens(input, output);
    let (pair) = ProtossLibrary.pairFor(factory, pairClass, input, output);

    let (reserve0, reserve1, _) = IProtossPair.getReserves(contract_address=pair);
    let (reserveInput, reserveOutput) = _swapSupportingFeeOnTransferTokens_reserves(
        input, token0, reserve0, reserve1
    );

    let (balanceInput) = IERC20.balanceOf(contract_address=input, account=pair);
    let (amountInput) = SafeUint256.sub_le(balanceInput, Uint256(reserveInput, 0));
    let (amountOutput) = ProtossLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);

    let (amount0Out : Uint256, amount1Out : Uint256) = _swap_amountOuts(input, token0, amountOutput);
    let (to) = _swap_to(factory, pairClass, i, path_len, path, output, _to);

    let (pair) = ProtossLibrary.pairFor(factory, pairClass, input, output);
    IProtossPair.swap(contract_address=pair, amount0Out=amount0Out, amount1Out=amount1Out, to=to);

    tempvar i = i + 1;
    tempvar next = path_len - 1 - i;

    jmp loop if next != 0;
    // *** End loop ***

    return ();
}

func _swapSupportingFeeOnTransferTokens_reserves{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(input : felt, token0 : felt, reserve0 : felt, reserve1 : felt) -> (
    reserveInput : felt, reserveOutput : felt
) {
    if (input == token0) {
        return (reserveInput=reserve0, reserveOutput=reserve1);
    } else {
        return (reserveInput=reserve1, reserveOutput=reserve0);
    }
}
