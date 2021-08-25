from web3 import Web3
import csv
import sys

# First, make a connection to the public testnet
ganache = "http://45.33.17.146:8545"
web3 = Web3(Web3.HTTPProvider(ganache))
if not web3.isConnected() :
    print("not connected")
    sys.exit()

# Open up the CSV and read from it
# The first row is the headers
# The second row is the account with 10e14 ETH (10e32 Wei).  This is the sender account
# The 1 index represents the address of the account, and the 3 index is the private key
csvpath = "bip39_addresses.csv"
with open(csvpath, "r") as csvfile:
    csvreader = csv.reader(csvfile, delimiter=",")
    header = next(csvreader)        # Skip Header Row
    main_row = next(csvreader)      # Read off the Primary account filled with ETH
    main_address = main_row[1]
    main_private_key = main_row[3]

    # Now loop over all remaining accounts, build a transaction, sign it, and send it
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
        print(f"transerred 100 ETH to wallet {current_address} with tx hash {web3.toHex(tx_hash)}")

    