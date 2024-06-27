// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title   BlazeLottery
 * @author  SemiInvader
 * @notice  This contract is a lottery contract that will be used to distribute BLZ tokens to users
 *          The lottery will be a 5/63 lottery, where users will buy tickets with 5 numbers each spanning 8 bits in length
 *          The lottery will be run on a weekly basis, with the lottery ending on a specific time and date
 * @dev IMPORTANT DEPENDENCIES:
 *      - Chainlink VRF ConsumerBase -> Request randomness for winner number
 *      - Chainlink VRF Coordinator (Interface only) -> receive randomness from this one
 *      - Chainlink Keepers Implementation -> Once winner is received, check all tickets for matches and return count of matches back to contract to save that particular data
 *      - Chainlink Keeper Implementation 2 -> request randomness for next round
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswap.sol";

//-------------------------------------------------------------------------
//    INTERFACES
//-------------------------------------------------------------------------
interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}
//-------------------------------------------------------------------------
//    ERRORS
//-------------------------------------------------------------------------
error BlazeLot__RoundInactive(uint256);
error BlazeLot__InsufficientTickets();
error BlazeLot__InvalidMatchers();
error BlazeLot__InvalidMatchRound();
error BlazeLot__InvalidUpkeeper();
error BlazeLot__InvalidRoundEndConditions();
error BlazeLot__InvalidRound();
error BlazeLot__TransferFailed();
error BlazeLot__InvalidClaim();
error BlazeLot__DuplicateTicketIdClaim(uint _round, uint _ticketIndex);
error BlazeLot__InvalidClaimMatch(uint ticketIndex);
error BlazeLot__InvalidDistribution(uint totalDistribution);
error BlazeLot__InvalidToken();
error BlazeLot__InvalidETHAmount();
error BlazeLot__InvalidCurrencyClaim();
error BlazeLot__InvalidTokenPair();

contract BlazeLottery is
    Ownable,
    ReentrancyGuard,
    AutomationCompatible,
    VRFConsumerBaseV2
{
    //-------------------------------------------------------------------------
    //    TYPE DECLARATIONS
    //-------------------------------------------------------------------------
    struct RoundInfo {
        uint256[5] distribution; // This is the total pot distributed to each item - NOT the percentages
        uint256 pot;
        uint256 ticketsBought;
        uint256 price;
        uint256 endRound; // Timestamp OR block number when round ends
        uint256 randomnessRequestID;
        bool active;
    }
    struct UserTickets {
        uint64[] tickets;
        bool[] claimed;
    }
    struct Matches {
        uint256 match1;
        uint256 match2;
        uint256 match3;
        uint256 match4;
        uint256 match5;
        uint256 roundId;
        uint64 winnerNumber; // We'll need to process this so it matches the same format as the tickets
        bool completed;
    }
    struct AcceptedTokens {
        uint price;
        uint match3;
        uint match4;
        uint match5;
        uint dev;
        uint burn;
        address v2Pair;
        bool accepted;
    }
    //-------------------------------------------------------------------------
    //    State Variables
    //-------------------------------------------------------------------------
    // kept for coverage purposes
    // mapping(address => bool ) public upkeeper;
    // mapping(uint  => Matches ) public matches;
    // mapping(uint => RoundInfo) public roundInfo;
    // mapping(uint => address[]) private roundUsers;
    // mapping(address  => mapping(uint => UserTickets))
    //     private userTickets;
    // We will accept BLZE, ETH, SHIB, and USDC
    mapping(address _token => AcceptedTokens _acceptedTokens)
        public acceptedTokens;

    mapping(address _upkeep => bool _enabled) public upkeeper;
    mapping(uint _randomnessRequestID => Matches _winnerMatches) public matches;
    mapping(uint _roundId => RoundInfo) public roundInfo;
    mapping(uint _roundId => address[] participatingUsers) private roundUsers;
    mapping(address _user => mapping(uint _round => UserTickets _all))
        private userTickets;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant SHIB = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
    IUniswapV2Pair private mainPair =
        IUniswapV2Pair(0x6BfCDA57Eff355A1BfFb76c584Fea20188B12166);
    address private immutable OTCWallet;

    uint[5] public distributionPercentages; // This percentage allocates to the different distribution amounts per ROUND
    // [match1, match2, match3, match4, match5, burn, team]
    // 25% Match 5
    // 25% Match 4
    // 25% Match 3
    // 0% Match 2 (ommited)
    // 0% Match 1 (ommited)
    // 20% Burns
    // 5%  Team
    address public constant DEAD_WALLET =
        0x000000000000000000000000000000000000dEaD;
    address public burnWallet;
    //-------------------------------------------------------------------------
    //    VRF Config Variables
    //-------------------------------------------------------------------------
    address public immutable vrfCoordinator;
    bytes32 public immutable keyHash;
    uint64 private immutable subscriptionId;
    uint16 private constant minimumRequestConfirmations = 4;
    uint32 private callbackGasLimit = 100000;

    address public teamWallet;

    IERC20Burnable public currency;
    uint256 public currentRound;
    uint256 public roundDuration;
    uint256 public constant PERCENTAGE_BASE = 100;
    uint64 public constant BIT_8_MASK = 0x00000000000000FF;
    uint64 public constant BIT_6_MASK = 0x000000000000003F;
    uint8 public constant BIT_1_MASK = 0x01;

    //-------------------------------------------------------------------------
    //    Events
    //-------------------------------------------------------------------------
    event AddToPot(address indexed user, uint256 indexed round, uint256 amount);
    event BoughtTickets(address indexed user, uint _round, uint amount);
    event EditRoundPrice(uint _round, uint _newPrice);
    event RolloverPot(uint _round, uint _newPot);
    event RoundEnded(uint indexed _round);
    event StartRound(uint indexed _round);
    event UpkeeperSet(address indexed upkeeper, bool isUpkeeper);
    event RewardClaimed(address indexed _user, uint rewardAmount);
    event RoundDurationSet(uint _oldDuration, uint _newDuration);
    event TransferFailed(address _to, uint _amount);
    event AltDistributionChanged(
        address _token,
        uint m3,
        uint m4,
        uint m5,
        uint dev,
        uint burn
    );
    event AltAcceptanceChanged(address indexed _token, bool status);
    event EditAltPrice(address _token, uint _newPrice);

    //-------------------------------------------------------------------------
    //    Modifiers
    //-------------------------------------------------------------------------
    modifier onlyUpkeeper() {
        if (!upkeeper[msg.sender]) revert BlazeLot__InvalidUpkeeper();
        _;
    }

    modifier activeRound() {
        RoundInfo storage playingRound = roundInfo[currentRound];
        if (!playingRound.active || block.timestamp > playingRound.endRound)
            revert BlazeLot__RoundInactive(currentRound);
        _;
    }

    //-------------------------------------------------------------------------
    //    Constructor
    //-------------------------------------------------------------------------
    constructor(
        address _tokenAccepted,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        address _team,
        address _burnWallet,
        address _otcWallet
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        burnWallet = _burnWallet;
        // _tokenAccepted is BLZ token
        currency = IERC20Burnable(_tokenAccepted);

        roundDuration = 1 weeks;
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;

        distributionPercentages = [25, 25, 25, 20, 5];
        teamWallet = _team;
        acceptedTokens[SHIB] = AcceptedTokens({
            price: 120_000 ether,
            match3: 25,
            match4: 25,
            match5: 25,
            dev: 5,
            burn: 20,
            v2Pair: 0x811beEd0119b4AfCE20D2583EB608C6F7AF1954f,
            accepted: true
        });
        acceptedTokens[address(0)] = AcceptedTokens({
            price: 0.0006 ether,
            match3: 25,
            match4: 25,
            match5: 25,
            dev: 5,
            burn: 20,
            v2Pair: address(0),
            accepted: true
        });
        OTCWallet = _otcWallet;
    }

    //-------------------------------------------------------------------------
    //    EXTERNAL Functions
    //-------------------------------------------------------------------------
    /**
     * @notice Buy tickets with ALT tokens or ETH
     * @param tickets Array of tickets to buy. The tickets need to have 5 numbers each spanning 8 bits in length
     * @param token Address of the token to use to buy tickets
     * @dev BLZE buys not accepted here
     */
    function buyTicketsWithAltTokens(
        uint64[] calldata tickets,
        address token
    ) external payable nonReentrant activeRound {
        AcceptedTokens storage altToken = acceptedTokens[token];
        // Make sure token is approved token
        if (!altToken.accepted) revert BlazeLot__InvalidToken();
        uint price = altToken.price * tickets.length;
        uint toBurn = (price * altToken.burn) / PERCENTAGE_BASE;
        uint devAmount = (price * altToken.dev) / PERCENTAGE_BASE;
        uint toPot = price - toBurn - devAmount;
        // if token = address(0) then we're using ETH
        if (token == address(0)) {
            if (msg.value < price) revert BlazeLot__InvalidETHAmount();
            // Send ETH to burn wallet
            (bool succ, ) = payable(burnWallet).call{value: toBurn}("");
            if (!succ) emit TransferFailed(burnWallet, toBurn);
            (succ, ) = payable(teamWallet).call{value: devAmount}("");
            if (!succ) emit TransferFailed(teamWallet, devAmount);
            (uint reserve0, uint reserve1, ) = mainPair.getReserves();
            uint toBuy = (toPot * reserve0) / reserve1;
            // Buy BLZE from OTC wallet
            currency.transferFrom(OTCWallet, address(this), toBuy);
            (succ, ) = payable(OTCWallet).call{value: toPot}("");
            if (!succ) emit TransferFailed(OTCWallet, toPot);
            uint[] memory dist = new uint[](5);
            dist[0] = altToken.match3;
            dist[1] = altToken.match4;
            dist[2] = altToken.match5;
            dist[3] = 0;
            dist[4] = 0;
            _addToPot(toBuy, currentRound, dist);
        } else {
            // Send token to burn wallet
            IERC20(token).transferFrom(msg.sender, burnWallet, toBurn);
            IERC20(token).transferFrom(msg.sender, teamWallet, devAmount);
            IERC20(token).transferFrom(msg.sender, OTCWallet, toPot);
            // Buy BLZE from OTC wallet
            // get token to ETH price using v2Pair
            (uint reserve0, uint reserve1, ) = IUniswapV2Pair(altToken.v2Pair)
                .getReserves();
            address token0 = IUniswapV2Pair(altToken.v2Pair).token0();
            uint toBuy = 0;
            if (token0 == WETH) toBuy = (reserve0 * toPot) / reserve1;
            else toBuy = (reserve1 * toPot) / reserve0;

            (reserve0, reserve1, ) = mainPair.getReserves();

            toBuy = (toBuy * reserve0) / reserve1;

            currency.transferFrom(OTCWallet, address(this), toBuy);
            uint[] memory dist = new uint[](5);
            dist[0] = altToken.match3;
            dist[1] = altToken.match4;
            dist[2] = altToken.match5;
            dist[3] = 0;
            dist[4] = 0;
            _addToPot(toBuy, currentRound, dist);
        }
        // Buy Tickets
        _buyTickets(tickets, 0, msg.sender);
    }

    /**
     *
     * @param tickets Array of tickets to buy. The tickets need to have 5 numbers each spanning 8 bits in length
     * @dev each number will be constrained to 6 bit numbers e.g. 0 - 63
     * @dev since each number is 6 bits in length but stored on an 8 bit space, we'll be using uint64 to store the numbers
     *      E.G.
     *      Storing the ticket with numbers 35, 12, 0, 63, 1
     *      each number in 8 bit hex becomes 0x23, 0x0C, 0x00, 0x3F, 0x01
     *      number to store = 0x000000230C003F01
     *      Although we will not check for this, the numbers will be be checked using bit shifting with a mask so any larger numbers will be ignored
     * @dev gas cost is reduced ludicrously, however we will be relying heavily on chainlink keepers to check for winners and get the match amount data
     */
    function buyTickets(
        uint64[] calldata tickets
    ) external nonReentrant activeRound {
        RoundInfo storage playingRound = roundInfo[currentRound];
        uint potAmount = playingRound.price * tickets.length;
        currency.transferFrom(msg.sender, address(this), potAmount);
        _buyTickets(tickets, potAmount, msg.sender);
    }

    /**
     *
     * @param _round round to claim tickets from
     * @param _userTicketIndexes Indexes / IDs of the tickets to claim
     * @param _matches matching number of the ticket/id to claim
     */
    function claimTickets(
        uint _round,
        uint[] calldata _userTicketIndexes,
        uint8[] calldata _matches
    ) public nonReentrant {
        uint toReward = _claimTickets(_round, _userTicketIndexes, _matches);
        if (toReward > 0) currency.transfer(msg.sender, toReward);
        emit RewardClaimed(msg.sender, toReward);
    }

    /**
     *
     * @param _rounds array of all rounds that will be claimed
     * @param _ticketsPerRound number of tickets that will be claimed in this call
     * @param _ticketIndexes array of ticket indexes to be claimed, the length of this array should be equal to the sum of _ticketsPerRound
     * @param _matches array to matches per ticket, the length of this array should be equal to the sum of _ticketsPerRound
     */
    function claimMultipleRounds(
        uint[] calldata _rounds,
        uint[] calldata _ticketsPerRound,
        uint[] calldata _ticketIndexes,
        uint8[] calldata _matches
    ) external nonReentrant {
        if (
            _rounds.length != _ticketsPerRound.length ||
            _rounds.length == 0 ||
            _ticketIndexes.length != _matches.length ||
            _ticketIndexes.length == 0
        ) revert BlazeLot__InvalidClaim();
        uint ticketOffset;
        uint rewards;
        for (uint i = 0; i < _rounds.length; i++) {
            uint round = _rounds[i];
            uint endOffset = _ticketsPerRound[i] - 1;
            uint[] memory tickets = _ticketIndexes[ticketOffset:ticketOffset +
                endOffset];
            uint8[] memory allegedMatch = _matches[ticketOffset:ticketOffset +
                endOffset];

            rewards += _claimTickets(round, tickets, allegedMatch);
            ticketOffset += _ticketsPerRound[i];
        }
        if (rewards > 0) currency.transfer(msg.sender, rewards);
        emit RewardClaimed(msg.sender, rewards);
    }

    /**
     * @notice Edit the price for an upcoming round
     * @param _newPrice Price for the next upcoming round
     * @param _roundId ID of the upcoming round to edit
     * @dev If this is not called, on round end, the price will be the same as the previous round
     */
    function setCurrencyPrice(
        uint256 _newPrice,
        uint256 _roundId
    ) external onlyOwner {
        require(_roundId > currentRound, "Invalid ID");
        roundInfo[_roundId].price = _newPrice;
        emit EditRoundPrice(_roundId, _newPrice);
    }

    function setAltPrice(uint _newPrice, address _token) external onlyOwner {
        AcceptedTokens storage altToken = acceptedTokens[_token];
        altToken.price = _newPrice;
        emit EditAltPrice(_token, _newPrice);
    }

    function setAltDistribution(
        uint m3,
        uint m4,
        uint m5,
        uint dev,
        uint burn,
        address _token,
        address tokenV2Pair
    ) external onlyOwner {
        AcceptedTokens storage altToken = acceptedTokens[_token];
        uint totalDistribution = m3 + m4 + m5 + dev + burn;
        if (totalDistribution != PERCENTAGE_BASE)
            revert BlazeLot__InvalidDistribution(totalDistribution);
        address token0 = IUniswapV2Pair(tokenV2Pair).token0();
        address token1 = IUniswapV2Pair(tokenV2Pair).token1();
        if (
            (token0 != _token && token1 != _token) ||
            (token0 != WETH && token1 != WETH)
        ) revert BlazeLot__InvalidTokenPair();
        altToken.v2Pair = tokenV2Pair;
        altToken.match3 = m3;
        altToken.match4 = m4;
        altToken.match5 = m5;
        altToken.dev = dev;
        altToken.burn = burn;
        emit AltDistributionChanged(_token, m3, m4, m5, dev, burn);
    }

    function acceptAlt(address _token, bool status) external onlyOwner {
        acceptedTokens[_token].accepted = status;
        emit AltAcceptanceChanged(_token, status);
    }

    /**
     *
     * @param initPrice Price for the first round
     * @param firstRoundEnd the Time when the first round ends
     * @dev This function can only be called once by owner and sets the initial price
     */
    function activateLottery(
        uint initPrice,
        uint firstRoundEnd
    ) external onlyOwner {
        require(currentRound == 0, "Lottery started");
        currentRound++;
        RoundInfo storage startRound = roundInfo[1];
        startRound.price = initPrice;
        startRound.active = true;
        startRound.endRound = firstRoundEnd;
        emit StartRound(1);
    }

    /**
     * @param _upkeeper Address of the upkeeper
     * @param _status Status of the upkeeper
     * @dev enable or disable an address that can call performUpkeep
     */
    function setUpkeeper(address _upkeeper, bool _status) external onlyOwner {
        upkeeper[_upkeeper] = _status;
        emit UpkeeperSet(_upkeeper, _status);
    }

    /**
     *
     * @param performData Data to perform upkeep
     * @dev performData is abi encoded as (bool, uint256[])
     *      - bool is if it's a round end request upkeep or winner array request upkeep
     *      - uint256[] is the array of winners that match the criteria
     */
    function performUpkeep(bytes calldata performData) external onlyUpkeeper {
        //Only upkeepers can do this
        if (!upkeeper[msg.sender]) revert BlazeLot__InvalidUpkeeper();

        (bool isRandomRequest, uint256[] memory matchers) = abi.decode(
            performData,
            (bool, uint256[])
        );
        RoundInfo storage playingRound = roundInfo[currentRound];
        if (isRandomRequest) {
            endRound();
        } else {
            if (matchers.length != 5 || playingRound.active)
                revert BlazeLot__InvalidMatchers();
            Matches storage currentMatches = matches[
                playingRound.randomnessRequestID
            ];
            if (currentMatches.winnerNumber == 0 || currentMatches.completed)
                revert BlazeLot__InvalidMatchRound();
            currentMatches.match1 = matchers[0];
            currentMatches.match2 = matchers[1];
            currentMatches.match3 = matchers[2];
            currentMatches.match4 = matchers[3];
            currentMatches.match5 = matchers[4];
            currentMatches.completed = true;
            rolloverAmount(currentRound, currentMatches);
            newRound(playingRound);
        }
    }

    function setRoundDuration(uint256 _newDuration) external onlyOwner {
        emit RoundDurationSet(roundDuration, _newDuration);
        roundDuration = _newDuration;
    }

    function claimNonPrizeTokens(address _token) external onlyOwner {
        if (_token == address(currency))
            revert BlazeLot__InvalidCurrencyClaim();
        if (_token == address(0)) {
            (bool succ, ) = payable(owner()).call{value: address(this).balance}(
                ""
            );
            if (!succ) emit TransferFailed(owner(), address(this).balance);
        } else {
            IERC20 token = IERC20(_token);
            token.transfer(owner(), token.balanceOf(address(this)));
        }
    }

    function addToPot(
        uint amount,
        uint round,
        uint[] memory customDistribution
    ) external {
        currency.transferFrom(msg.sender, address(this), amount);
        _addToPot(amount, round, customDistribution);
    }

    //-------------------------------------------------------------------------
    //    PUBLIC FUNCTIONS
    //-------------------------------------------------------------------------

    /**
     * @notice End the current round
     * @dev this function can be called by anyone as long as the conditions to end the round are met
     */
    function endRound() public {
        RoundInfo storage playingRound = roundInfo[currentRound];
        // Check that endRound of current Round is passed
        if (
            block.timestamp > playingRound.endRound &&
            playingRound.active &&
            playingRound.randomnessRequestID == 0
        ) {
            playingRound.active = false;
            emit RoundEnded(currentRound);
            if (playingRound.ticketsBought == 0) {
                rolloverAmount(currentRound, matches[0]);
                newRound(playingRound);
            } else {
                uint requestId = VRFCoordinatorV2Interface(vrfCoordinator)
                    .requestRandomWords(
                        keyHash,
                        subscriptionId,
                        minimumRequestConfirmations,
                        callbackGasLimit,
                        1
                    );
                playingRound.randomnessRequestID = requestId;
                matches[requestId].roundId = currentRound;
            }
        } else revert BlazeLot__InvalidRoundEndConditions();
    }

    //-------------------------------------------------------------------------
    //    INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------
    /**
     * @notice Add Blaze to the POT of the selected round
     * @param amount Amount of Blaze to add to the pot
     * @param round Round to add the Blaze to
     * @param customDistribution Distribution of the funds into the pot
        // 25% Match 3   0
        // 25% Match 4   1
        // 25% Match 5   2
        // 20% Burns     3
        // 5%  Team      4
     */
    function _addToPot(
        uint amount,
        uint round,
        uint[] memory customDistribution
    ) internal {
        if (round < currentRound || round == 0) revert BlazeLot__InvalidRound();
        uint distributionLength = customDistribution.length;
        uint totalPercentage = PERCENTAGE_BASE;
        if (distributionLength == 0 || distributionLength != 5) {
            customDistribution = new uint[](5);
            customDistribution[0] = distributionPercentages[0];
            customDistribution[1] = distributionPercentages[1];
            customDistribution[2] = distributionPercentages[2];
            customDistribution[3] = distributionPercentages[3];
            customDistribution[4] = distributionPercentages[4];
        } else {
            for (uint i = 0; i < 5; i++) {
                totalPercentage += customDistribution[i];
            }
            totalPercentage -= PERCENTAGE_BASE;
        }
        RoundInfo storage playingRound = roundInfo[round];
        for (uint i = 0; i < 5; i++) {
            playingRound.distribution[i] +=
                (customDistribution[i] * amount) /
                totalPercentage;
        }

        playingRound.pot += amount;

        emit AddToPot(msg.sender, amount, round);
    }

    function fulfillRandomWords(
        uint requestId,
        uint256[] memory randomWords
    ) internal override {
        uint64 winnerNumber = uint64(randomWords[0]);
        uint64 addedMask = 0;
        for (uint8 i = 0; i < 5; i++) {
            uint64 currentNumber = (winnerNumber >> (8 * i)) & BIT_6_MASK;
            if (i == 0) {
                addedMask += currentNumber;
                continue;
            }
            for (uint8 j = 1; j < i + 1; j++) {
                if (
                    currentNumber == ((addedMask >> (8 * (j - 1))) & BIT_6_MASK)
                ) {
                    currentNumber++;
                    j = 0;
                    continue;
                }
            }
            // pass a 6 bit mask to get the last 6 bits of each number
            addedMask += (currentNumber & BIT_6_MASK) << (8 * i);
        }
        if (addedMask == 0) addedMask = uint64(1);
        matches[requestId].winnerNumber = addedMask;
    }

    function _claimTickets(
        uint _round,
        uint[] memory _userTicketIndexes,
        uint8[] memory _matches
    ) internal returns (uint) {
        if (_round >= currentRound) revert BlazeLot__InvalidRound();
        if (
            _userTicketIndexes.length != _matches.length ||
            _userTicketIndexes.length == 0
        ) revert BlazeLot__InvalidClaim();
        RoundInfo storage round = roundInfo[_round];

        UserTickets storage user = userTickets[msg.sender][_round];
        if (user.tickets.length < _userTicketIndexes.length)
            revert BlazeLot__InvalidClaim();

        Matches storage roundMatches = matches[round.randomnessRequestID];
        uint toReward;

        // Cycle through all tickets to claim
        for (uint i = 0; i < _userTicketIndexes.length; i++) {
            uint ticketIndex = _userTicketIndexes[i];
            // index is checked and if out of bounds, will revert
            if (_matches[i] < 3 || _matches[i] > 5)
                revert BlazeLot__InvalidClaimMatch(i);

            if (user.claimed[ticketIndex])
                revert BlazeLot__DuplicateTicketIdClaim(_round, ticketIndex);

            uint64 ticket = user.tickets[ticketIndex];

            if (
                _compareTickets(roundMatches.winnerNumber, ticket) ==
                _matches[i]
            ) {
                uint totalMatches = getTotalMatches(roundMatches, _matches[i]);

                user.claimed[ticketIndex] = true;

                uint256 matchReward = round.distribution[_matches[i] - 3] /
                    totalMatches;
                toReward += matchReward;
            } else {
                revert BlazeLot__InvalidClaimMatch(i);
            }
        }
        return toReward;
    }

    //-------------------------------------------------------------------------
    //    PRIVATE FUNCTIONS
    //-------------------------------------------------------------------------

    function _buyTickets(
        uint64[] calldata tickets,
        uint256 potAmount,
        address _user
    ) private {
        RoundInfo storage playingRound = roundInfo[currentRound];
        if (!playingRound.active || block.timestamp > playingRound.endRound)
            revert BlazeLot__RoundInactive(currentRound);
        // Check ticket array
        uint256 ticketAmount = tickets.length;
        if (ticketAmount == 0) {
            revert BlazeLot__InsufficientTickets();
        }

        uint[] memory dist = new uint[](1);
        if (potAmount > 0) _addToPot(potAmount, currentRound, dist);

        playingRound.ticketsBought += ticketAmount;
        // Save Ticket to current Round
        UserTickets storage user = userTickets[_user][currentRound];
        // Add user to the list of users to check for winners
        if (user.tickets.length == 0) roundUsers[currentRound].push(_user);

        for (uint i = 0; i < ticketAmount; i++) {
            user.tickets.push(tickets[i]);
            user.claimed.push(false);
        }
        emit BoughtTickets(_user, currentRound, ticketAmount);
    }

    function rolloverAmount(uint round, Matches storage matchInfo) private {
        RoundInfo storage playingRound = roundInfo[round];
        RoundInfo storage nextRound = roundInfo[round + 1];

        uint nextPot = 0;
        if (playingRound.pot == 0) return;
        // Check amount of winners of each match type and their distribution percentages
        // if (matchInfo.match1 == 0 && playingRound.distribution[0] > 0)
        //     nextPot += (currentPot * playingRound.distribution[0]) / 100;
        // if (matchInfo.match2 == 0 && playingRound.distribution[1] > 0)
        //     nextPot += (currentPot * playingRound.distribution[1]) / 100;
        if (matchInfo.match3 == 0) {
            nextPot += playingRound.distribution[0];
            nextRound.distribution[0] = playingRound.distribution[0];
        }
        if (matchInfo.match4 == 0) {
            nextPot += playingRound.distribution[1];
            nextRound.distribution[1] = playingRound.distribution[1];
        }
        if (matchInfo.match5 == 0) {
            nextPot += playingRound.distribution[2];
            nextRound.distribution[2] = playingRound.distribution[2];
        }
        // BURN the Currency Amount
        uint burnAmount = playingRound.distribution[3];
        // Send the appropriate percent to the team wallet
        uint teamPot = playingRound.distribution[4];
        if (burnAmount > 0) currency.transfer(burnWallet, burnAmount);
        if (teamPot > 0) {
            bool succ = currency.transfer(teamWallet, teamPot);
            if (!succ) revert BlazeLot__TransferFailed();
        }
        nextRound.pot += nextPot;
        emit RolloverPot(round, nextPot);
    }

    function newRound(RoundInfo storage playingRound) private {
        currentRound++;
        roundInfo[currentRound].active = true;
        roundInfo[currentRound].endRound =
            playingRound.endRound +
            roundDuration;
        if (roundInfo[currentRound].price == 0)
            roundInfo[currentRound].price = playingRound.price;
    }

    function getTotalMatches(
        Matches storage winners,
        uint8 matched
    ) private view returns (uint) {
        if (matched == 1) return winners.match1;
        if (matched == 2) return winners.match2;
        if (matched == 3) return winners.match3;
        if (matched == 4) return winners.match4;
        if (matched == 5) return winners.match5;
        return 0;
    }

    //-------------------------------------------------------------------------
    //    INTERNAL & PRIVATE VIEW & PURE FUNCTIONS
    //-------------------------------------------------------------------------
    /**
     *
     * @param winnerNumber Base Number to check against
     * @param ticketNumber Number to check against the base number
     * @return matchAmount Number of matches between the two numbers
     */
    function _compareTickets(
        uint64 winnerNumber,
        uint64 ticketNumber
    ) private pure returns (uint8 matchAmount) {
        uint64 winnerMask;
        uint64 ticketMask;
        uint8 matchesChecked = 0x00;

        // cycle through all 5 numbers on winnerNumber
        for (uint8 i = 0; i < 5; i++) {
            winnerMask = (winnerNumber >> (8 * i)) & BIT_6_MASK;
            // cycle through all 5 numbers on ticketNumber
            for (uint8 j = 0; j < 5; j++) {
                // check if this ticket Mask has already been matched
                uint8 maskCheck = BIT_1_MASK << j;
                if (matchesChecked & maskCheck == maskCheck) {
                    continue;
                }
                ticketMask = (ticketNumber >> (8 * j)) & BIT_8_MASK;
                // If number is larger than 6 bits, ignore
                if (ticketMask > BIT_6_MASK) {
                    matchesChecked = matchesChecked | maskCheck;
                    continue;
                }

                if (winnerMask == ticketMask) {
                    matchAmount++;
                    matchesChecked = matchesChecked | maskCheck;
                    break;
                }
            }
        }
    }

    //-------------------------------------------------------------------------
    //    EXTERNAL AND PUBLIC VIEW & PURE FUNCTIONS
    //-------------------------------------------------------------------------
    /**
     * @notice Check if upkeep is needed
     * @param checkData Data to check for upkeep
     * @return upkeepNeeded Whether upkeep is needed
     * @return performData Data to perform upkeep
     *          - We use two types of upkeeps here. 1 Time , 2 Custom logic
     *          - 1. Time based upkeep is used to end the round and request for randomness
     *          - 2. Custom logic is used to check for winners
     *          - performData has 2 values, endRoundRequest (bool) and matching numbers (uint[])
     *           if endRoundRequest is true, then we will end the round and request for randomness
     *          if matching numbers is not empty, then we will check for winners
     *          after winners are selected we increase the round number and activate it
     */
    function checkUpkeep(
        bytes calldata checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        checkData; // Dummy to remove unused var warning
        // Is this a endRound request or a checkWinner request?
        RoundInfo storage playingRound = roundInfo[currentRound];
        uint[] memory matchingNumbers = new uint[](5);
        performData = bytes("");
        if (playingRound.active) {
            upkeepNeeded = playingRound.endRound < block.timestamp;
            performData = abi.encode(true, matchingNumbers);
        } else if (
            playingRound.randomnessRequestID > 0 &&
            !matches[playingRound.randomnessRequestID].completed &&
            matches[playingRound.randomnessRequestID].winnerNumber > 0
        ) {
            upkeepNeeded = true;
            address[] storage participants = roundUsers[currentRound];
            uint participantsLength = participants.length;
            uint64 winnerNumber = matches[playingRound.randomnessRequestID]
                .winnerNumber;
            for (uint i = 0; i < participantsLength; i++) {
                UserTickets storage user = userTickets[participants[i]][
                    currentRound
                ];
                uint ticketsLength = user.tickets.length;
                for (uint j = 0; j < ticketsLength; j++) {
                    uint8 matchAmount = _compareTickets(
                        winnerNumber,
                        user.tickets[j]
                    );
                    if (matchAmount > 0) {
                        matchingNumbers[matchAmount - 1]++;
                    }
                }
            }
            performData = abi.encode(false, matchingNumbers);
        } else upkeepNeeded = false;
    }

    function checkTicket(
        uint round,
        uint _userTicketIndex,
        address _user
    ) external view returns (uint) {
        uint pot = roundInfo[round].pot;
        uint64 winnerNumber = matches[roundInfo[round].randomnessRequestID]
            .winnerNumber;
        if (pot == 0 || winnerNumber == 0) return 0;
        // Check if user has claimed this ticket
        if (userTickets[_user][round].claimed[_userTicketIndex]) return 0;

        uint8 _matched_ = _compareTickets(
            matches[roundInfo[round].randomnessRequestID].winnerNumber,
            userTickets[_user][round].tickets[_userTicketIndex]
        );
        if (_matched_ < 3) return 0;
        uint totalMatches = getTotalMatches(
            matches[roundInfo[round].randomnessRequestID],
            _matched_
        );
        if (totalMatches == 0) return 0;
        return roundInfo[round].distribution[_matched_ - 3] / totalMatches;
    }

    function checkTickets(
        uint round,
        uint[] calldata _userTicketIndexes,
        address _user
    ) external view returns (uint) {
        uint pot = roundInfo[round].pot;
        uint64 winnerNumber = matches[roundInfo[round].randomnessRequestID]
            .winnerNumber;
        if (pot == 0 || winnerNumber == 0) return 0;

        uint totalReward;
        uint rndId = roundInfo[round].randomnessRequestID;

        for (uint i = 0; i < _userTicketIndexes.length; i++) {
            uint ticketIndex = _userTicketIndexes[i];
            // Check if user has claimed this ticket
            if (userTickets[_user][round].claimed[ticketIndex]) continue;

            uint8 _matched_ = _compareTickets(
                matches[rndId].winnerNumber,
                userTickets[_user][round].tickets[ticketIndex]
            );
            if (_matched_ < 3) continue;
            uint totalMatches = getTotalMatches(matches[rndId], _matched_);
            if (totalMatches == 0) continue;
            totalReward +=
                roundInfo[round].distribution[_matched_ - 3] /
                totalMatches;
        }
        return totalReward;
    }

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

    function checkTicketMatching(
        uint64 ticket1,
        uint64 ticket2
    ) external pure returns (uint8) {
        return _compareTickets(ticket1, ticket2);
    }

    function roundDistribution(
        uint round
    ) external view returns (uint[] memory) {
        uint[] memory distribution = new uint[](5);
        for (uint i = 0; i < 5; i++) {
            distribution[i] = roundInfo[round].distribution[i];
        }
        return distribution;
    }
}
