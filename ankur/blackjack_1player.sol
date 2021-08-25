pragma solidity ^0.5.0;

contract BlackJack_1player {
    
    // a card is an integer from 0 to 51
    // 0-12 is Ace to King of Spades
    // 13-25 is Ace to King of Hearts
    // 26-38 is Ace to King of Diamonds
    // 39 to 51 is Ace to King of Clubs
    //   this means 9 through 12 represents 10/J/Q/K of spades
    //order from https://en.wikipedia.org/wiki/Playing_cards_in_Unicode
    //see rules at https://bicyclecards.com/how-to-play/blackjack/
    
    // insurance is only offered if player does not already have blackjack
    
    // This contract requires the dealer to cover 2.5X the bet of the player
    // Dealer transfers 2.5X the bet in the constructor, and then player has to send bet by calling ante

    
    address payable player;
    address payable dealer;
    
    uint public bet;        // Bet amount in Wei
    uint8[] playerHand;     // an array of integers representing player's hand
    uint8 playerHandValue;  // The numerical value of the hand in BlackJack rules
    uint8[] dealerHand;     // an array of integers represneting the dealer's hand
    uint8 dealerHandValue;  // The numerical value of the hand

    uint8[52] deck;         // 52 cards in a deck
    uint8 deckLength;       // the length of the deck starts at 52, and is reduced by 1 after dealing a card
    
    bool public isFinished; // isFinished is true when the game is over and either player or dealer wins, or push
    bool public isStarted;  // isStarted is true after the player ante's up their money
    
    // constructor will start the contract.  msg.sender is the dealer.  
    // dealer puts Ether in contract first and awaits ante() for player to send Ether
    // player must call getPlayerHand and getDealerHand to see results of deal
    // player must call ante to send bet and start the game
    constructor (address payable _player, uint _bet) public payable {
        require(_bet > 0,"You must bet some ether to play this game.");
        require(msg.value >= (5 * _bet/ 2), "dealer must cover at least 2.5X the player bet in case of insurance win and push");

        dealer = msg.sender;
        player = _player;
        bet = _bet;
        
        isFinished = false;
        isStarted = false;
    }

    // getHandValue calculates the numerical score of a hand in Blackjack
    // it assigns values 2 to 9 for cars from 2 to 9
    // it assigns 10 for cards from 10/J/Q/K
    // it then counts number of aces and chooses either 1 or 11, maximizing the hand value without going over 21
    function getHandValue(uint8[] storage hand) internal view returns (uint8) {
        // aces suck:  
        //   If a hand has 1 ace, add 1 or 11
        //   If a hand has 2 aces, add 2 or 12, anything else busts
        //   If a hand has 3 aces, add 3 or 13, anything else busts
        //   If a hand has 4 aces, add 4 or 14, anything else busts
        
        uint8 baseValue = 0;  // value without aces
        uint8 cardValue = 0;
        uint8 acesCount = 0;
        
        for (uint8 i = 0; i < hand.length; i++) {
            cardValue = hand[i] % 13;
            if (cardValue > 0) {   //not an aces
                if (cardValue < 10) {
                    baseValue += cardValue + 1;
                } else {
                    baseValue += 10;  // Jack, Queen, or King
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
            if (baseValue + 12 <= 21) {
                return baseValue + 12;
            } else {
                return baseValue + 2;
            }
        } else if (acesCount == 3) {
            if (baseValue + 13 <= 21) {
                return baseValue + 13;
            } else {
                return baseValue + 3;
            }
        } else if (acesCount == 4) {
            if (baseValue + 14 <= 21) {
                return baseValue + 14;
            } else {
                return baseValue + 4;
            }            
        } else {
            return baseValue;
        }
    }
    
    // player can always call this public view function to get total value of hand
    function getPlayerHandValue() public view returns (uint8) {
        return getHandValue(playerHand);
    }
    
    // player cannot call this function. Instead, call getDealerHand and calculate client side
    function getDealerHandValue() internal returns (uint8) {
        return getHandValue(dealerHand);
    }
    
    // Call this function anytime to get the contract's balance
    function getBalance() public view returns (uint) {
        return (address(this).balance);
    }
    
    // ante() must be called by player once the game is constructed. 
    // It initializes the deck from 0 to 51, sets isStarted to true, and calls deal()
    // It then checks to see if player got blackjack and if dealer got blackjack
    function ante() public payable {
        require (msg.sender == player, "only player can ante up");
        require (msg.value >= bet, "must send at least bet amount to ante.  excess will be returned");
        require (!isFinished, "cannot ante if game is finished");
        require (!isStarted, "cannot ante if game already started");
        
        
        // send back excess ether
        if (msg.value > bet) {
            msg.sender.transfer(msg.value - bet);
        }
        
        // initialize the deck, gas payed by player
        for (uint8 i = 0; i < 52; i++) {
            deck[i] = i;
        }
        deckLength = 52;
        
        deal();
        isStarted = true;
        playerHandValue = getPlayerHandValue();
        dealerHandValue = getDealerHandValue();
        
        if ((playerHandValue == 21) && (dealerHandValue < 21)) {  //blackjack
            player.transfer(bet * 3 /2 );
            dealer.transfer(address(this).balance);
            isFinished = true;
        }
        
        if ((playerHandValue == 21) && (dealerHandValue == 21)) {
            player.transfer(bet);
            dealer.transfer(address(this).balance);
            isFinished = true;
        }
    }
    
    // function dealSingleCard should be called when the player need to hit, or it is the dealer's turn and needs to hit
    // increment the counter every time you deal within a single transaction to make sure keccak256 hashes a different number
    function dealSingleCard(uint8 counter) internal returns (uint8) {
        uint8 random;
        uint8 card;
        random = uint8(uint256(keccak256(abi.encodePacked(block.timestamp+counter, block.difficulty+counter))) % deckLength  );
        card = random;
        deck[random] = deck[deckLength-1];
        deckLength -= 1;
        return card;
    }
    
    // function deal() is only called once per game during the ante().  
    // it will generate 4 random numbers and pull them from the deck array, insuring the cards are unique by decrementing the deckLength on each deal
    //    and removing the dealt card from the array
    // 2 cards will be placed in playerHand, and 2 cards in the dealerHand
    function deal() internal {
        uint8 random;
        
        random = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % deckLength  );
        playerHand.push(deck[random]);
        deck[random] = deck[deckLength-1];
        deckLength -= 1;  
        
        random = uint8(uint256(keccak256(abi.encodePacked(block.timestamp+1, block.difficulty+1))) % deckLength  );
        dealerHand.push(deck[random]);
        deck[random] = deck[deckLength-1];
        deckLength -= 1;    
        
        random = uint8(uint256(keccak256(abi.encodePacked(block.timestamp+2, block.difficulty+2))) % deckLength  );
        playerHand.push(deck[random]);
        deck[random] = deck[deckLength-1];
        deckLength -= 1;    
        
        random = uint8(uint256(keccak256(abi.encodePacked(block.timestamp+3, block.difficulty+3))) % deckLength  );
        dealerHand.push(deck[random]);
        deck[random] = deck[deckLength-1];
        deckLength -= 1;    
    }
    
    // public function to view the player's hand after ante
    function getPlayerHand() public view returns (uint8[] memory) {
        return playerHand;
    }

    // this public function will view the dealer's hand; HOWEVER!
    //  if the game is not finished, only the dealer's face card is returned
    //  once the game is finished, it will return the entire dealer's hand
    function getDealerHand() public view returns (uint8[] memory) {
        if (isFinished) {
            return dealerHand;
        } else {
            if (dealerHand.length == 0) {  // if you call getDealerHand before ante, I needed to return an empty array
                return dealerHand;
            }
            uint8[] memory hand = new uint8[](1);  // had to fight compiler to get this to work.
            hand[0]=dealerHand[0];
            return hand;
        }
    }
    
    // stand() is called by the player if they are satisifed with the value of their hand
    //  it will deal cards to the dealer until a hard 17 or the dealer goes bust
    //  once the dealer is complete, it will pay out whoever has the best hand without going over 21
    function stand() public {
        require(isStarted, "cannot call Stand without starting game");
        require(!isFinished, "cannot call Stand when game has already ended");
        uint8 counter;
        while (dealerHandValue < 17) {
            counter += 1;
            dealerHand.push(dealSingleCard(counter));
            dealerHandValue = getDealerHandValue();
        }
        
        if ((dealerHandValue > 21) || (dealerHandValue < playerHandValue)) {
            player.transfer(bet * 2);
            dealer.transfer(address(this).balance);
        } else if (dealerHandValue == playerHandValue) {
            player.transfer(bet);
            dealer.transfer(address(this).balance);
        } else if (dealerHandValue > playerHandValue) {
            // player gets nothing
        }
        isFinished = true;
        dealer.transfer(address(this).balance);  // any remaining money in the contract goes back to the dealer
    }
    
    // hit() is called by player if they want another card.
    //  if the player's hand goes over 21, they bust immediately and the game is finished.
    function hit() public {
        require(isStarted, "cannot call hit without starting game");
        require(!isFinished, "cannot call hit when game has already ended");
        playerHand.push(dealSingleCard(0));
        playerHandValue = getPlayerHandValue();
        
        if (playerHandValue > 21) {
            isFinished = true;
            dealer.transfer(address(this).balance);
        }
    }
    
    // doubleDown() allows the player to double their bet immediately after the ante and take only 1 card. 
    //  it will deal one card to the player.  If they don't bust, it will call stand() to allow the dealer to deal
    function doubleDown() public payable {
        require(playerHand.length == 2, "can only double down when showing 2 cards");
        playerHand.push(dealSingleCard(0));
        playerHandValue = getPlayerHandValue();
        
        if (playerHandValue > 21) {
            isFinished = true;
            dealer.transfer(address(this).balance);
        } else {
        
            stand();
        }
    }
    
    // if dealer has blackjack, buyInsurance returns true, and will payout 2-to-1 on insurance bets, and game will end on this function call.  
    // if player also has blackjack, dealer get 1X bet and player gets 1X bet (push)
    // if player does not have blackjack, he automatically loses.
    // if dealer does not have blackjack, insurance goes to dealer and game continues
    function buyInsurance() public payable returns (bool) {
        require(isStarted, "cannot buy insurance until you have ante'd up");
        require(!isFinished, "cannot buy insurance after game is finished.");
        require(playerHand.length == 2, "cannot pay insurance once you have already hit");
        require(dealerHand[0] % 13 == 0, "insurance only applies when dealer is showing an Ace");
        require(msg.value <= (bet / 2), "can only offer insurance up to 50% original bet amount");
        
        if (dealerHand[1] % 13 >= 9) {  //dealer has blackjack
            player.transfer(msg.value * 2);
            isFinished = true;
            return true;
        } else {
            dealer.transfer(msg.value);
            return false;
        }
    }
    
    // endGame can be called by dealer to prematurely end the game and send money to back to player and dealer
    function endGame() public {
        require(!isFinished, "cannot call endGame if game has already finished");
        if (isStarted) {
            player.transfer(bet);
        }
        
        dealer.transfer(address(this).balance);
        
        isFinished = true;
    }
    
    //Fallback function
    function () external payable {
        require(false, "This contract does not accept direct transfers.");
    }
    
    
}