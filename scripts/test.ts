import { number, Contract, Account, ec, Provider, SequencerProvider, stark, uint256 } from "starknet";
import * as dotenv from 'dotenv'
dotenv.config()

// Account
const accountAddress = "0x076b885Ca6e863346774BEaF32f8752db6af9eEBEc2A9CB0D321725Cad6c197e";
const privateKey = process.env.PROTOSTAR_ACCOUNT_PRIVATE_KEY || "";
const starkKeyPair = ec.getKeyPair(privateKey);

// ERC20
const tokenAAddress = "0x58e4cf84d5c9d7c6e5f3fdd4d2d7186566f39fa67bdd1f24f91c41b4c095fcb";
const tokenBAddress = "0x401d06bd0e3e0d2cca6eead7bb20ec5d6ad4f48a27b2ce00e416f89cbd5d011";
const tokenCAddress = "0x6f5a85cfdadca8a90f7b99c99afd992a149e853a641257db99cf50bc2093ed7";
const tokenDAddress = "0x55ce6e2c9f7e962ceddce755ac5dbed6415d206d5435631557d1d75c44d3149";

// ProtossFactory
const factoryAddress = "0x678950106a6e2d23ed2f38b3b645ea48e994a9d009c9aa7f8ef3f8b6434fb5e";

// ProtossRouter
const routerAddress = "0x064ee214c54f4e3e43fcca70cb518f6eca85a29548a3eaa2da67fe9ac4a866e4";


// const provider = new Provider({ sequencer: { network: 'goerli-alpha' } });
const provider = new Provider({
  rpc: {
    nodeUrl: 'https://starknet-goerli.infura.io/v3/f33802aa97504278bf8ac3f6e85e3b7b',
  },
})

const getContract = async (addr: string) => {
    const { abi: abi } = await provider.getClassAt(addr);
    if (abi === undefined) { throw new Error("no abi.") };

    return new Contract(abi, addr, provider);
}

const getAccount = () => {
    const account = new Account(provider, accountAddress, starkKeyPair);
    return account;
}

// Solution 2 for mint
// const executeHash = await account.execute({
//   contractAddress: tokenAAddress,
//   entrypoint: "mint",
//   calldata: [
//     accountAddress,
//     '500000000000000000000',
//     '0'
//   ]
// }, undefined, { maxFee: 900_000_000_000_000_000 });
// console.log("tx hash: ", executeHash.transaction_hash);
// await provider.waitForTransaction(executeHash.transaction_hash);
//
// Interaction with the contract with call
const mintToken = async (tokenAddress: string, amount: string) => {
    const erc20 = await getContract(tokenAddress);

    // connect account
    const account = getAccount();
    erc20.connect(account);
    const balance = await erc20.balanceOf(account.address);
    console.log("Initial balance =", balance[0]);

    let res = await account.estimateInvokeFee({
      contractAddress: tokenAAddress,
      entrypoint: "mint",
      calldata: [
        accountAddress,
        amount,
        '0'
      ]
    });

    // Solution 1 for mint
    const amountToMint = uint256.bnToUint256(amount);
    const { transaction_hash: mintTxHash } = await erc20.mint(account.address, amountToMint, { maxFee: res.suggestedMaxFee });
    showTxStatus(mintTxHash);
}

const createPair = async (tokenA: string, tokenB: string) => {
    const factory = await getContract(factoryAddress);
    const router = await getContract(routerAddress);

    // connect account
    const account = getAccount();
    factory.connect(account);
    router.connect(account);

    let res = await account.estimateInvokeFee({
      contractAddress: factoryAddress,
      entrypoint: "createPair",
      calldata: [
        tokenA,
        tokenB,
        Math.floor((new Date().getTime() + 10000) / 1000),
      ]
    });

    // create pair
    const { transaction_hash: createPairTxHash } = await factory.createPair(tokenA, tokenB, { maxFee: res.suggestedMaxFee } );
    showTxStatus(createPairTxHash);

    // get pair address
    const pairAddress = await factory.getPair(tokenA, tokenB);
    console.log("Pair address =", pairAddress);
}

// //// Solution 1 add liquidity
// const { transaction_hash: addLiquidityTxHash } = await router.addLiquidity(
//   tokenA,
//   tokenB,
//   [1000000000, 0],
//   [1000000000, 0],
//   [0, 0],
//   [0, 0],
//   account.address,
//   Math.floor((new Date().getTime() + 100000) / 1000)
// );
// showTxStatus(addLiquidityTxHash);
//
const addLiquidity = async (tokenA: string, tokenB: string, amount: string) => {
    const router = await getContract(routerAddress);
    const account = getAccount();
    router.connect(account);

    // check if user has enough balance

    let res = await account.estimateInvokeFee({
      contractAddress: routerAddress,
      entrypoint: "addLiquidity",
      calldata: [
        tokenA,
        tokenB,
        amount, 0, // amountA
        amount, 0, // amountB
        0, 0, // amountAMin
        0, 0, // amountBMin
        account.address,
        Math.floor((new Date().getTime() + 10000) / 1000),
      ]
    });

    const executeHash = await account.execute({
      contractAddress: routerAddress,
      entrypoint: "addLiquidity",
      calldata: [
        tokenA,
        tokenB,
        amount, '0',
        amount, '0',
        '0', '0',
        '0', '0',
        account.address,
        Math.floor((new Date().getTime() + 100000) / 1000),
      ]
    }, undefined, { maxFee: res.suggestedMaxFee });
    showTxStatus(executeHash.transaction_hash);
}

const approve = async (tokenAddress: string, spender: string, amount: string) => {
    const erc20 = await getContract(tokenAddress);
    const account = getAccount();
    erc20.connect(account);

    let res = await account.estimateInvokeFee({
      contractAddress: tokenAddress,
      entrypoint: "approve",
      calldata: [
        spender,
        amount,
        '0'
      ]
    });

    const executeHash = await account.execute({
      contractAddress: tokenAddress,
      entrypoint: "approve",
      calldata: [
        spender,
        amount,
        '0'
      ]
    }, undefined, { maxFee: res.suggestedMaxFee });
    showTxStatus(executeHash.transaction_hash);
}

const removeLiquidity = async (tokenA: string, tokenB: string, amount: string) => {
    const router = await getContract(routerAddress);
    const account = getAccount();
    router.connect(account);

    let res = await account.estimateInvokeFee({
      contractAddress: routerAddress,
      entrypoint: "removeLiquidity",
      calldata: [
        tokenA,
        tokenB,
        amount, 0, // liquidity
        0, 0, // amountAMin
        0, 0, // amountBMin
        account.address,
        Math.floor((new Date().getTime() + 10000) / 1000),
      ]
    });

    const executeHash = await account.execute({
      contractAddress: routerAddress,
      entrypoint: "removeLiquidity",
      calldata: [
        tokenA,
        tokenB,
        amount, 0, // liquidity
        0, 0, // amountAMin
        0, 0, // amountBMin
        account.address,
        Math.floor((new Date().getTime() + 10000) / 1000),
      ]
    }, undefined, { maxFee: res.suggestedMaxFee });
    showTxStatus(executeHash.transaction_hash);
}

const approveLiquidityAllowance = async (tokenA: string, tokenB: string, amount: string) => {
    const router = await getContract(routerAddress);
    const account = getAccount();
    router.connect(account);

    let res = await account.estimateInvokeFee({
      contractAddress: routerAddress,
      entrypoint: "approveLiquidityAllowance",
      calldata: [
        tokenA,
        tokenB,
        amount,
      ]
    });

    const executeHash = await account.execute({
      contractAddress: routerAddress,
      entrypoint: "approveLiquidityAllowance",
      calldata: [
        tokenA,
        tokenB,
        amount,
      ]
    }, undefined, { maxFee: res.suggestedMaxFee });
    showTxStatus(executeHash.transaction_hash);
}

const getPairContractAddress = async (tokenA: string, tokenB: string) => {
    const factory = await getContract(factoryAddress);
    const account = getAccount();
    factory.connect(account);

    const pairAddress = await factory.getPair(tokenA, tokenB);
    console.log("Pair address =", pairAddress[0].toString());
}

// show transaction status with a link to https://testnet.starknet.io/tx/{tx_hash}
const showTxStatus = (txHash: string) => {
    console.log(`https://testnet.starkscan.co/tx/${txHash}`);
}

//// Testing Call code
// mintToken(tokenAAddress, '1000000000000000000000000');
// mintToken(tokenBAddress, '1000000000000000000000000');
// mintToken(tokenCAddress, '1000000000000000000000000');
// mintToken(tokenDAddress, '1000000000000000000000000');

// createPair(tokenAAddress, tokenDAddress);
// createPair(tokenBAddress, tokenDAddress);
// createPair(tokenCAddress, tokenDAddress);

// approve(tokenAAddress, routerAddress, uint256.UINT_128_MAX.toString());
// approve(tokenBAddress, routerAddress, uint256.UINT_128_MAX.toString());
// approve(tokenCAddress, routerAddress, uint256.UINT_128_MAX.toString());
// approve(tokenDAddress, routerAddress, uint256.UINT_128_MAX.toString());

// addLiquidity(tokenAAddress, tokenBAddress, '50000000000000000000000');
// addLiquidity(tokenAAddress, tokenCAddress, '50000000000000000000000');
// addLiquidity(tokenAAddress, tokenDAddress, '50000000000000000000000');
// addLiquidity(tokenBAddress, tokenCAddress, '50000000000000000000000');
// addLiquidity(tokenBAddress, tokenDAddress, '50000000000000000000000');
// addLiquidity(tokenCAddress, tokenDAddress, '50000000000000000000000');

// getPairContractAddress(tokenAAddress, tokenBAddress);
// getPairContractAddress(tokenAAddress, tokenCAddress);
// getPairContractAddress(tokenAAddress, tokenDAddress);
// getPairContractAddress(tokenBAddress, tokenCAddress);
// getPairContractAddress(tokenBAddress, tokenDAddress);
// getPairContractAddress(tokenCAddress, tokenDAddress);

// approveLiquidityAllowance(tokenAAddress, tokenDAddress, '1000000_000000000000000000');
// const TokenATokenDPair = "0x12028a058439d05115ef58d0885cf8d6a3223b5514ee60d3c87716dab5dab0c"
// approve(TokenATokenDPair, routerAddress, '1000000_000000000000000000')
// removeLiquidity(tokenAAddress, tokenDAddress, '1000000_000000000000000000');
