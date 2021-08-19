from web3 import Web3
import json
import sys
import os

from web3.providers import base

#initialize abi and bytecode
print(os.getcwd())
f = open("./ankur/blackjack_abi.json")
abi = json.load(f)
f.close()

f = open("./ankur/blackjack_bytecode.json")
bytecode_json = json.load(f)
f.close()
bytecode = bytecode_json["object"]

ganache_server = "http://127.0.0.1:8545"
web3 = Web3(Web3.HTTPProvider(ganache_server))

dealer = web3.eth.accounts[1]
player = web3.eth.accounts[2]
web3.eth.default_account = dealer

#current default is dealer
blackjack_contract = web3.eth.contract(abi=abi, bytecode=bytecode)

def num_to_str(number):
    card_str = ""
    mod = number % 13
    div = number // 13

    if mod == 0:
        card_str += "A"
    elif mod == 10:
        card_str += "J"
    elif mod == 11:
        card_str += "Q"
    elif mod == 12:
        card_str += "K"
    else:
        card_str += f"{mod+1}"

    if div == 0:
        card_str += " Spades"
    elif div == 1:
        card_str += " Hearts"
    elif div == 2:
        card_str += " Diamonds"
    elif div == 3:
        card_str += " Clubs"

    return card_str

# nums_to_cards converts a list of numbers from 0-51 into a list of cards
def nums_to_cards(hand):
    cards = []
    for num in hand:
        cards.append(num_to_str(num))
    return cards

def nums_to_value(hand):
    baseValue = 0
    cardValue = 0
    acesCount = 0

    for i in hand:
        cardValue = i % 13
        if cardValue > 0: #not an ace
            if cardValue < 10:
                baseValue += cardValue + 1
            else:
                baseValue += 10
        else:
            acesCount += 1

    if acesCount == 1:
        if baseValue + 11 <= 21:
            return baseValue + 11
        else:
            return baseValue + 1
    elif acesCount == 2:
        if baseValue + 11 <= 21:
            return baseValue + 12
        else:
            return baseValue + 2
    elif acesCount == 3:
        if baseValue + 11 <= 21:
            return baseValue + 13
        else:
            return baseValue + 3
    elif acesCount == 4:
        if baseValue + 11 <= 21:
            return baseValue + 14
        else:
            return baseValue + 4
    else:
        return baseValue

def main() :
    print("****************Welcome to Blockchain Blackjack*************")
    bet = input("How much Wei would you like to bet?  ")
    bet = int(bet)
    print("** Instantiating game on the blockchain **")

    #current default is dealer
    tx_hash_construct = blackjack_contract.constructor(player, bet).transact({"value":int(bet*2.5+1)})
    tx_receipt_construct = web3.eth.waitForTransactionReceipt(tx_hash_construct)
    current_game_contract = web3.eth.contract(address=tx_receipt_construct.contractAddress, abi=abi)

    #check to make sure dealer has properly funded the game
    contract_balance = current_game_contract.functions.getBalance().call()
    if contract_balance < bet :
        sys.exit("dealer did not properly fund the contract")

    #change to player
    print("** Posting your ante to the blockchain **")
    web3.eth.default_account = player
    tx_hash_ante = current_game_contract.functions.ante().transact({"value":bet})
    tx_receipt_ante = web3.eth.waitForTransactionReceipt(tx_hash_ante)
    player_hand = current_game_contract.functions.getPlayerHand().call()
    player_hand_value = current_game_contract.functions.getPlayerHandValue().call()
    dealer_hand = current_game_contract.functions.getDealerHand().call()
    print(f"You are showing {', '.join(nums_to_cards(player_hand))} with a value of {player_hand_value}. Dealer is showing {', '.join(nums_to_cards(dealer_hand))}")
    
    while player_hand_value <= 21:
        choice = input("Do you want to (H)it or (S)tand or (D)ouble Down: ")
        if choice == "S":
            tx_hash_stand = current_game_contract.functions.stand().transact()
            tx_receipt_stand = web3.eth.waitForTransactionReceipt(tx_hash_stand)
            dealer_hand = current_game_contract.functions.getDealerHand().call()
            dealer_hand_value = nums_to_value(dealer_hand)
            if dealer_hand_value > 21:
                print(f"You win. Dealer busted with total {dealer_hand_value}. His hand was {', '.join(nums_to_cards(dealer_hand))}")
            elif player_hand_value > dealer_hand_value:
                print(f"You win. Dealer lost with total {dealer_hand_value}. His hand was {', '.join(nums_to_cards(dealer_hand))}")
            elif player_hand_value == dealer_hand_value:
                print(f"You pushed. Dealer ended with total {dealer_hand_value}. His hand was {', '.join(nums_to_cards(dealer_hand))}")
            else:
                print(f"You lost. Dealer ended with total {dealer_hand_value}. His hand was {', '.join(nums_to_cards(dealer_hand))}")
            break
        elif choice == "H":
            tx_hash_hit = current_game_contract.functions.hit().transact()
            tx_receipt_stand = web3.eth.waitForTransactionReceipt(tx_hash_hit)
            player_hand = current_game_contract.functions.getPlayerHand().call()
            player_hand_value = current_game_contract.functions.getPlayerHandValue().call()
            if player_hand_value > 21:
                print(f"You busted with total {player_hand_value}. Your hand was {', '.join(nums_to_cards(player_hand))}")
                break
            else:
                print(f" Your hand is now {', '.join(nums_to_cards(player_hand))}. Your total is {player_hand_value}.")
                continue
        elif choice == "D":
            tx_hash_double = current_game_contract.functions.doubleDown().transact({"value":bet})
            tx_receipt_double = web3.eth.waitForTransactionReceipt(tx_hash_double)
            player_hand = current_game_contract.functions.getPlayerHand().call()
            player_hand_value = current_game_contract.functions.getPlayerHandValue().call()
            dealer_hand = current_game_contract.functions.getDealerHand().call()
            dealer_hand_value = nums_to_value(dealer_hand)
            if dealer_hand_value > 21:
                print(f"You win. Dealer busted with total {dealer_hand_value}. His hand was {', '.join(nums_to_cards(dealer_hand))}")
            elif player_hand_value > dealer_hand_value:
                print(f"You win. Dealer lost with total {dealer_hand_value}. His hand was {', '.join(nums_to_cards(dealer_hand))}")
            elif player_hand_value == dealer_hand_value:
                print(f"You pushed. Dealer ended with total {dealer_hand_value}. His hand was {', '.join(nums_to_cards(dealer_hand))}")
            else:
                print(f"You lost. Dealer ended with total {dealer_hand_value}. His hand was {', '.join(nums_to_cards(dealer_hand))}")
            break
        else:
            print("Incorrect Selection. Try Again")


    return

if __name__ == "__main__":
   main()