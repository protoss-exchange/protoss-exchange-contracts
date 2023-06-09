from starkware.cairo.common.uint256 import Uint256, uint256_eq

func warp_neq(lhs : felt, rhs : felt) -> (res : felt) {
    if (lhs == rhs) {
        return (res=0);
    } else {
        return (res=1);
    }
}

func warp_neq256{range_check_ptr}(lhs : Uint256, rhs : Uint256) -> (res : felt) {
    let (res : felt) = uint256_eq(lhs, rhs);
    return (res=1 - res);
}
