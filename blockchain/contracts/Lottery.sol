// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error RoundInactive(uint256);

contract BlazeLottery is Ownable {
    struct RoundInfo {
        uint256 ticketsBought;
        uint256 price;
        uint256 endRound; // Timestamp OR block number when round ends
        uint8[5] winnerNumbers;
        bool active;
    }

    struct UserTickets {
        uint64[] tickets;
        bool[] claimed;
    }

    mapping(uint _roundId => RoundInfo) public roundInfo;
    mapping(address _user => mapping(uint _round => UserTickets _all))
        private userTickets;
    uint256 public currentRound;
    IERC20 public currency;
    bool public roundIsActive;

    event BoughtTickets(address indexed user, uint _round, uint amount);
    event EditRoundPrice(uint _round, uint _newPrice);

    constructor(address _tokenAccepted) {
        // _tokenAccepted is BLZ token
        currency = IERC20(_tokenAccepted);
        //stuff
    }

    function buyTickets(uint64[] calldata tickets) external {
        if (!roundInfo[currentRound].active) revert RoundInactive(currentRound);
        // Check ticket array
        uint256 ticketAmount = tickets.length;
        require(ticketAmount > 0, "InsufficientTickets");
        // Get payment from ticket price
        uint256 price = roundInfo[currentRound].price * ticketAmount;
        if (price > 0) currency.transferFrom(msg.sender, address(this), price);
        // Price Distribution
        // @audit-issue TODO Confirm with client what the token distribution will be
        // @audit-issue TODO Confirm duration of lottery rounds
        // Save Ticket to current Round
        UserTickets storage user = userTickets[msg.sender][currentRound];
        for (uint i = 0; i < ticketAmount; i++) {
            user.tickets.push(tickets[i]);
            user.claimed.push(false);
        }
        emit BoughtTickets(msg.sender, currentRound, ticketAmount);
    }

    function claimTickets(
        uint _round,
        uint[] calldata _userTicketIndexes,
        uint8[] calldata matches
    ) external {}

    function checkTicket(
        uint round,
        uint _userTicketIndex
    ) external view returns (uint) {}

    function checkTickets(
        uint round,
        uint[] calldata _userTicketIndexes
    ) external view returns (uint) {}

    function endRound() external {}

    function getUserTickets(
        address _user,
        uint round
    )
        external
        view
        returns (
            uint64[] memory _userTickets,
            bool[] memory claimed,
            uint tickets
        )
    {
        UserTickets storage user = userTickets[_user][round];
        tickets = user.tickets.length;
        _userTickets = new uint64[](tickets);
        claimed = new bool[](tickets);
        for (uint i = 0; i < tickets; i++) {
            _userTickets[i] = user.tickets[i];
            claimed[i] = user.claimed[i];
        }
    }

    function setPrice(uint256 _newPrice, uint256 _roundId) external onlyOwner {
        require(_roundId > currentRound, "Invalid ID");
        roundInfo[_roundId].price = _newPrice;
        emit EditRoundPrice(_roundId, _newPrice);
    }

    function activateLottery(uint initPrice) external onlyOwner {
        require(currentRound == 0, "Lottery started");
        currentRound++;
        RoundInfo storage startRound = roundInfo[1];
        startRound.price = initPrice;
        startRound.active = true;
        // TODO please CHECK the DURATION of each lottery round;
        startRound.endRound = block.timestamp + 12 hours;
    }

    // function checkRoundPrice(uint256 _roundId) external view returns (uint256) {
    //     require(_roundId >= 0, "Invalid Round ID");
    //     return roundInfo[_roundId].price;
    // }
}
