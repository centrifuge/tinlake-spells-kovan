# tinlake kovan spells

## tests

set env

```
    ETH_RPC_URL=https://kovan.infura.io/v3/<INFURA_KEY>
```

run tests

```
    forge test --rpc_url=$ETH_RPC_URL
```

## deploy

set env

```
    ETH_RPC_URL=ttps://kovan.infura.io/v3/<INFURA_KEY>
    ETH_KEYSTORE
    ETH_PASSWORD
    ETH_FROM
    ETH_GAS_PRICE
    ETH_GAS=10000000
    ETHERSCAN_API_KEY=<ETHERSCAN_API_KEY>
```

run bash commands

```bash
 forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY src/spell.sol:TinlakeSpell --verify --etherscan-api-key $ETHERSCAN_KEY --legacy
```

## archive

store deployed spells in archive using following format

```bash
"archive/<pool_root>/spell-<contract-address>.sol"
```
