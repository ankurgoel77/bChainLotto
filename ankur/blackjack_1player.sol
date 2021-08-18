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
    
    // This contract requires the dealer to cover 1.5X the bet of the player
    // Dealer transfers 1.5X the bet in the constructor, and then player has to send bet by calling ante

    
    address payable player;
    address payable dealer;
    uint bet;
    uint pot;
    uint8[] playerHand;
    uint8[] dealerHand;
    uint8[52] deck;
    uint8 deckLength;
    
    bool public isFinished;
    bool public isStarted;
    
    // constructor will start game.  msg.sender is the dealer.  
    // constructor will deal 2 cards to player, and deal 2 cards to house
    // player must call getPlayerHand and getDealerHand to see results of deal
    constructor (uint _bet, address payable _player) public payable {
        require(_bet > 0,"You must bet some ether to play this game.");
        require(msg.value >= (5 * _bet/ 2), "dealer must cover at least 2.5X the player bet in case of insurance win and push");

        dealer = msg.sender;
        player = _player;
        bet = _bet;
        pot = msg.value;
        
        isFinished = false;
        isStarted = false;


        
    }
    
    // Call this function anytime to get the contract's balance, and the pot balance.  These 2 numbers should always be equal!
    function getBalance() public view returns (uint, uint) {
        return (address(this).balance, pot);
    }
    
    function ante() public payable {
        require (msg.sender == player, "only player can ante up");
        require (msg.value >= bet, "must send at least bet amount to ante.  excess will be returned");
        
        if (msg.value > bet) {
            msg.sender.transfer(msg.value - bet);
        }
        pot += bet;
        
        // initialize the deck, gas payed by player
        for (uint8 i = 0; i < 52; i++) {
            deck[i] = i;
        }
        deckLength = 52;
        
        deal();
        isStarted = true;
    }
    
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
    
    function getPlayerHand() public view returns (uint8[] memory) {
        return playerHand;
    }
    
    function getHouseHand() public view returns (uint8[] memory) {
        if (isFinished) {
            return dealerHand;
        } else {
            uint8[] memory hand = new uint8[](1);  // had to fight compiler to get this to work.
            hand[0]=dealerHand[0];
            return hand;
        }
    }
    
    function stand() public {}
    
    function hit() public {}
    
    function doubleDown() public {}
    
    //function split() public returns () {}
    
    
    // if dealer has blackjack, buyInsurance returns true, and will payout 2-to-1 on insurance bets, and game will end on this function call.  
    // if player also has blackjack, dealer get 1X bet and player gets 1X bet (push)
    // if player does not have blackjack, he automatically loses.
    // if dealer does not have blackjack, insurance goes to dealer and game continues
    function buyInsurance(uint insuranceAmount) public payable returns (bool) {
        require(playerHand.length == 2, "cannot pay insurance once you have already hit");
        require(dealerHand[0] % 13 == 0, "insurance only applies when dealer is showing an Ace");
        require(insuranceAmount <= bet, "can only offer insurance up to original bet amount");
        
        if (dealerHand[1] % 13 >= 9) {  //dealer has blackjack
            player.transfer(insuranceAmount);
        } else {
            dealer.transfer(msg.value);
        }
    }
    
    // endGame can be called by dealer to prematurely end the game and send money to back to player and dealer
    function endGame() public {
        require(!isFinished, "cannot call endGame if game has already finished");
        if (isStarted) {
            player.transfer(bet);
            pot -= bet;
        }
        
        pot -= address(this).balance;
        dealer.transfer(address(this).balance);
        
        isFinished = true;
    }
    
    
}