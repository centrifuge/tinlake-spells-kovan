# tinlake kovan spells

## tests

set env
```
    ETH_RPC_URL=https://kovan.infura.io/v3/<INFURA_KEY>
```   

run tests
```bash 
 ./bin/test.sh      
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

```bash 
 dapp create "src/spell.sol:TinlakeSpell"  
 dapp verify-contract --async "src/spell.sol:TinlakeSpell" <SPELL_ADDRESS>
```


## archive

store deployed spells in archive using following format

```bash 
"archive/<root>/spell-<contract-address>.sol"  
```