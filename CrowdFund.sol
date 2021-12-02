// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.6 <0.9.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract CrowdFundContract {

    using SafeMathChainlink for uint256; // Countermeasure to overflow errors resulting from uint256 math operations in early versions of solidity compiler.

    mapping(address => uint256) public addressToAmountFunded; //Hash map like stucture; in this instance it is used to map addresses to the total amount deposited in the contract.
    address[] public funders; // Array for keeping track of all those whom have funded contract.
    address public owner;

    constructor() public {
        owner = msg.sender; // Security measure to establish deployer of contract as owner.
    }

    function fundContract() public payable { // Anyone can fund this contract.
 
        uint256 minimumUSD = 1 * 10 ** 18;
        require(getConversionRate(msg.value) >= minimumUSD, "Minimum eth requirement not met.");

        if ((isPresent() == false)){
            funders.push(msg.sender); // If this is the 1st time address pays to contract then it is added to the array.
        }

        addressToAmountFunded[msg.sender] += msg.value; // Each time there is a payment made to contract the amount is mapped to the right address; it generally adds to the amount already present.
    } 

    function isPresent () public view returns (bool) { // Returns true if funder address payed into contract already. "required(!addressToAmountFunded(msg.sender))" should suffice,however this is me experimenting.

        address funder = msg.sender;
        if (addressToAmountFunded[funder] > 0) {
            return true;
        }
    } 

    function getPrice() public view returns(uint256){ // Function from the chainlink contract; returns price data for ethereum.
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
         return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount) public view returns (uint256){ // Converts eth amount to usd.
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    modifier onlyOwner { 
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable onlyOwner public { // Withdraw function that only contract owner can call.
        msg.sender.transfer(address(this).balance);

        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){ // This loop serves to reset the amount funded by each address to 0;
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); // Funders is now a new array, it has no elements.
    }

}
