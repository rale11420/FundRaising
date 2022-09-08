// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error InvalidCampaignData();
error NotEnoughTimePassed();
error NotActive();
error AlreadyFinished();
error NotDonorYet();

/// @author rale11420
/// @title Simple fundraising contract
contract FundRaising is ReentrancyGuard{

    //events
    event CampaignStart(uint id, address indexed creator, string name, uint targetAmount);
    event DonationMade(uint id, address indexed contributor, uint amount);
    event DonationCanceled(uint id, address indexed contributor);
    event RefundDonation(uint id, address indexed contributor);
    event CampaignFinished(uint id, address indexed creator, uint targetAmount);  

    //modifiers
    modifier ValidID(uint index){
        require(index >= 0 && index <= id);
        _;
    }

    modifier NotCreator(uint index) {
        require(campaigns[index].creator != msg.sender, "Not creator");  
        _;      
    }

    struct Campaign {
        address creator;
        string name; 
        string description;
        uint targetAmount;
        uint currentAmount;
        uint endTime;        
        bool active;
    }

    uint id;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public donations;

    /// @notice Function starts new campaign with msg.sender as creator
    /// @param _name is name of the campaign
    /// @param _description is description of the campaign
    /// @param _targetAmount is targetAmount of the campaign
    /// @param _duration is duration of the campaign
    function startCampaign(string calldata _name, string calldata _description, uint _targetAmount, uint _duration) external {
        if (bytes(_name).length <= 0 || _targetAmount > 0 || _duration > 0) { revert InvalidCampaignData(); }

        campaigns[id] = Campaign({
            creator: msg.sender,
            name: _name,
            description: _description,
            targetAmount: _targetAmount,
            currentAmount: 0,
            endTime: block.timestamp + _duration,
            active: true
        });
        id++;

        emit CampaignStart(id, msg.sender, _name, _targetAmount);
    }

    /// @notice Function enables ETH donations to contract
    /// @param campaignIndex is id of campaign in campaigns mapping
    function donate(uint campaignIndex) external payable ValidID(campaignIndex) NotCreator(campaignIndex){
        Campaign storage temp = campaigns[campaignIndex];

        if(temp.endTime < block.timestamp) { revert AlreadyFinished(); }
        if(!temp.active) { revert NotActive(); }
        require(msg.value > 0 && msg.value <= (temp.targetAmount-temp.currentAmount), "Invalid amount to donate");
        require(temp.endTime > block.timestamp, "Campaign finished");


        donations[campaignIndex][msg.sender] += msg.value;
        temp.currentAmount += msg.value;

        emit DonationMade(campaignIndex, msg.sender, msg.value);
    }

    /// @notice Function enables canceling ETH donations to contract if campaign still active
    /// @param campaignIndex is id of campaign in campaigns array
    function cancelDonation(uint campaignIndex) external ValidID(campaignIndex) NotCreator(campaignIndex) nonReentrant(){     
        Campaign storage temp = campaigns[campaignIndex];

        if(donations[campaignIndex][msg.sender] <= 0) { revert NotDonorYet(); }
        if(temp.endTime < block.timestamp) { revert AlreadyFinished(); }

        temp.currentAmount -= donations[campaignIndex][msg.sender];       
        donations[campaignIndex][msg.sender] = 0;  
        
        payable(msg.sender).transfer(donations[campaignIndex][msg.sender]);

        emit DonationCanceled(campaignIndex, msg.sender);
    }

    /// @notice Function for finishing campaign, withdraw donations, can be called only by campaign creator
    /// @param campaignIndex is id of campaign in campaigns array
    function finishCampaign(uint campaignIndex) external ValidID(campaignIndex) nonReentrant(){
        Campaign memory temp = campaigns[campaignIndex];

        if(temp.endTime > block.timestamp) { revert NotEnoughTimePassed(); }
        if(!temp.active) { revert NotActive(); }        
        require(temp.targetAmount <= temp.currentAmount,"Not enough funds");
        require(temp.creator == msg.sender, "Not creator");

        campaigns[campaignIndex].active = false;

        payable(msg.sender).transfer(temp.targetAmount);

        emit CampaignFinished(campaignIndex, msg.sender, temp.targetAmount); 
    }
    
    /// @notice Function enables refund donations if campaign wasn't success
    /// @param campaignIndex is id of campaign in campaigns array
    function refundDonation(uint campaignIndex) external ValidID(campaignIndex) NotCreator(campaignIndex) nonReentrant(){
        Campaign memory temp = campaigns[campaignIndex];
        if(temp.endTime > block.timestamp) { revert NotEnoughTimePassed(); }
        if(donations[campaignIndex][msg.sender] <= 0) { revert NotDonorYet(); }
        require(temp.active == false, "Not finished");
        require(msg.sender != temp.creator, "Creator can't refund");

        donations[campaignIndex][msg.sender] = 0;  

        payable(msg.sender).transfer(donations[campaignIndex][msg.sender]);

        emit RefundDonation(campaignIndex, msg.sender);        
    }

    function getCampaign(uint campaignIndex) external view ValidID(campaignIndex) returns(Campaign memory) {
        return campaigns[campaignIndex];
    }
}