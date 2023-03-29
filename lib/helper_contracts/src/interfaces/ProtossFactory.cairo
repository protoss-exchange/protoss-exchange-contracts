%lang starknet

@contract_interface
namespace IProtossFactory {
    func feeTo() -> (feeTo : felt) {
    }

    func feeToSetter() -> (feeToSetter : felt) {
    }

    func getPair(tokenA : felt, tokenB : felt) -> (pair : felt) {
    }

    func allPairs(index : felt) -> (pair : felt) {
    }

    func allPairsLength() -> (length : felt) {
    }

    func createPair(tokenA : felt, tokenB : felt) -> (pair : felt) {
    }

    func setFeeTo(feeTo : felt) -> () {
    }

    func setFeeToSetter(feeToSetter : felt) -> () {
    }
}
