%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_check,
    uint256_sqrt,
    uint256_le,
    uint256_lt,
    uint256_eq,
)
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.math import assert_nn, assert_not_equal, assert_not_zero
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)

from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.token.erc20.library import ERC20, ERC20_total_supply, ERC20_balances, Transfer
from openzeppelin.token.erc20.IERC20 import IERC20

from warplib.maths.div import warp_div256
from warplib.maths.mod import warp_mod
from warplib.maths.gt import warp_gt
from warplib.maths.neq import warp_neq
from warplib.maths.add import warp_add256
from warplib.maths.int_conversions import warp_int256_to_int112, warp_int128_to_int32, warp_uint256

from libraries.protoss_library import min_uint256
from libraries.uq112x112 import Q112, encode, uqdiv
from interfaces.ProtossFactory import IProtossFactory

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt) {
    let (name) = ERC20.name();
    return (name=name);
}

@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt) {
    let (symbol) = ERC20.symbol();
    return (symbol=symbol);
}

@view
func totalSupply{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    totalSupply : Uint256
) {
    let (totalSupply) = ERC20.total_supply();
    return (totalSupply=totalSupply);
}

@view
func decimals{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    decimals : felt
) {
    let (decimals) = ERC20.decimals();
    return (decimals=decimals);
}

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    account : felt
) -> (balance : Uint256) {
    let (balance) = ERC20.balance_of(account);
    return (balance=balance);
}

@view
func allowance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, spender : felt
) -> (remaining : Uint256) {
    let (remaining) = ERC20.allowance(owner, spender);
    return (remaining=remaining);
}

@external
func transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    recipient : felt, amount : Uint256
) -> (success : felt) {
    ERC20.transfer(recipient, amount);
    return (success=TRUE);
}

@external
func transferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    sender : felt, recipient : felt, amount : Uint256
) -> (success : felt) {
    ERC20.transfer_from(sender, recipient, amount);
    return (success=TRUE);
}

@external
func approve{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    spender : felt, amount : Uint256
) -> (success : felt) {
    ERC20.approve(spender, amount);
    return (success=TRUE);
}

@external
func increaseAllowance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    spender : felt, added_value : Uint256
) -> (success : felt) {
    ERC20.increase_allowance(spender, added_value);
    return (success=TRUE);
}

@external
func decreaseAllowance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    spender : felt, subtracted_value : Uint256
) -> (success : felt) {
    ERC20.decrease_allowance(spender, subtracted_value);
    return (success=TRUE);
}

//
// ERC20 === end ===
//

//
// Pair === start ===
//

//
// Constants
//

// Cairo supports defining constant expressions (only integers(felt));
// https://www.cairo-lang.org/docs/how_cairo_works/consts.html
const _MINIMUM_LIQUIDITY = 10 ** 3;

//
// Events
//

@event
func Mint(sender : felt, amount0 : Uint256, amount1 : Uint256) {
}

@event
func Burn(sender : felt, amount0 : Uint256, amount1 : Uint256, to : felt) {
}

@event
func Swap(
    sender : felt,
    amount0In : Uint256,
    amount1In : Uint256,
    amount0Out : Uint256,
    amount1Out : Uint256,
    to : felt,
) {
}

@event
func Sync(reserve0 : felt, reserve1 : felt) {
}

//
// Storage
//

@storage_var
func _factory() -> (factory : felt) {
}

@storage_var
func _token0() -> (token0 : felt) {
}

@storage_var
func _token1() -> (token1 : felt) {
}

// Type: uint112
@storage_var
func _reserve0() -> (reserve0 : felt) {
}

@storage_var
func _reserve1() -> (reserve1 : felt) {
}

@storage_var
func _blockTimestampLast() -> (blockTimestampLast : felt) {
}

@storage_var
func _price0CumulativeLast() -> (price0CumulativeLast : Uint256) {
}

@storage_var
func _price1CumulativeLast() -> (price1CumulativeLast : Uint256) {
}

// reserve0 * reserve1, as of immediately after the most recent liquidity event
@storage_var
func _kLast() -> (kLast : Uint256) {
}

//
// Constructor
//

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
    let (sender) = get_caller_address();
    _factory.write(sender);
    return ();
}

//
// Getters
//

@view
func MINIMUM_LIQUIDITY{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    MINIMUM_LIQUIDITY : felt
) {
    return (MINIMUM_LIQUIDITY=_MINIMUM_LIQUIDITY);
}

@view
func factory{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    factory : felt
) {
    let (value) = _factory.read();
    return (factory=value);
}

@view
func token0{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (token0 : felt) {
    let (value) = _token0.read();
    return (token0=value);
}

@view
func token1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (token1 : felt) {
    let (value) = _token1.read();
    return (token1=value);
}

@view
func blockTimestampLast{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    blockTimestampLast : felt
) {
    let (value) = _blockTimestampLast.read();
    return (blockTimestampLast=value);
}

@view
func price0CumulativeLast{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    price0CumulativeLast : Uint256
) {
    let (value) = _price0CumulativeLast.read();
    return (price0CumulativeLast=value);
}

@view
func price1CumulativeLast{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    price1CumulativeLast : Uint256
) {
    let (value) = _price1CumulativeLast.read();
    return (price1CumulativeLast=value);
}

@view
func kLast{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    kLast : Uint256
) {
    let (value) = _kLast.read();
    return (kLast=value);
}

@view
func getReserves{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    reserve0 : felt, reserve1 : felt, blockTimestampLast : felt
) {
    let (reserve0) = _reserve0.read();
    let (reserve1) = _reserve1.read();
    let (blockTimestampLast) = _blockTimestampLast.read();

    return (reserve0=reserve0, reserve1=reserve1, blockTimestampLast=blockTimestampLast);
}

//
// Externals
//

// called once by the factory at time of deployment
@external
func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token0 : felt, token1 : felt
) -> () {
    let (factory) = _factory.read();
    let (sender) = get_caller_address();
    with_attr error_message("ProtossSwap: FB") {
        assert factory = sender;
    }

    _token0.write(token0);
    _token1.write(token1);

    ERC20.initializer('ProtossSwap Pair Token', 'LPT', 18);

    return ();
}

// this low-level function should be called from a contract which performs important safety checks
@external
func mint{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(to : felt) -> (liquidity : Uint256) {
    alloc_locals;

    ReentrancyGuard.start();

    let (reserve0, reserve1, _) = getReserves();
    let (token0) = _token0.read();
    let (token1) = _token1.read();
    let (self) = get_contract_address();
    let (balance0 : Uint256) = IERC20.balanceOf(contract_address=token0, account=self);
    let (balance1 : Uint256) = IERC20.balanceOf(contract_address=token1, account=self);
    let (amount0) = SafeUint256.sub_le(balance0, Uint256(reserve0, 0));
    let (amount1) = SafeUint256.sub_le(balance1, Uint256(reserve1, 0));

    let (feeOn) = _mintFee(reserve0, reserve1);
    let (totalSupply : Uint256) = ERC20.total_supply();

    let (zero_total_supply) = uint256_eq(totalSupply, Uint256(0, 0));
    if (zero_total_supply == TRUE) {
        let (m0 : Uint256) = SafeUint256.mul(amount0, amount1);
        let (sq : Uint256) = uint256_sqrt(m0);
        let (_liquidity : Uint256) = SafeUint256.sub_le(sq, Uint256(_MINIMUM_LIQUIDITY, 0));

        // permanently lock the first _MINIMUM_LIQUIDITY tokens
        _mint(0, Uint256(_MINIMUM_LIQUIDITY, 0));

        _mint_part1(feeOn, to, amount0, amount1, _liquidity, balance0, balance1, reserve0, reserve1);

        ReentrancyGuard.end();
        return (liquidity=_liquidity);
    } else {
        // a = amount0 * totalSupply / reserve0
        // b = amount1 * totalSupply / reserve1
        // liquidity = min(a, b);
        let (a_lhs : Uint256) = SafeUint256.mul(amount0, totalSupply);
        let (a : Uint256) = warp_div256(a_lhs, Uint256(reserve0, 0));
        let (b_lhs : Uint256) = SafeUint256.mul(amount1, totalSupply);
        let (b : Uint256) = warp_div256(b_lhs, Uint256(reserve1, 0));
        let (_liquidity : Uint256) = min_uint256(a, b);

        _mint_part1(feeOn, to, amount0, amount1, _liquidity, balance0, balance1, reserve0, reserve1);

        ReentrancyGuard.end();
        return (liquidity=_liquidity);
    }
}

// this low-level function should be called from a contract which performs important safety checks
@external
func burn{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(to : felt) -> (amount0 : Uint256, amount1 : Uint256) {
    alloc_locals;

    ReentrancyGuard.start();

    let (reserve0, reserve1, _) = getReserves();
    let (token0) = _token0.read();
    let (token1) = _token1.read();
    let (self) = get_contract_address();
    let (balance0 : Uint256) = IERC20.balanceOf(contract_address=token0, account=self);
    let (balance1 : Uint256) = IERC20.balanceOf(contract_address=token1, account=self);
    let (liquidity : Uint256) = ERC20.balance_of(account=self);

    let (feeOn) = _mintFee(reserve0, reserve1);
    let (totalSupply : Uint256) = ERC20.total_supply();

    // using balances ensures pro-rata distribution
    let (a0) = SafeUint256.mul(liquidity, balance0);
    let (amount0) = warp_div256(a0, totalSupply);
    let (a1) = SafeUint256.mul(liquidity, balance1);
    let (amount1) = warp_div256(a1, totalSupply);

    // Insufficient liquidity burned
    with_attr error_message("ProtossSwap: ILB") {
        let (r0) = uint256_le(amount0, Uint256(0, 0));
        let (r1) = uint256_le(amount1, Uint256(0, 0));
        assert r0 = FALSE;
        assert r1 = FALSE;
    }

    _burn(self, liquidity);
    IERC20.transfer(contract_address=token0, recipient=to, amount=amount0);
    IERC20.transfer(contract_address=token1, recipient=to, amount=amount1);
    let (balance0 : Uint256) = IERC20.balanceOf(contract_address=token0, account=self);
    let (balance1 : Uint256) = IERC20.balanceOf(contract_address=token1, account=self);
    _update(balance0, balance1, reserve0, reserve1);

    _kLast_update(feeOn);

    let (sender) = get_caller_address();
    Burn.emit(sender, amount0, amount1, to);

    ReentrancyGuard.end();

    return (amount0=amount0, amount1=amount1);
}

// this low-level function should be called from a contract which performs important safety checks
@external
func swap{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(amount0Out : Uint256, amount1Out : Uint256, to : felt) -> () {
    alloc_locals;

    ReentrancyGuard.start();

    // Insufficient output amount
    with_attr error_message("ProtossSwap: IOA") {
        // Require amount0Out > 0 || amount1Out > 0
        let (r0) = uint256_le(amount0Out, Uint256(0, 0));
        let (r1) = uint256_le(amount1Out, Uint256(0, 0));
        assert r0 * r1 = FALSE;
    }

    let (reserve0, reserve1, _) = getReserves();

    // Insufficient liquidity
    with_attr error_message("ProtossSwap: IL") {
        let (r0) = uint256_lt(amount0Out, Uint256(reserve0, 0));
        let (r1) = uint256_lt(amount1Out, Uint256(reserve1, 0));
        assert r0 * r1 = TRUE;
    }

    let (token0) = _token0.read();
    let (token1) = _token1.read();

    // Invalid to
    with_attr error_message("ProtossSwap: IT") {
        if (to == token0) {
            assert 1 = 0;
        }
        if (to == token1) {
            assert 1 = 0;
        }
    }

    // TODO. Not implemented safeTransfer
    _swap_Transfer(token0, to, amount0Out);
    _swap_Transfer(token1, to, amount1Out);

    let (self) = get_contract_address();
    let (balance0 : Uint256) = IERC20.balanceOf(contract_address=token0, account=self);
    let (balance1 : Uint256) = IERC20.balanceOf(contract_address=token1, account=self);

    // Amount in
    let (amount0In : Uint256) = _swap_get_amountIn(balance0, reserve0, amount0Out);
    let (amount1In : Uint256) = _swap_get_amountIn(balance1, reserve1, amount1Out);

    // Insufficient input amount
    with_attr error_message("ProtossSwap: IIA") {
        // Require amount0In > 0 || amount1In > 0
        let (r0) = uint256_le(amount0In, Uint256(0, 0));
        let (r1) = uint256_le(amount1In, Uint256(0, 0));
        assert r0 * r1 = FALSE;
    }

    with_attr error_message("ProtossSwap: K") {
        let (b0 : Uint256) = SafeUint256.mul(balance0, Uint256(1000, 0));
        let (a0 : Uint256) = SafeUint256.mul(amount0In, Uint256(3, 0));
        let (balance0Adjusted : Uint256) = SafeUint256.sub_le(b0, a0);

        let (b1 : Uint256) = SafeUint256.mul(balance1, Uint256(1000, 0));
        let (a1 : Uint256) = SafeUint256.mul(amount1In, Uint256(3, 0));
        let (balance1Adjusted : Uint256) = SafeUint256.sub_le(b1, a1);

        let (m0) = SafeUint256.mul(balance0Adjusted, balance1Adjusted);
        let (m1_0) = SafeUint256.mul(Uint256(reserve0, 0), Uint256(reserve1, 0));
        let (m1) = SafeUint256.mul(m1_0, Uint256(1000 ** 2, 0));

        let (is_lt) = uint256_lt(m0, m1);

        assert is_lt = FALSE;
    }

    _update(balance0, balance1, reserve0, reserve1);

    let (sender) = get_caller_address();
    Swap.emit(sender, amount0In, amount1In, amount0Out, amount1Out, to);

    ReentrancyGuard.end();

    return ();
}

// force balances to match reserves
@external
func skim{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(to : felt) -> () {
    alloc_locals;

    ReentrancyGuard.start();

    let (token0) = _token0.read();
    let (token1) = _token1.read();
    let (self) = get_contract_address();
    let (balance0 : Uint256) = IERC20.balanceOf(contract_address=token0, account=self);
    let (balance1 : Uint256) = IERC20.balanceOf(contract_address=token1, account=self);
    let (reserve0) = _reserve0.read();
    let (reserve1) = _reserve1.read();

    // Todo: To be implemented safeTransfer
    let (diff0) = SafeUint256.sub_le(balance0, Uint256(reserve0, 0));
    let (diff1) = SafeUint256.sub_le(balance1, Uint256(reserve1, 0));
    IERC20.transfer(contract_address=token0, recipient=to, amount=diff0);
    IERC20.transfer(contract_address=token1, recipient=to, amount=diff1);

    ReentrancyGuard.end();

    return ();
}

// force reserves to match balances
@external
func sync{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}() -> () {
    alloc_locals;

    ReentrancyGuard.start();

    let (token0) = _token0.read();
    let (token1) = _token1.read();
    let (self) = get_contract_address();
    let (balance0 : Uint256) = IERC20.balanceOf(contract_address=token0, account=self);
    let (balance1 : Uint256) = IERC20.balanceOf(contract_address=token1, account=self);
    let (reserve0) = _reserve0.read();
    let (reserve1) = _reserve1.read();

    _update(balance0, balance1, reserve0, reserve1);

    ReentrancyGuard.end();

    return ();
}

//
// Internal
//

func _mint_part1{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(
    feeOn : felt,
    to : felt,
    amount0 : Uint256,
    amount1 : Uint256,
    liquidity : Uint256,
    balance0 : Uint256,
    balance1 : Uint256,
    reserve0 : felt,
    reserve1 : felt,
) {
    // Insufficient liquidity minted
    with_attr error_message("ProtossSwap: ILM") {
        let (is_le) = uint256_le(liquidity, Uint256(0, 0));
        assert is_le = FALSE;
    }

    _mint(to, liquidity);

    _update(balance0, balance1, reserve0, reserve1);

    _kLast_update(feeOn);

    let (sender) = get_caller_address();
    Mint.emit(sender, amount0, amount1);

    return ();
}

func _update{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(balance0 : Uint256, balance1 : Uint256, reserve0 : felt, reserve1 : felt) {
    alloc_locals;

    // Overflow
    with_attr error_message("ProtossSwap: OV") {
        let (is_le_0) = uint256_le(balance0, Uint256(Q112 - 1, 0));
        let (is_le_1) = uint256_le(balance1, Uint256(Q112 - 1, 0));
        assert (is_le_0, is_le_1) = (TRUE, TRUE);
    }

    let (blockTimestampLast) = _blockTimestampLast.read();
    let (price0CumulativeLast : Uint256) = _price0CumulativeLast.read();
    let (price1CumulativeLast : Uint256) = _price1CumulativeLast.read();

    let (block_timestamp) = get_block_timestamp();
    let (bt_r) = warp_mod(block_timestamp, 2 ** 32);
    let (block_timestamp) = warp_int128_to_int32(bt_r);

    // overflow is desired
    let timeElapsed = block_timestamp - blockTimestampLast;

    let (if0) = warp_gt(timeElapsed, 0);
    let (if1) = warp_neq(reserve0, 0);
    let (if2) = warp_neq(reserve1, 0);
    if (if0 * if1 * if2 == TRUE) {
        let (e0) = encode(reserve0);
        let (e1) = encode(reserve1);
        let (u0) = uqdiv(e1, reserve0);
        let (u1) = uqdiv(e0, reserve1);

        // uint224 to uint256
        let (u0_256) = warp_uint256(u0);
        let (u1_256) = warp_uint256(u1);

        // * never overflows, and + overflow is desired
        // _price0CumulativeLast = _price0CumulativeLast + u0 * timeElapsed
        let (p0 : Uint256) = SafeUint256.mul(u0_256, Uint256(timeElapsed, 0));
        let (p1 : Uint256) = SafeUint256.mul(u1_256, Uint256(timeElapsed, 0));
        let (p0CumulativeLast : Uint256) = warp_add256(p0, price0CumulativeLast);
        let (p1CumulativeLast : Uint256) = warp_add256(p1, price1CumulativeLast);
        _price0CumulativeLast.write(p0CumulativeLast);
        _price1CumulativeLast.write(p1CumulativeLast);

        // if condition will revoked implicit arguments
        // https://www.cairo-lang.org/docs/how_cairo_works/builtins.html?highlight=revoke%20reference#revoked-implicit-arguments
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    }

    // Stroage
    let (r0) = warp_int256_to_int112(balance0);
    _reserve0.write(r0);
    let (r1) = warp_int256_to_int112(balance1);
    _reserve1.write(r1);
    _blockTimestampLast.write(block_timestamp);

    Sync.emit(r0, r1);

    return ();
}

// if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k);
func _mintFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    reserve0 : felt, reserve1 : felt
) -> (feeOn : felt) {
    alloc_locals;

    let (factory) = _factory.read();
    let (kLast : Uint256) = _kLast.read();
    let (feeTo) = IProtossFactory.feeTo(contract_address=factory);

    let notFeeOn = is_le_felt(feeTo, 0);
    let feeOn = 1 - notFeeOn;
    let (zeroKLast) = uint256_eq(kLast, Uint256(0, 0));

    if (feeOn == TRUE) {
        if (zeroKLast == FALSE) {
            let (m0 : Uint256) = SafeUint256.mul(Uint256(reserve0, 0), Uint256(reserve1, 0));
            let (rootK : Uint256) = uint256_sqrt(m0);
            let (rootKLast : Uint256) = uint256_sqrt(kLast);

            let (is_le) = uint256_le(rootK, rootKLast);
            if (is_le == FALSE) {
                let (totalSupply : Uint256) = ERC20.total_supply();
                let (s1 : Uint256) = SafeUint256.sub_le(rootK, rootKLast);
                let (numerator : Uint256) = SafeUint256.mul(totalSupply, s1);

                let (m1 : Uint256) = SafeUint256.mul(rootK, Uint256(5, 0));
                let (denominator : Uint256) = SafeUint256.add(m1, rootKLast);

                let (liquidity : Uint256) = warp_div256(numerator, denominator);
                let (liquidity_le_zero) = uint256_le(liquidity, Uint256(0, 0));
                if (liquidity_le_zero == FALSE) {
                    _mint(feeTo, liquidity);

                    return (feeOn=feeOn);
                }

                return (feeOn=feeOn);
            }

            return (feeOn=feeOn);
        }

        return (feeOn=feeOn);
    } else {
        if (zeroKLast == FALSE) {
            _kLast.write(Uint256(0, 0));

            return (feeOn=feeOn);
        }

        return (feeOn=feeOn);
    }
}

func _mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    recipient : felt, amount : Uint256
) {
    with_attr error_message("ERC20: amount is not a valid Uint256") {
        uint256_check(amount);
    }

    // Remove zero address check
    // with_attr error_message("ERC20: cannot mint to the zero address") {
    //     assert_not_zero(recipient);
    // }

    let (supply : Uint256) = ERC20_total_supply.read();
    with_attr error_message("ERC20: mint overflow") {
        let (new_supply : Uint256) = SafeUint256.add(supply, amount);
    }
    ERC20_total_supply.write(new_supply);

    let (balance : Uint256) = ERC20_balances.read(account=recipient);
    // overflow is not possible because sum is guaranteed to be less than total supply
    // which we check for overflow below
    let (new_balance : Uint256) = SafeUint256.add(balance, amount);
    ERC20_balances.write(recipient, new_balance);

    Transfer.emit(0, recipient, amount);
    return ();
}

func _burn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    account : felt, amount : Uint256
) {
    with_attr error_message("ERC20: amount is not a valid Uint256") {
        uint256_check(amount);
    }

    // Remove zero address check
    // with_attr error_message("ERC20: cannot burn from the zero address") {
    //     assert_not_zero(account);
    // }

    let (balance : Uint256) = ERC20_balances.read(account);
    with_attr error_message("ERC20: burn amount exceeds balance") {
        let (new_balance : Uint256) = SafeUint256.sub_le(balance, amount);
    }

    ERC20_balances.write(account, new_balance);

    let (supply : Uint256) = ERC20_total_supply.read();
    let (new_supply : Uint256) = SafeUint256.sub_le(supply, amount);
    ERC20_total_supply.write(new_supply);
    Transfer.emit(account, 0, amount);
    return ();
}

func _kLast_update{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(feeOn : felt) -> () {
    alloc_locals;

    if (feeOn == TRUE) {
        // _reserve0 and _reserve1 are up-to-date
        let (reserve0) = _reserve0.read();
        let (reserve1) = _reserve1.read();
        let (r0xr1) = SafeUint256.mul(Uint256(reserve0, 0), Uint256(reserve1, 0));
        _kLast.write(r0xr1);

        return ();
    } else {
        return ();
    }
}

func _swap_Transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token : felt, recipient : felt, amountOut : Uint256
) -> () {
    let (is_le) = uint256_le(amountOut, Uint256(0, 0));
    if (is_le == TRUE) {
        return ();
    }

    IERC20.transfer(contract_address=token, recipient=recipient, amount=amountOut);

    return ();
}

func _swap_get_amountIn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    balance : Uint256, reserve : felt, amountOut : Uint256
) -> (amountIn : Uint256) {
    alloc_locals;

    // amountIn = balance <= reserve - amountOut ? 0 : balance - (reserve - amountOut);
    let (a) = SafeUint256.sub_le(Uint256(reserve, 0), amountOut);
    let (is_le) = uint256_le(balance, a);
    if (is_le == FALSE) {
        let (_amountIn) = SafeUint256.sub_le(balance, a);
        return (amountIn=_amountIn);
    }

    return (amountIn=Uint256(0, 0));
}

//
// Pair === end ===
//
