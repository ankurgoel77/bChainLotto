
function getAddress() {
    player_pvt_key = txt_pvtkey.value;
    player_account = web3.eth.accounts.privateKeyToAccount(player_pvt_key);
    acc_address.value = player_account.address;
    web3.eth.getBalance(player_account.address).then(updatePlayerBalance);
}

function updatePlayerBalance(value) {
    acc_balance.value = value + " Wei  ==> (" + web3.utils.fromWei(value,"ether") + " Ether)";
    console.log(acc_balance.value);
    btn_ante.disabled = false;
}

function beginGame() {
    betAmount = txt_betAmount.value;
    if (Number(betAmount) > 1) {
        alert("max bet is 1 ether");
        betAmount = "1";
    }

    betAmount = web3.utils.toWei(betAmount, "ether");

    constructGame();
}

function constructGame() {
    //player_account is web3.eth.account
    //betAmount is a string in Wei

    let gasPrice = web3.eth.gasPrice;
    let gasPriceHex = web3.utils.toHex(gasPrice);
    let gasLimitHex = web3.utils.toHex(6000000000000);
    let block = web3.eth.getBlock("latest");
    let nonce = web3.eth.getTransactionCount(dealer_account.address, "pending");
    let nonceHex = web3.utils.toHex(nonce);


    // contractData = blackjackContract.new.getData(player, betAmount, {
    //     data: '0x' + bytecode["object"]
    // });  

    let blackjackContract = new web3.eth.Contract(abi);
    blackjackContract.options.data = '0x'+bytecode["object"];

    blackjackContract.deploy({arguments: [player_account.address, betAmount]
    }).send({
        from: dealer_account.address,
        gasLimit : 6721975,
        value : String( Math.trunc(Number(betAmount) * 2.5) + 1)
    }).then(function(newContractInstance){
        console.log("Contract Address is" + newContractInstance.options.address);
        currentContract = new web3.eth.Contract(abi, newContractInstance.options.address );
        ante();
    });


    

    // let rawTx = {
    //     nonce : nonceHex,
    //     gasPrice : gasPriceHex,
    //     gasLimit : gasLimitHex,
    //     data: contractData,
    //     from : dealer_account.account,
    //     value : "251"
    // }

    // web3.eth.accounts.signTransaction(rawTx,dealer_pvt_key).then(console.log, console.log)
    
}

function ante() {
    
    currentContract.methods.ante().send({
        from : player_account.address,
        value : betAmount,
        gasLimit : 6721975,
    }).then(function(receipt) {
        currentContract.methods.getPlayerHand().call({from: player_account.address}).then(function(value) {
            player_hand = value;
            player_string_hand.innerHTML = hand_to_str(player_hand);
            player_card_hand.innerHTML = hand_to_unicode(player_hand);
            results.innerHTML = "Your hand value is " + hand_to_value(player_hand);
            currentContract.methods.getDealerHand().call({from:player_account.address}).then(function(value) {
                dealer_hand = value;
                dealer_card_hand.innerHTML = hand_to_unicode(dealer_hand);
                if (hand_to_value(dealer_hand) == 11) {
                    btn_insurance.disabled = false;
                }
            })
        })
    } );

    btn_hit.disabled = false;
    btn_stand.disabled = false;
    btn_double.disabled = false;

}

function hit() {
    currentContract.methods.hit().send({
        from : player_account.address,
        gasLimit : 6721975,
    }).then(function(receipt) {
        currentContract.methods.getPlayerHand().call({from: player_account.address}).then(function(value) {
            player_hand = value;
            player_string_hand.innerHTML = hand_to_str(player_hand);
            player_card_hand.innerHTML = hand_to_unicode(player_hand);
            if (hand_to_value(player_hand) > 21) {
                endGame();
                results.innerHTML = "You Busted! Your hand value is " + hand_to_value;
                web3.eth.getBalance(player_account.address).then(updatePlayerBalance);
            } else {
                btn_insurance.disabled = false;
                btn_double.disabled = false;
                results.innerHTML = "Your hand value is " + hand_to_value(player_hand);
            }
            
        })
    });
}

function stand() {
    currentContract.methods.stand().send({
        from : player_account.address,
        gasLimit : 6721975,
    }).then(function(receipt) {
        currentContract.methods.getDealerHand().call({from: player_account.address}).then(function(value) {
            dealer_hand = value;
            dealer_string_hand.innerHTML = hand_to_str(dealer_hand);
            dealer_card_hand.innerHTML = hand_to_unicode(dealer_hand);
            endGame();
            let dealer_hand_value = hand_to_value(dealer_hand);
            let player_hand_value = hand_to_value(player_hand);
            if (dealer_hand_value > 21) {
                results.innerHTML = "Dealer Busted! Your hand value is " + player_hand_value + " and dealer hand value is " + dealer_hand_value;
                web3.eth.getBalance(player_account.address).then(updatePlayerBalance);
            } else if (dealer_hand_value < player_hand_value) {
                results.innerHTML = "You Win! Your hand value is " + player_hand_value + " and dealer hand value is " + dealer_hand_value;
            } else if (dealer_hand_value == player_hand_value) {
                results.innerHTML = "You Push. Your hand value is " + player_hand_value + " and dealer hand value is " + dealer_hand_value;
            } else {
                results.innerHTML = "You Lose. Your hand value is " + player_hand_value + " and dealer hand value is " + dealer_hand_value;
            }
            
        })
    });
}

function endGame() {
    btn_ante.disabled = true;
    btn_hit.disabled = true;
    btn_double.disabled = true;
    btn_stand.disabled = true;
    btn_insurance.disabled = true;
}

function num_to_unicode(number) {
    let codepoint = 0;
    let mod = number % 13;
    let div = Math.trunc(number/13);
    let black = false;

    // fix for knight card between Jack and Queen
    if (mod >= 11) {
        mod += 1;
    }
    
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

function hand_to_value(hand){
    let baseValue = 0
    let cardValue = 0
    let acesCount = 0

    for (let i = 0; i < hand.length; i++) {
        cardValue = hand[i] % 13;
        if (cardValue > 0){ // #not an ace
            if (cardValue < 10) {
                baseValue += cardValue + 1;
            } else {
                baseValue += 10;
            }
        } else {
            acesCount += 1;
        }
    }

    if (acesCount == 1) {
        if (baseValue + 11 <= 21) {
            return baseValue + 11;
        } else {
            return baseValue + 1;
        }
    } else if (acesCount == 2) {
        if (baseValue + 11 <= 21) {
            return baseValue + 12;
        } else {
            return baseValue + 2;
        }
    } else if (acesCount == 3){
        if (baseValue + 11 <= 21) {
            return baseValue + 13;
        } else {
            return baseValue + 3;
        }
    } else if (acesCount == 4) {
        if (baseValue + 11 <= 21) {
            return baseValue + 14;
        } else {
            return baseValue + 4;
        }
    } else {
        return baseValue;
    }
}


//pre-get all the buttons and boxes
const txt_pvtkey = document.querySelector('#pvtkey');
const acc_address = document.querySelector("#acc_address");
const acc_balance = document.querySelector("#acc_balance"); 
const txt_betAmount = document.querySelector("#betAmount");
const player_string_hand = document.querySelector('#player_string_hand');
const player_card_hand = document.querySelector('#player_card_hand');
const dealer_string_hand = document.querySelector('#dealer_string_hand');
const dealer_card_hand = document.querySelector('#dealer_card_hand');
const btn_insurance = document.querySelector('#btn_insurance');
const btn_ante = document.querySelector("#btn_ante");
const btn_hit = document.querySelector('#btn_hit');
const btn_stand = document.querySelector('#btn_stand');
const btn_double = document.querySelector('#btn_double');
const results = document.querySelector('#results');


const provider = new Web3.providers.HttpProvider('http://127.0.0.1:8545');
const web3 = new Web3(provider);




let dealer_pvt_key = "d5046127ca371f85b9268b4c3b6a2b5fa891c66e38c2532726215a7ce4673d32";
let dealer_account = web3.eth.accounts.privateKeyToAccount(dealer_pvt_key);
let player_pvt_key = null;
let player_account = null;

let betAmount = "0";

let currentContract = null;

// the hands will become arrays upon ante
let dealer_hand = null;
let player_hand = null; 



// const pCard = document.querySelector('#card');
// let myString = num_to_unicode(20);
// pCard.innerHTML = myString;

// let pHand = [23,45,9,50];
// document.querySelector('#player_string_hand').innerHTML = hand_to_str(pHand);
// document.querySelector('#player_card_hand').innerHTML = hand_to_unicode(pHand);

// document.querySelector("#btn_start").disabled = false;

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