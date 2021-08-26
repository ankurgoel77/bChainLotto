import json
from web3 import Web3

from eth_account import Account
import random

# User

f = open("abi.json")
abi = json.load(f)
f.close()

# ganache_server = "http://127.0.0.1:8545"
ganache_server = "http://45.33.17.146:8545"
web3 = Web3(Web3.HTTPProvider(ganache_server))
web3.isConnected()

pvtkey = input("type in your private key: ")
user_account = Account.from_key(pvtkey).address
print(f"Your wallet address is: {user_account} ")
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
    return ticket
    



def buyTicket(six_numbers):
    """
    Input 6 numbers separated by spaces, can alternatively call the pick6 function here
    """
    tx = contract.functions.buyTicket(
        six_numbers[0],
        six_numbers[1],
        six_numbers[2],
        six_numbers[3],
        six_numbers[4], 
        six_numbers[5]).buildTransaction({
            "chainId": 5337, 
            "value" : web3.toWei(1, "ether"),
            "nonce": web3.eth.getTransactionCount(user_account),
        })
        
    signed_tx = web3.eth.account.sign_transaction(tx, private_key=pvtkey)
    tx_hash = web3.eth.send_raw_transaction(signed_tx.rawTransaction)
    tx_receipt = web3.eth.waitForTransactionReceipt(tx_hash)

def main():
    while True:

        choice = input("buy a ticket for 1 ETH? Y or N ")
        if choice.upper() == "Y":
            choice = input("want to pick your own numbers? Y or N ")
            if choice.upper() == "Y":
                chosen_nums = input("enter 6 numbers 1-60 separated by spaces: ")
                chosen_nums = chosen_nums.split(" ")
                chosen_nums = [int(i) for i in chosen_nums]
                chosen_nums.sort()  
                buyTicket(chosen_nums)
                print(f"Here are your numbers: {chosen_nums}")
            elif choice.upper() == "N":
                ticket = pick6()
                buyTicket(ticket)
                print(f"Here are your numbers: {ticket}")
            continue

        if choice.upper() == "N":
            choice = input("Menu === w for get winning numbers, L for check lotto pot ")
            if choice.upper() == "W":
                isOpen = contract.functions.isOpen().call()
                if isOpen != True:
                    print(f"The winning numbers are: {contract.functions.getWinningNumbers().call()}")
                else:
                    print("Winning numbers are not available until the lotto has been drawn.")
                break

            elif choice.upper() == "L":
                print(f"Current Pot: {contract.functions.lottoPot().call()}")
                continue
            





if __name__ == "__main__":
   main()



