// Get Address converts the Player Private Key into an address and then gets the account balance
function getAddress() {
    player_pvt_key = txt_pvtkey.value;
    player_account = web3.eth.accounts.privateKeyToAccount(player_pvt_key);
    acc_address.value = player_account.address;
    web3.eth.getBalance(player_account.address).then(updatePlayerBalance);
}

// Updates the UI for player's ETH balance
function updatePlayerBalance(value) {
    acc_balance.value = value + " Wei  ==> (" + web3.utils.fromWei(value,"ether") + " Ether)";
    console.log(acc_balance.value);
    btn_ante.disabled = false;
}

// Called when ante is pressed.  It checks that balance is correctly entered than calls constructGame
function beginGame() {
    betAmount = txt_betAmount.value;
    if (Number(betAmount) > 1) {
        alert("max bet is 1 ether");
        betAmount = "1";
    }

    betAmount = web3.utils.toWei(betAmount, "ether");

    constructGame();
}

// This function uses the dealer account to deploy the Blackjack contract and then call ante
function constructGame() {
    //player_account is web3.eth.account
    //betAmount is a string in Wei
  
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
}

// This function uses the player account to call ante on the contract
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

                if (hand_to_value(player_hand) == 21) {  //player has blackjack
                    endGame();
                    web3.eth.getBalance(player_account.address).then(updatePlayerBalance);
                    if (hand_to_value(dealer_hand) == 21) {
                        results.innerHTML = "You and the dealer both have Blackjack! Push! Your hand value is " + player_hand_value + " and dealer hand value is " + dealer_hand_value;

                    } else {
                        results.innerHTML = "You have Blackjack! Your hand value is " + player_hand_value + " and dealer hand value is " + dealer_hand_value;

                    }

                } else if (hand_to_value(dealer_hand) == 11) {
                    btn_insurance.disabled = false;
                }
            })
        })
    } );

    btn_hit.disabled = false;
    btn_stand.disabled = false;
    btn_double.disabled = false;

}

// This function uses the player account to call hit on the contract
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
                results.innerHTML = "You Busted! Your hand value is " + hand_to_value(player_hand);
            } else {
                btn_insurance.disabled = true;
                btn_double.disabled = true;
                results.innerHTML = "Your hand value is " + hand_to_value(player_hand);
            }
            
        })
    });
}

// This function uses the player account to call stand on the contract
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

// This function uses the player account to call doubleDown on the contract
function double() {
    currentContract.methods.doubleDown().send({
        from : player_account.address,
        gasLimit : 6721975,
        value : betAmount
    }).then(function(receipt) {
        currentContract.methods.getPlayerHand().call({from: player_account.address}).then(function(value) {
            player_hand = value;
            player_string_hand.innerHTML = hand_to_str(player_hand);
            player_card_hand.innerHTML = hand_to_unicode(player_hand);
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
        })
    });   
}

// This function simply reloads the page, similar to F5
function playAgain() {
    location.reload();
    return false;
}

// This function grays out all the buttons once the game is over
function endGame() {
    btn_ante.disabled = true;
    btn_hit.disabled = true;
    btn_double.disabled = true;
    btn_stand.disabled = true;
    btn_insurance.disabled = true;
    btn_playAgain.disabled = false;
    web3.eth.getBalance(player_account.address).then(updatePlayerBalance);
}

// This function creates a string that generates unicode codepoints for a single playing card and spans it with a color
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

// This function creates a string that describes a card
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

// This function loops over num_to_unicode to generate codepoints for an entire hand
function hand_to_unicode(hand) {
    value = "";
    for (let i = 0; i < hand.length; i++) {
        value += num_to_unicode(hand[i]);
    }
    return value
}

// This function loops over num_to_str to generate a description of a hand
function hand_to_str(hand) {
    value = [];
    for (let i = 0; i < hand.length; i++) {
        value.push(num_to_str(hand[i]));
    }
    return value.join(', ');
}

// This function calculates the value of a hand
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
const btn_playAgain = document.querySelector("#btn_playAgain");

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
