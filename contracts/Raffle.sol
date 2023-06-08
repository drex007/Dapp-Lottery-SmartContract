//Enter lottery
//Pick a random winner 
//Winner to be selected every x minutes 
//ChainLink Oracles => Randomness, Automated Exceution (ChainLink Keppers)

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "hardhat/console.sol";


error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen(); 
error Raffle__UpKeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
         );

/**@title A sample Raffle Contract
*@author Viktor ojemeni
*@notice Contract for crating untamperable dapp smart contract
*@dev  This implement chainlink vrf v2 and chainlink keepers

 */

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    //Types
    enum RaffleState{
        OPEN,
        CALCULATING
    }


    //State Variables
    uint256  private immutable i_entranceFee;
    address payable [] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordnator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callBackGasLimit; 
    uint32 private constant NUM_WORDS=1;
    uint16 private constant REQUEST_CONFIRMATION = 3;

    

    //Lottery payable
    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamped;
    uint256 private immutable i_interval;




    //Events
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);


    constructor (uint256 entranceFee,address vrfCoordinator, bytes32 gasLane, uint64 subscriptionId, uint32 callBackGasLimit, uint256 interval ) VRFConsumerBaseV2(vrfCoordinator )
    
    
    
    {
    i_entranceFee = entranceFee;  
    i_vrfCoordnator =  VRFCoordinatorV2Interface(vrfCoordinator);
    i_gasLane = gasLane;
    i_subscriptionId = subscriptionId;
    i_callBackGasLimit = callBackGasLimit; 
    s_raffleState = RaffleState.OPEN;
    s_lastTimeStamped = block.timestamp;
    i_interval = interval;


    }

//Functions


    function enterRaffle() public payable{
        if(msg.value < i_entranceFee){revert Raffle__NotEnoughETHEntered();}
        if(s_raffleState != RaffleState.OPEN) {revert Raffle__NotOpen();}
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender) ;
    }
    // This functions tells vrf when to genertaye a random number 
    //1. time interval should have passed
    //2. The loterry should have atleast one player
    //3. Our subscription is funded with Link
    //4. The lottery should be in open state 
     

     // The checkup function is just like stating the conidtions that must be achieved for the performUpKeep to be called
     //The checkUpKeep function returns true, if it returns True, then automatically the performUpkeep function will be called 

    function checkUpKeep(
        bytes memory 
        // checkData
        ) public view override returns(bool upKeepNeeded, bytes memory /*performata  */){
            bool isOpen = (RaffleState.OPEN == s_raffleState);
            bool timePassed = ((block.timestamp - s_lastTimeStamped) > i_interval);
            bool hasPlayers = (s_players.length > 0);
            bool hasBalance =  address(this).balance > 0;
            upKeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);

    }
    //Random  number generator, with gaslimint specificartions and the number to generate

    function performUpKeep(
        bytes calldata /*performData */
    ) external override {
        (bool upKeepNeeded, ) = checkUpKeep(""); // Check if the function returns True 
        if(!upKeepNeeded){revert Raffle__UpKeepNotNeeded(
        address(this).balance,
        s_players.length,
         uint256(s_raffleState)
         );}
        s_raffleState = RaffleState.CALCULATING; // This updates our rafflestate to calcultaing in order not to allow neew user enter the lottery
        uint256 requestId =   i_vrfCoordnator. requestRandomWords(
            i_gasLane,//gasLane
            i_subscriptionId,
            REQUEST_CONFIRMATION  ,
            i_callBackGasLimit,
            NUM_WORDS 
        );
    emit RequestedRaffleWinner(requestId);

    }

    function fulfillRandomWords(
        uint256,
        // ,requestId, 
        
        uint256 [] memory randomWords) internal override {

        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable [](0);
        s_lastTimeStamped = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if(!success){
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);

    }

    //View functions
    function getEntranceFee() public view returns(uint256){
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns(address){
        return s_players[index];
    }
    

    function getRecentWinner() public view returns(address){
        return s_recentWinner;
    }

    function getRaffleState() public view returns(RaffleState){
        return s_raffleState;
    }

    function getNumWords() public view returns(uint256){
        return NUM_WORDS;
    }
   function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATION;
    }



    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamped;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
}


