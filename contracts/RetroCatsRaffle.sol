// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "../interfaces/IKeeperCompatible.sol";
import "../interfaces/IRetroCats.sol";

/**
* @dev This contract is designed to send an NFT holder `s_winAmount` of ETH every `s_interval` seconds.
* The Chainlink Keeper network kicks off a raffle, and then a Chainlink VRF node 
* returns a random number to give a cat holder X amount of ETH
*/
contract RetroCatsRaffle is Ownable, VRFConsumerBase, ReentrancyGuard, IKeeperCompatible{
    bytes32 public s_keyHash;
    uint256 public s_fee;
    uint256 public s_lastTimeStamp;
    uint256 public s_interval;
    IRetroCats public s_retroCats;
    bool public s_raffleOpen;
    uint256 public s_winAmount;
    address public s_recentWinner;

    event requestedRaffleWinner(bytes32 indexed requestId);

    constructor (address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee, address _retroCats) 
        VRFConsumerBase(_vrfCoordinator, _linkToken)
        {   
            s_lastTimeStamp = block.timestamp;
            s_keyHash = _keyHash;
            s_fee = _fee;
            s_retroCats = IRetroCats(_retroCats);
            s_interval = 4 weeks;
            s_raffleOpen = false;
            // 1 ETH
            s_winAmount = 1000000000000000000;
        }

    function setWinAmount(uint256 _winAmount) public {
        s_winAmount = _winAmount;
    }
    
    function setRaffleOpen(bool _raffleOpen) public onlyOwner {
        s_raffleOpen = _raffleOpen;
    }

    function setInterval(uint256 _interval) public onlyOwner {
        s_interval = _interval;
    }

    receive() external payable {}

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True
     * the following should be true for this to return true:
     * 1. The raffle is open
     * 2. The time interval has passed between raffle runs
     * 3. The contract has LINK
     * 4. The contract has ETH
     */
    function checkUpkeep(bytes memory /* checkData */) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool hasLink = LINK.balanceOf(address(this)) >= s_fee;
        upkeepNeeded = (((block.timestamp - s_lastTimeStamp) > s_interval) && hasLink && s_raffleOpen && (address(this).balance >= s_winAmount));
    }

    // function getStats() public view returns(uint256, uint256, uint256, bool, uint256){
    //     return(block.timestamp, s_lastTimeStamp, s_interval, s_raffleOpen, s_winAmount);
    // }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner
     */
    function performUpkeep(bytes calldata /* performData */) external override{
        require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK");
        require(address(this).balance >= s_winAmount, "Not enough ETH");
        require(s_raffleOpen, "Raffle is not open");
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Upkeep not needed");
        s_lastTimeStamp = block.timestamp;
        bytes32 requestId = requestRandomness(s_keyHash, s_fee);
        emit requestedRaffleWinner(requestId);
    }  

    /**
     * @dev This is the function that Chainlink VRF node calls to send the money to the random winner
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 tokenCount = s_retroCats.s_tokenCounter();
        uint256 randomIndex = randomness % tokenCount;
        address payable winner = payable(s_retroCats.ownerOf(randomIndex));
        s_recentWinner = winner;
        (bool success, ) = winner.call{value: s_winAmount}("");
    }

}
