install ganache

> npm install -g ganache-cli

start ganache

> ganache-cli --chainId 5337 --db ./gandb -v -h 45.33.17.146

from BIP39, use Mnemonic `panther travel sketch action ill portion gallery welcome crumble butter route renew horn shine oak` with ETH coin. You get the following address at m/44'/60'/0'/0/0:

* address: 0x7E86cfAc3C3bCd76C4a3F6a578acaAb34b9c481a
* public key : 0x0376025d39ec6cc2e42f45bddbfee2607648c907c41e9dfd7954cfb41d2c78aaa4
* private key : 0x8c5784cca8b5444cb8ed7f06297b29a88ffaa31236c872793918c45a1c376710

we can start ganache with the following to fund a single wallet with 100,000 ether (1e23 wei): 

> ganache-cli --chainId 5337 --db ./gandb -v -h 45.33.17.146  --account="0x8c5784cca8b5444cb8ed7f06297b29a88ffaa31236c872793918c45a1c376710,100000000000000000000000"  

or, to initialize the first 9 wallets of a mnemonic, use :

> ganache-cli --chainId 5337 --db ./gandb -v -h 45.33.17.146  -m "panther travel sketch action ill portion gallery welcome crumble butter route renew horn shine oak"

if you perform any transactions on this blockchain, and then kill the ganache server, re-starting ganache with the same command will start up where you left off, and will not re-initialize those wallets, even if those wallets are outputted again.

to re-start from scratch, you need to delete the db:

> rm -rf gandb  

finally, we can instantiate the chain with a single address with a large amount of ether (priced in wei).  This example is 32 zeros, so 10^14 ether:

> ganache-cli --chainId 5337 --db ./gandb -v -h 45.33.17.146  --account="0x8c5784cca8b5444cb8ed7f06297b29a88ffaa31236c872793918c45a1c376710,100000000000000000000000000000000" 
