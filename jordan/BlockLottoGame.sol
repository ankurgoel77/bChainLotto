pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/drafts/Counters.sol";

contract BlockLottoGame{
    using Counters for Counters.Counter;
    Counters.Counter ticketids;
    address starter;
    address beneficiary; // charity gets all if nobody wins :-) 
    
    // closingTime
    bool isOpen;
    uint lottoPot;
    uint maxBallNum;
    
    
    struct Ticket {
        address payable buyer;
        uint num1;
        uint num2;
        uint num3;
        uint num4;
        uint num5;
        uint num6;
    
    }
    mapping(uint => Ticket) public tickets;
    
    event ticketBought (address buyer, uint num1, uint num2, uint num3, uint num4, uint num5, uint num6);
    event winningNumbers(uint num1, uint num2, uint num3, uint num4, uint num5, uint num6);
    event winningTicket(address buyer, uint payout);
    
    constructor(
        address payable _beneficiary,
        uint maxBallNum
        // uint _closingTime 
        ) public {
            
        starter = msg.sender;
        beneficiary = _beneficiary; 
        maxBallNum = _maxBallNum;
        isOpen = true;
        // closingTime = _closingTime
    }
    modifier openStatus{
        require (isOpen, "Lotto already closed");
        _;
    }
    
    function buyTicket(uint num1, uint num2, uint num3, uint num4, uint num5, uint num6) public payable openStatus{
        // buy 1 ETH ticket (return excess), store & emit address+ nums, & add 1ETH to pot  
        require (msg.value >= 1 ether, "SEND MORE");
        // require now <= closingTime, "closed"
        if (msg.value > 1 ether) {
            msg.sender.transfer(msg.value - 1 ether);
        }
        lottoPot += 1 ether;
        Ticket ticket = new ticket(msg.sender, num1, num2, num3, num4, num5, num6);
        ticketids.increment();
        tickets[ticketids.current()] = ticket
        
        //@TODO: verify all nums are 1 - maxBallNum
        emit ticketBought(msg.sender, num1, num2, num3, num4, num5, num6);
    }
    
    function getWinningNumbers() private view returns (uint, uint, uint, uint, uint, uint) {
        // need to make sure the numbers are independent
        num1 = ( uint8(uint256(keccak256(block.timestamp, block.difficulty)) % maxBallNum  ) + 1;
        num2 = ( uint8(uint256(keccak256(block.timestamp+1, block.difficulty+1)) % maxBallNum ) + 1;
        num3 = ( uint8(uint256(keccak256(block.timestamp+2, block.difficulty+2)) % maxBallNum ) + 1;
        num4 = ( uint8(uint256(keccak256(block.timestamp+3, block.difficulty+3)) % maxBallNum ) + 1;
        num5 = ( uint8(uint256(keccak256(block.timestamp+4, block.difficulty+4)) % maxBallNum ) + 1;
        num6 = ( uint8(uint256(keccak256(block.timestamp+5, block.difficulty+5)) % maxBallNum ) + 1;
    }
    
    function finalize()public openStatus{
        // pick winning nums, find winning tickets, divide .8 pot among winners
        require (msg.sender == starter, "Only the starter can close the lottery");
        isOpen = false;
        
        Counters.Counter winnerIds;
        uint winningAmount = 0;
        mapping (uint ==> Ticket) winners;
        // require for closingTime;
        
        (num1, num2, num3, num4, num5, num6) =  getWinningNumbers();
        emit winningNumbers(num1, num2, num3, num4, num5, num6);
        
        
        for (uint i=1; i<= ticketids; i++) {
            Ticket currentTicket = tickets[i];
            if (currentTicket.num1 == num1 && currentTicket.num2 == num2 && currentTicket.num3 == num3 && currentTicket.num4 == num4 && currentTicket.num5 == num5 && currentTicket.num6 == num6 ) {
                winnerIds.increment();
                winners[winnerIds.current()] = currentTicket;
            }
        }
        if (winnerIds.current() > 0) {
            winningAmount = lottoPot * .8 / winnerIds.current();
        }
        
        for (uint i = 1; i <= winnerIds.current(); i++) {
            winners[i].buyer.transfer(winningAmount);
            emit winningTicket(buyer, winningAmount);
        }
        
        lottoPot -= winningAmount // takes care of remainders
        beneficiary.transfer(lottoPot)
        
    }
    
    //@TODO: <maybe> rollover lotto (sees previous pot >>>>to potential next contract) 
    
    
    // uint256 public lotteryId;
    // function startLotto(uint256 duration){}
    
    
}