// SPDX-License-Identifier: MIT

// Cuurent contract address polygon: 0x7FAbEBaa16eB899fba6e04fF2d9F6310df5215Fb
pragma solidity ^0.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lotto is Pausable, AccessControl{

    // bytes32 internal _KEY = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    address internal constant _safe = 0xd8806d66E24b702e0A56fb972b75D24CAd656821;
    // address internal _VRF = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;
    // address internal _LINK = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address public winner;
    address[] public Players;

    // uint internal _FEE = 0.0001 * 1e18;
    uint public winningNumber;
    uint Ticket;
    uint startDay;
    uint lotteryPeriod;
    uint claimperiod;

    bool internal _win;

    AggregatorV3Interface internal priceFeed;
    IERC721 LottoTickets;

    bytes32 public constant CEO = keccak256("CEO");
    bytes32 public constant CTO = keccak256("CTO");
    bytes32 public constant CFO = keccak256("CFO");
    
    modifier validate() {
        require(
            hasRole(CEO, msg.sender) ||
                hasRole(CFO, msg.sender) ||
                hasRole(CTO, msg.sender),
            "AccessControl: Address does not have valid Rights"
        );
        _;
    }

    constructor(address _L){
        priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
        LottoTickets = IERC721(_L);
        startDay = 1642420800;
        lotteryPeriod = startDay + 5 days;
        claimperiod = lotteryPeriod + 2 days;
        _win = false;
    }

    // function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    //     winningNumber = randomness;
    // }
    
    function getPrice() public view returns(uint){
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return uint(price);
    }

    function getDollar() public view returns(uint256){
        uint price = getPrice();
        return (uint(1e14) / price) * 1e12; // a dollar in matic
    }

    function getFiveDollar() public view returns(uint256){
        uint price = getPrice();
        return ((uint(1e14) / price) * 1e12)*5; // Five dollar in matic
    }

    function getTenDollar() public view returns(uint256){
        uint price = getPrice();
        return ((uint(1e14) / price) * 1e12)*10; // Ten dollar in matic
    }

    function getPot() public view returns(uint256){
        return address(this).balance;
    }

    function getPotUSD() public view returns(uint256){
        return (address(this).balance) * getPrice();
    }

    function getAnnounceDate() public view returns(uint256){
        return lotteryPeriod + 1;
    }

    function getPlayerCount() public view returns(uint256){
        return Players.length;
    }

    function startLottery(uint _start, uint _duration) public validate {
        startDay = _start;
        lotteryPeriod = startDay + _duration * 1 days;
        claimperiod = lotteryPeriod + 2 days;
    }

    function updateLottery() public validate {
        startLottery(claimperiod, 5);
    }

    function BuyTicket() public payable{
        if(msg.value == getDollar()){
            require(msg.value >= getDollar(), "BTS: Price should be greater than a dollar");
        require(block.timestamp < lotteryPeriod, "Lottery Period Ended: No More buying allowed");
        Players[++Ticket] = msg.sender;
        LottoTickets.safeMint(msg.sender, Ticket);
        }

        else if(msg.value == getFiveDollar()){
            require(msg.value >= getFiveDollar(), "BTS: Price should be greater than 5 dollar");
        require(block.timestamp < lotteryPeriod, "Lottery Period Ended: No More buying allowed");
        uint j=1;
        for(j;j<=5;j+=1){
            Players[++Ticket] = msg.sender;
        LottoTickets.safeMint(msg.sender, Ticket);
        }
        }

        else if(msg.value == getTenDollar()){
            require(msg.value >= getTenDollar(), "BTS: Price should be greater than 10 dollar");
        require(block.timestamp < lotteryPeriod, "Lottery Period Ended: No More buying allowed");
        uint j=1;
        for(j;j<=10;j+=1){
            Players[++Ticket] = msg.sender;
        LottoTickets.safeMint(msg.sender, Ticket);
        }
        }
    }

    // function BuyFiveTicket() public payable{
    //     require(msg.value >= getFiveDollar(), "BTS: Price should be greater than a dollar");
    //     require(block.timestamp < lotteryPeriod, "Lottery Period Ended: No More buying allowed");
    //     uint j=1;
    //     for(j;j<=5;j+=1){
    //         Players[++Ticket] = msg.sender;
    //     LottoTickets.safeMint(msg.sender, Ticket);
    //     }
    // }

    // function BuyTenTicket() public payable{
    //     require(msg.value >= getTenDollar(), "BTS: Price should be greater than a dollar");
    //     require(block.timestamp < lotteryPeriod, "Lottery Period Ended: No More buying allowed");
    //     uint j=1;
    //     for(j;j<=10;j+=1){
    //         Players[++Ticket] = msg.sender;
    //     LottoTickets.safeMint(msg.sender, Ticket);
    //     }
    // }

    function AnnounceLotteryWinner() public validate{
        require(block.timestamp > lotteryPeriod, "Lottery Period Not Ended: No winners yet");
        require(_win == false, "Cannot Announce winner yet");
        winningNumber = uint(blockhash(block.number - 1)) % Players.length;
        winner = Players[winningNumber];
        _win = true;
    }

    function claim() public {
        if(_win == false){
            AnnounceLotteryWinner();
        }

        require(block.timestamp > lotteryPeriod, "Lottery Period: Still buying tickets");
        require(block.timestamp < claimperiod, "Claim Period: Invalid Claim Period");
        require(msg.sender == winner, "Error: You are not the winner");
        
        uint cut = address(this).balance * 5 / 100;
        uint pot = address(this).balance - cut;
        payable(_safe).transfer(cut);
        payable(winner).transfer(pot);
        updateLottery();

        winningNumber = 0;
        winner = address(0);
        _win = false;
    } 
}


interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeMint(address to, uint256 tokenId) external;
    function safeBurn(address to, uint256 tokenId) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function safeTransfer(address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
