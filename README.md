# tinlake kovan spells

to run the tests 

```bash 
 ./bin/test.sh      
```

deploy


```bash 
 dapp create "src/spell.sol:TinlakeSpell"  
 dapp verify-contract --async "src/spell.sol:TinlakeSpell" <SPELL_ADDRESS>
```


archive

store deployed spells in archive using following format

```bash 
"archive/<root>/spell-<MM-DD-YYYYY>.soll"  
```