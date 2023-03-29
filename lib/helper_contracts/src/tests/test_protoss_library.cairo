%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_check,
    uint256_sub,
    uint256_eq,
    uint256_sqrt,
    uint256_le,
    uint256_lt,
)

from openzeppelin.security.safemath.library import SafeUint256

from libraries.protoss_library import ProtossLibrary

@view
func test_pairFor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    factory : felt, pairClass : felt, tokenA : felt, tokenB : felt
) -> (res : felt) {
    let (pair) = ProtossLibrary.pairFor(factory, pairClass, tokenA, tokenB);

    return (res=pair);
}

@view
func test_quote{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amountA : Uint256, reserveA : felt, reserveB : felt
) -> (amountB : Uint256) {
    let (amountB) = ProtossLibrary.quote(amountA, reserveA, reserveB);

    return (amountB=amountB);
}
