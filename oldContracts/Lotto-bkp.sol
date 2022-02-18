// SPDX-License-Identifier: MIT

// Cuurent contract address polygon: 0x7FAbEBaa16eB899fba6e04fF2d9F6310df5215Fb
pragma solidity ^0.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lotto is Pausable, AccessControl{

    // bytes32 internal _KEY = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    address internal constant _safe = 0xd8806d66E24b702e0A56fb972b75D24CAd656821;
    // address internal _VRF = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;
    // address internal _LINK = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address[] public winners;
    address[] public Pool1;
    address[] public Pool5;
    address[] public Pool10;
    uint[3] public PoolAmounts;
    bool[3] internal claimed;

    // uint internal _FEE = 0.0001 * 1e18;
    uint public winningNumber;
    uint startDay;
    uint lotteryPeriod;
    uint claimperiod = 0;

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

    function getPot(uint _pool) public view returns(uint256){
        if(_pool == 1) return PoolAmounts[0];
        else if(_pool == 5) return PoolAmounts[1];
        else if(_pool == 10) return PoolAmounts[2];
        else return 0;
    }

    function getPotUSD(uint _pool) public view returns(uint256){
        return (getPot(_pool)) * getPrice();
    }

    function getAnnounceDate() public view returns(uint256){
        return lotteryPeriod + 1;
    }

    function getPlayerCount(uint _pool) public view returns(uint256){
        if(_pool == 1){
            return Pool1.length;
        }else if(_pool == 5){
            return Pool5.length;
        }else if(_pool == 10){
            return Pool10.length;
        }else return 0;
    }

    function getTotalPlayerCount() public view returns(uint256){
        return Pool1.length + Pool5.length + Pool10.length;
    }

    function startLottery(uint _start, uint _duration) public validate {
        resetLottery();
        startDay = _start;
        lotteryPeriod = startDay + _duration * 1 days;
        claimperiod = lotteryPeriod + 2 days;
    }

    function resetLottery() public validate {
        // startLottery(claimperiod, 5);
        require(block.timestamp > claimperiod, "Cannot reset Lottery before prevoius Claim period end");
        Pool1 = [address(0)];
        Pool5 = [address(0)];
        Pool10 = [address(0)];
        PoolAmounts = [0,0,0];
        winners = [address(0)];
    }

    function BuyOneTicket() public payable{
        require(block.timestamp < lotteryPeriod, "Lottery Period Ended: No More buying allowed");
        uint onedollar = getDollar();
        require(msg.value >= onedollar, "Buy Lottery Ticket: Price should be greater than 1 USD");
        Pool1.push(msg.sender); // Pool1 is the 1 USD pool
        LottoTickets.safeMint(msg.sender, (Pool1.length * 10) + 0);
        PoolAmounts[0] = PoolAmounts[0] + msg.value - gasleft();
    }

    function BuyFiveTicket() public payable{
        require(block.timestamp < lotteryPeriod, "Lottery Period Ended: No More buying allowed");
        uint onedollar = getDollar();
        require(msg.value >= (onedollar * 5), "Buy Lottery Ticket: Price should be greater than 5 USD");
        Pool5.push(msg.sender); // Pool5 is the 5 USD pool
        LottoTickets.safeMint(msg.sender, (Pool5.length * 10) + 1);
        PoolAmounts[1] = PoolAmounts[1] + msg.value - gasleft();
    }

    function BuyTenTicket() public payable{
        require(block.timestamp < lotteryPeriod, "Lottery Period Ended: No More buying allowed");
        uint onedollar = getDollar();
        require(msg.value >= (onedollar * 10), "Buy Lottery Ticket: Price should be greater than 10 USD");
        Pool10.push(msg.sender); // Pool10 is the 10 USD pool
        LottoTickets.safeMint(msg.sender, (Pool10.length * 10) + 2);
        PoolAmounts[2] = PoolAmounts[2] + msg.value - gasleft();
    }

    function AnnounceLotteryWinner() public validate{
        require(block.timestamp > lotteryPeriod, "Lottery Period Not Ended: No winners yet");
        require(_win == false, "Cannot Announce winner yet");
        // winningNumber = uint(blockhash(block.number - 1)) % Players.length;

        uint winningOne = uint(blockhash(block.number - 1)) % Pool1.length;
        uint winningFive = uint(blockhash(block.number - 1)) % Pool5.length;
        uint winningTen = uint(blockhash(block.number - 1)) % Pool10.length;
        winners.push(Pool1[winningOne]);
        winners.push(Pool5[winningFive]);
        winners.push(Pool10[winningTen]);
        _win = true;
    }

    function claim() public {
        if(_win == false){
            AnnounceLotteryWinner();
        }

        require(block.timestamp > lotteryPeriod, "Lottery Period: Still buying tickets");
        require(block.timestamp < claimperiod, "Claim Period: Invalid Claim Period");
        // require(msg.sender == winner, "Error: You are not the winner");
        require((msg.sender == winners[0]) || (msg.sender == winners[1]) || (msg.sender == winners[2]), "Error: You are not the winner");
        
        uint winnerpot;
        if(winners[0] == msg.sender){winnerpot = 0;} // 1 USD Pot
        else if(winners[1] == msg.sender){winnerpot = 1;}  // 5 USD Pot
        else if(winners[2] == msg.sender){winnerpot = 2;}  // 10 USD Pot

        uint poolpot = PoolAmounts[winnerpot];
        require(claimed[winnerpot] == false, "Claim: Prize already Claimed");

        uint cut = poolpot * 5 / 100;
        uint pot = poolpot - cut;

        payable(_safe).transfer(cut);
        payable(winners[winnerpot]).transfer(pot);

        claimed[winnerpot] = true;
        // _win = false;
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