import json
from toolz.itertoolz import first
from web3 import Web3

from eth_account import Account

# Creator
"""

initiate the contract with all required parameters: 
    
    init starting account object
    init contract
        set maxballnum

"""

f = open("abi.json")
abi = json.load(f)
f.close()

f = open("bytecode.json")
bytecode_json = json.load(f)
f.close()
bytecode = bytecode_json["object"]

# ganache_server = "http://127.0.0.1:8545"
ganache_server = "http://45.33.17.146:8545"
web3 = Web3(Web3.HTTPProvider(ganache_server))
web3.isConnected()

pvtkey = input("type in your private key: ")
creator_account = Account.from_key(pvtkey)
beneficiary_key = (input("type in a private key for the beneficiary: "))
beneficiary = Account.from_key(beneficiary_key).address

web3.eth.default_account = creator_account.address

def init_game():
    lotto_contract = web3.eth.contract(abi=abi, bytecode=bytecode)

    tx_hash = lotto_contract.constructor(beneficiary, 60).transact()
    tx_receipt = web3.eth.waitForTransactionReceipt(tx_hash)
    return tx_receipt.contractAddress # need to give this address to players

def get_lottopot(contractAddress):
    current_contract = web3.eth.contract(address=contractAddress, abi=abi)
    lottoPot = current_contract.functions.lottoPot().call()
    return lottoPot

def get_winningnums(contractAddress):
    current_contract = web3.eth.contract(address=contractAddress, abi=abi)
    winning_numbers = current_contract.functions.getWinningNumbers().call() 
    return winning_numbers

def finalize(contractAddress):
    current_contract = web3.eth.contract(address=contractAddress, abi=abi)
    tx_hash = current_contract.functions.finalize().transact()
    tx_receipt = web3.eth.waitForTransactionReceipt(tx_hash)

def listTickets(contractAddress):
    print(" ")
    print("======= TICKET LIST ===================")
    current_contract = web3.eth.contract(address=contractAddress, abi=abi)
    ticket_filter = current_contract.events.ticketBought.createFilter(fromBlock="0x0", argument_filters={})
    for entry in ticket_filter.get_all_entries():
        myEvent = entry["args"]
        myTicket = ""
        for i in range(1,6+1):
            key = f'num{i}'
            myTicket += str(myEvent[key]) + " "

        print("Wallet Address " + myEvent["buyer"] + " bought the following numbers: " + myTicket)
    print("=======================================")
    print("")

def mywhileloop(contractAddress):
    choice = ""
    while choice.upper() != "Q":
        choice = input("Menu === b for Balance, w for WinningNums, f for Finalize, L for list tickets, Q for quit ")
        if choice.upper() == "B":
            print(get_lottopot(contractAddress))
        elif choice.upper() == "W":
            print(get_winningnums(contractAddress))
        elif choice.upper() == "F":
            finalize(contractAddress)
        elif choice.upper() == "L":
            listTickets(contractAddress)


def main():
    choice = input("construct game? Y or N ")
    if choice.upper() == "Y":
        contractAddress = init_game()
        print(f"Contract address for players , {contractAddress} ")
        mywhileloop(contractAddress)
    if choice.upper() == "N":
        contractAddress = input("provide existing contract address : ")
        mywhileloop(contractAddress)




if __name__ == "__main__":
   main()