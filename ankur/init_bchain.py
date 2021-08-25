from web3 import Web3
import csv

csvpath = "bip39_addresses.csv"
ganache = ganache = "http://45.33.17.146:8545"
web3 = Web3(Web3.HTTPProvider(ganache))
if not web3.isConnected() :
    print("not connected")
    exit()

with open(csvpath, "r") as csvfile:
    csvreader = csv.reader(csvfile, delimiter=",")
    header = next(csvreader)
    main_row = next(csvreader)
    main_address = main_row[1]
    main_private_key = main_row[3]

    for row in csvreader:
        current_address = row[1]
        nonce = web3.eth.getTransactionCount(main_address)
        tx = {
            "nonce": nonce,
            "to" : current_address,
            "value" : web3.toWei(100, "ether"),
            "gas" : 2000000,
            "gasPrice" : web3.toWei("50", "gwei")
        }
        signed_tx = web3.eth.account.sign_transaction(tx, main_private_key)
        tx_hash = web3.eth.send_raw_transaction(signed_tx.rawTransaction)
        print(f"transerred 2 ETH to wallet {current_address} with tx hash {web3.toHex(tx_hash)}")

    