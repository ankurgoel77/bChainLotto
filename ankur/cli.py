from web3 import Web3

ganache = ganache = "http://45.33.17.146:8545"
web3 = Web3(Web3.HTTPProvider(ganache))

address = input("Enter you address")
print(address)

print(f"balance of that address is {web3.fromWei(web3.eth.get_balance(address),'ether')}")


choice = input("Do you want to pick 6?  Y or N : ")
if choice == "Y":
    pick6(sssss)
else:
    input("Enter your 6 numbers separated by spaces..")