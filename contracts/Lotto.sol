// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Lotto is Pausable, AccessControl{
    address internal _safe = 0xd8806d66E24b702e0A56fb972b75D24CAd656821;
    address public winner;
    address[] public Pool;
    uint public PoolAmount;
    bool internal claimed;

    // uint internal _FEE = 0.0001 * 1e18;
    uint public winningNumber;
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
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        LottoTickets = IERC721(_L);
        startDay = 1642420800;
        lotteryPeriod = startDay + 5 days;
        claimperiod = lotteryPeriod + 2 days;
        _win = false;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CEO, msg.sender);
    }
    
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

    function getPot() public view returns(uint256){
        return PoolAmount;
    }

    function getPotUSD() public view returns(uint256){
        return (getPot()) * getPrice();
    }

    function getAnnounceDate() public view returns(uint256){
        return lotteryPeriod + 1 days;
    }

    function getPlayerCount() public view returns(uint256){
        return Pool.length;
    }

    function startLottery(uint _start, uint _duration) public validate {
        resetLottery();
        startDay = _start;
        lotteryPeriod = startDay + _duration * 1 days;
        claimperiod = lotteryPeriod + 2 days;
    }

    function resetLottery() public validate {
        require(block.timestamp > claimperiod, "Cannot reset Lottery before prevoius Claim period end");
        Pool = new address[](0);
        PoolAmount = 0;
        winner = address(0);
    }

    function BuyTicket() public payable{
        require(block.timestamp < lotteryPeriod, "Lottery Period Ended: No More buying allowed");
        uint onedollar = getDollar();
        require(msg.value >= onedollar, "Buy Lottery Ticket: Price should be greater than 1 USD");
        Pool.push(msg.sender); // Pool1 is the 1 USD pool
        LottoTickets.safeMint(msg.sender, (Pool.length * 10) + 1);
        PoolAmount +=  msg.value - gasleft();
    }

    function AnnounceLotteryWinner() public validate{
        require(block.timestamp > lotteryPeriod, "Lottery Period Not Ended: No winners yet");
        require(_win == false, "Cannot Announce winner yet");
        uint winningOne = uint(blockhash(block.number - 1)) % Pool.length;
        winner = Pool[winningOne];
        _win = true;
    }

    function claim() public {
        require(_win == true);
        require(block.timestamp > lotteryPeriod, "Lottery Period: Still buying tickets");
        require(block.timestamp < claimperiod, "Claim Period: Invalid Claim Period");
        require((msg.sender == winner) , "Error: You are not the winner");
        
        uint poolpot = PoolAmount;
        require(claimed == false, "Claim: Prize already Claimed");

        uint cut = poolpot * 5 / 100;
        uint pot = poolpot - cut;

        payable(_safe).transfer(cut);
        payable(winner).transfer(pot);

        claimed = true;
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