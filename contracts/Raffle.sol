//Enter lottery
//Pick a random winner 
//Winner to be selected every x minutes 
//ChainLink Oracles => Randomness, Automated Exceution (ChainLink Keppers)

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";



error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();



contract Raffle is VRFConsumerBaseV2{


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
    //Events
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);


    constructor (uint256 entranceFee,address vrfCoordinator, bytes32 gasLane, uint64 subscriptionId, uint32 callBackGasLimit) VRFConsumerBaseV2(vrfCoordinator ){
    i_entranceFee = entranceFee;  
    i_vrfCoordnator =  VRFCoordinatorV2Interface(vrfCoordinator);
    i_gasLane = gasLane;
    i_subscriptionId = subscriptionId;
    i_callBackGasLimit = callBackGasLimit; 


    }

    function enterRaffle() public payable{
        if(msg.value < i_entranceFee){revert Raffle__NotEnoughETHEntered();}
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender) ;
    }

    function checkUpKeep(){
        
    }
    function requestRandomWinner() public {
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

}


