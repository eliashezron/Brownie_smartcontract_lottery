// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal priceFeed;
    enum LOTTERY_STATE {
        open,
        closed,
        calculating_winner
    }
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    uint256 public entranceFee;
    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeed,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        entranceFee = 50 * (10**18);
        lottery_state = LOTTERY_STATE.closed;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        require(
            lottery_state == LOTTERY_STATE.open,
            "wait for lottery to start"
        );
        require(msg.value >= getEntranceFee(), "not enough eth");
        players.push(msg.sender);
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10**18);
    }

    function getConversionRate(uint256 _amount) public view returns (uint256) {
        return (((_amount * getPrice()) / 1) * 10**8);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        // $50, $2,000 / ETH
        // 50/2,000
        // 50 * 100000 / 2000
        uint256 costToEnter = (entranceFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.closed,
            "can't start a new lottery just yet"
        );
        lottery_state = LOTTERY_STATE.open;
    }

    function endLottery() public onlyOwner {
        lottery_state = LOTTERY_STATE.calculating_winner;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.calculating_winner,
            "you arent there yet"
        );
        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        // reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.closed;
        randomness = _randomness;
    }
}
