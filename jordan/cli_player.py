import json
from web3 import Web3
import random

# User

user_account = "user account address or privKeytoAccount"

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
    



def buyTicket(six_numbers_str):
    """
    Input 6 numbers as a string separated by spaces, can alternatively call the pick6 function here
    """






