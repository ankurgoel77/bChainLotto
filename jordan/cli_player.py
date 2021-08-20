import json
from web3 import Web3

from eth_account import Account
import random

# User

f = open("abi.json")
abi = json.load(f)
f.close()

ganache_server = "http://127.0.0.1:8545"
web3 = Web3(Web3.HTTPProvider(ganache_server))
web3.isConnected()

pvtkey = input("type in your private key: ")
user_account = Account.from_key(pvtkey)
contractAddress = input("type in contract address: ")
contract = web3.eth.contract(address=contractAddress, abi=abi)
web3.eth.default_account = user_account

def pick6():
    """
    Uses rng to pick 6 unique random numbers to use in the ticket buy
    """
    myset = set(range(1,60+1))  # 60 is maxballnum
    ticket = []
    for i in range(0,6):
        number = random.choice(list(myset))
        ticket.append(number)
        myset = myset - set([number])
    ticket.sort()
    



def buyTicket(six_numbers):
    """
    Input 6 numbers separated by spaces, can alternatively call the pick6 function here
    """
    tx_hash = contract.functions.buyTicket(
        six_numbers[0],
        six_numbers[1],
        six_numbers[2],
        six_numbers[3],
        six_numbers[4], 
        six_numbers[5]).transact({"value": web3.toWei(1, "ether")})
    
    tx_receipt = web3.eth.waitForTransactionReceipt(tx_hash)

def main():
    choice = input("buy a ticket? Y or N ")
    if choice == "Y":
        choice = input("want to pick your own numbers? Y or N ")
        if choice == "Y":
            chosen_nums = input("enter 6 numbers 1-60 separated by spaces: ")
            chosen_nums = chosen_nums.split(" ")
            chosen_nums = [int(i) for i in chosen_nums]
            buyTicket(chosen_nums)
        elif choice == "N":
            buyTicket(pick6())
    if choice == "N":
        choice = "Menu === w for get winning numbers, L for check lotto pot "
        if choice == "w":
            isFinished = contract.functions.isFinished().call()
            if isFinished:
                print(f"The winning numbers are: {contract.functions.getWinningNumbers().call()}")
            else:
                print("Winning numbers are not available until the lotto has been drawn.")

        elif choice == "L":
            print(f"Current Pot: {contract.functions.lottoPot().call()}")





if __name__ == "__main__":
   main()



