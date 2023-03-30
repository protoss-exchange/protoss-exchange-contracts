# Deploy script

## Deploy pair
```
protostar deploy 0xce61e906700ba8fceb3a7b294dc4369b210807bad75273e59aef856e383b62 \
  --account-address 0x076b885Ca6e863346774BEaF32f8752db6af9eEBEc2A9CB0D321725Cad6c197e \
  --max-fee auto --network testnet
```


## Deploy factory
```
protostar deploy 0x58762fdf0d0418309c7d2f734a71b54a98a2589c6ec5dc3d393261718e65541 \
  --account-address 0x076b885Ca6e863346774BEaF32f8752db6af9eEBEc2A9CB0D321725Cad6c197e \
  --max-fee auto --network testnet \
  --inputs \
    pairClass=0xce61e906700ba8fceb3a7b294dc4369b210807bad75273e59aef856e383b62
    feeToSetter=0x076b885Ca6e863346774BEaF32f8752db6af9eEBEc2A9CB0D321725Cad6c197e
```

## Deploy router
```
protostar deploy 0x10fa77505ee3f0ce3d7c751096058d6025a368f4a9812c593790d63540e8c8f \
  --account-address 0x076b885Ca6e863346774BEaF32f8752db6af9eEBEc2A9CB0D321725Cad6c197e \
  --max-fee auto --network testnet \
  --inputs \
    0x0678950106a6e2d23ed2f38b3b645ea48e994a9d009c9aa7f8ef3f8b6434fb5e
    0xce61e906700ba8fceb3a7b294dc4369b210807bad75273e59aef856e383b62
```