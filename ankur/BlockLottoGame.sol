pragma solidity ^0.5.0;

contract BlockLottoGame{
    address starter;
    address payable beneficiary; // charity gets all if nobody wins :-) 
    uint8 public maxBallNum;
    
    bool isOpen;
    uint public lottoPot;
    uint64 winningTicket;
    
    mapping(uint64 => address payable[]) public tickets;
    
    event ticketBought (address buyer, uint8 num1, uint8 num2, uint8 num3, uint8 num4, uint8 num5, uint8 num6);
    event winningNumbers(uint8 num1, uint8 num2, uint8 num3, uint8 num4, uint8 num5, uint8 num6);
    event winningBuyer(address payable buyer, uint payout);
    
    constructor(
        address payable _beneficiary,
        uint8 _maxBallNum
        ) public {
            
        starter = msg.sender;
        beneficiary = _beneficiary; 
        maxBallNum = _maxBallNum;
        isOpen = true;
    }
    modifier openStatus{
        require (isOpen, "Lotto already closed");
        _;
    }
    
    function encodeTicket(uint8 num1, uint8 num2, uint8 num3, uint8 num4, uint8 num5, uint8 num6) internal pure returns (uint64) {
        return (uint64(num1) << 0) + (uint64(num2) << 8) + (uint64(num3) << 16) + (uint64(num4) << 24) + (uint64(num5) << 32) + (uint64(num6) << 40);
    }
    
    function buyTicket(uint8 num1, uint8 num2, uint8 num3, uint8 num4, uint8 num5, uint8 num6) public payable openStatus{
        // buy 1 ETH ticket (return excess), store & emit address+ nums, & add 1ETH to pot  
        require (msg.value >= 1 ether, "SEND MORE");
        // require now <= closingTime, "closed"
        if (msg.value > 1 ether) {
            msg.sender.transfer(msg.value - 1 ether);
        }
        lottoPot += 1 ether;
        
        uint64 ticket = encodeTicket(num1, num2, num3, num4, num5, num6);
        tickets[ticket].push(msg.sender);

        //@TODO: verify all nums are 1 - maxBallNum
        emit ticketBought(msg.sender, num1, num2, num3, num4, num5, num6);
    }
    
    function bubbleSort(uint8[6] memory a) internal  {
        uint8 i;
        uint8 j;
        uint8 temp;
        for (i = 0; i < 6-1 ; i++) {
            for (j = 0; j < 6-1-i; j++ ) {
                if (a[j] > a[j+1]) {
                    temp = a[j];
                    a[j] = a[j+1];
                    a[j+1] = temp;
                } 
            }
        }
    }
    
    function generateWinningNumbers() internal returns (uint8, uint8, uint8, uint8, uint8, uint8) {
        // This function generate 6 unique random numbers between 1 and maxBallNum inclusive
        // A "bag" of numbers is initialized in a array 
        // A random number will be chosen from this array and stored as a winning number, then the last number in the array is swapped into that storage position
        // and the bag length decremented.  This ensures that the next time we pick a random number, even if it's the same one as before, it will result in a different ball number
        uint8[6] memory numbers;
        uint8 random;
        
        uint8[] memory lottoBag = new uint8[](maxBallNum);
        uint8 bagLength = maxBallNum;
        for (uint8 i = 0; i < maxBallNum; i++) {
            lottoBag[i] = i+1;
        }
        
        random = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % maxBallNum  );
        numbers[0] = lottoBag[random];
        lottoBag[random] = lottoBag[bagLength-1];
        bagLength -= 1;
        
        random = uint8(uint256(keccak256(abi.encodePacked(block.timestamp+1, block.difficulty+1))) % maxBallNum  );
        numbers[1] = lottoBag[random];
        lottoBag[random] = lottoBag[bagLength-1];
        bagLength -= 1;
        
        random = uint8(uint256(keccak256(abi.encodePacked(block.timestamp+2,block.difficulty+2))) % maxBallNum  );
        numbers[2] = lottoBag[random];
        lottoBag[random] = lottoBag[bagLength-1];
        bagLength -= 1;
        
        random = uint8(uint256(keccak256(abi.encodePacked(block.timestamp+3,block.difficulty+3))) % maxBallNum  );
        numbers[3] = lottoBag[random];
        lottoBag[random] = lottoBag[bagLength-1];
        bagLength -= 1;
        
        random = uint8(uint256(keccak256(abi.encodePacked(block.timestamp+4, block.difficulty+4))) % maxBallNum  );
        numbers[4] = lottoBag[random];
        lottoBag[random] = lottoBag[bagLength-1];
        bagLength -= 1;
        
        random = uint8(uint256(keccak256(abi.encodePacked(block.timestamp+5, block.difficulty+5))) % maxBallNum  );
        numbers[5] = lottoBag[random];
        lottoBag[random] = lottoBag[bagLength-1];
        bagLength -= 1;
        
        bubbleSort(numbers);
        
        return (numbers[0], numbers[1], numbers[2], numbers[3], numbers[4], numbers[5]);
    }
    
    function finalize() public openStatus{
        // pick winning nums, find winning tickets, divide .8 pot among winners
        require (msg.sender == starter, "Only the starter can close the lottery");
        uint8 num1;
        uint8 num2;
        uint8 num3;
        uint8 num4;
        uint8 num5;
        uint8 num6;
        
        
        isOpen = false;
        
        uint winningAmount = 0;

        (num1, num2, num3, num4, num5, num6) =  generateWinningNumbers();
        emit winningNumbers(num1, num2, num3, num4, num5, num6);
        
        winningTicket = encodeTicket(num1, num2, num3, num4, num5, num6);
        
        address payable[] memory winners = tickets[winningTicket];
        
        if (winners.length > 0) {
            winningAmount = uint(lottoPot * 4 / 5 / winners.length);
        }
        
        
        for (uint i = 0; i < winners.length; i++) {
            winners[i].transfer(winningAmount);
            emit winningBuyer(winners[i], winningAmount);
        }
        
        lottoPot -= (winningAmount * winners.length); // takes care of remainders
        beneficiary.transfer(lottoPot);
        
    }
    
    function getWinningNumbers() public view returns (uint8, uint8, uint8, uint8, uint8, uint8) {
        require (!isOpen, "lottery has not completed yet");
        return (uint8((winningTicket & 255) >> 0),
                uint8((winningTicket & 65280) >> 8),
                uint8((winningTicket & 16711680) >> 16),
                uint8((winningTicket & 4278190080) >> 24),
                uint8((winningTicket & 1095216660480) >> 32),
                uint8((winningTicket & 280375465082880) >> 40) 
                );
    }
    
    
}