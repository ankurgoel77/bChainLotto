function multiply(num1, num2) {
    let result = num1 * num2;
    return result;
}

function getAddress() {
    const txt_pvtkey = document.querySelector('#pvtkey');
    const acc_address = document.querySelector("#acc_address");
    const acc_balance = document.querySelector("#acc_balance");
    let pvtkey = txt_pvtkey.value;
    let account = web3.eth.accounts.privateKeyToAccount(pvtkey);
    acc_address.value = account.address;
    web3.eth.getBalance(account.address).then(myTestFunction);
    console.log(acc_balance.value);
}

function myTestFunction(value) {
    const acc_balance = document.querySelector("#acc_balance");
    acc_balance.value = value;
}

function constructGame() {
    const txt_betAmount = document.querySelector("#betAmount");
    let betAmount = Number(txt_betAmount.value);
    let player = document.querySelector("#acc_address").value;

    let gasPrice = web3.eth.gasPrice;
    let gasPriceHex = web3.toHex(gasPrice);
    let gasLimitHex = web3.toHex(6000000000000);
    let block = web3.eth.getBlock("latest");
    let nonce = web3.eth.getTransactionCount(dealer_account.address, "pending");
    let nonceHex = web3.toHex(nonce);

    let contractData = '0x'+ bytecode["object"];

    let blackjackContract = web3.eth.contract(abi);
    
}

function num_to_unicode(number) {
    let codepoint = 0;
    let mod = number % 13;
    let div = Math.trunc(number/13);
    let black = false;
    
    switch(div) {
        case 0:
            codepoint = 127137 + mod;
            black = true;
            break;
        case 1:
            codepoint = 127153 + mod;
            break;
        case 2:
            codepoint = 127169 + mod;
            break;
        case 3:
            codepoint = 127185 + mod;
            black = true;
            break;
    }

    if (black) {
        return '<span style="color:black">&#' + String(codepoint) +';</span>'
    } else {
        return '<span style="color:red">&#' + String(codepoint) +';</span>'
    }
}

function num_to_str(number) {
    let card_str = "";
    let mod = number % 13;
    let div = Math.trunc(number/13);

    switch(mod) {
        case 0:
            card_str += "Ace";
            break;
        case 10:
            card_str += "Jack";
            break;
        case 11:
            card_str += "Queen";
            break;
        case 12:
            card_str += "King";
            break;
        default:
            card_str += String(mod+1);
    }

    switch(div) {
        case 0:
            card_str += " of Spades"
            break;
        case 1:
            card_str += " of Hearts"
            break;
        case 2:
            card_str += " of Diamonds"
            break;
        case 3:
            card_str += " of Clubs"
            break;
    }

    return card_str
}

function hand_to_unicode(hand) {
    value = "";
    for (let i = 0; i < hand.length; i++) {
        value += num_to_unicode(hand[i]);
    }
    return value
}

function hand_to_str(hand) {
    value = [];
    for (let i = 0; i < hand.length; i++) {
        value.push(num_to_str(hand[i]));
    }
    return value.join(', ');
}

const provider = new Web3.providers.HttpProvider('http://127.0.0.1:8545');
const web3 = new Web3(provider);




let dealer_pvt_key = "d5046127ca371f85b9268b4c3b6a2b5fa891c66e38c2532726215a7ce4673d32";
let dealer_account = web3.eth.accounts.privateKeyToAccount(dealer_pvt_key);



const pCard = document.querySelector('#card');
let myString = num_to_unicode(20);
pCard.innerHTML = myString;

let pHand = [23,45,9,50];
document.querySelector('#player_string_hand').innerHTML = hand_to_str(pHand);
document.querySelector('#player_card_hand').innerHTML = hand_to_unicode(pHand);

document.querySelector("#btn_start").disabled = false;

// const myHeading = document.querySelector('h1');
// myHeading.textContent = "Hello World!";

// const myPara = document.querySelector('#para1');
// myPara.textContent = "selected paragraph";

// const btn_pvtkey = document.querySelector('#btn_pvtkey');
// const acc_address = document.querySelector("#acc_address")


//console.log('No web3 instance injected, using Local web3.');

// //const myAccount = web3.eth.accounts.privateKeyToAccount("d5046127ca371f85b9268b4c3b6a2b5fa891c66e38c2532726215a7ce4673d32");
// const myAccount = web3.eth.accounts.privateKeyToAccount(btn_pvtkey.value);

// acc_address.value = myAccount.address;