// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";

contract Volunteer {
    address private ownerAdrr;

    mapping(address => uint256) private donations; 
    address[] private donatorAddresses;
    uint256 private donationTotal;

    uint256 private minimumDonation; 
    uint256 private deadline; // in seconds

    address payable private destinationAddress;
    address private representativeAddress;

    uint64 private constant defaultMinimumDonation = 1 ether / 1000; // 0.001 ETH

    uint private startTimestamp;

    constructor(uint256 _deadlineSeconds, address _destinationAddr, uint256 _minimumDonation) {
        ownerAdrr = msg.sender; // set owner address when contract is deployed
        setMinumumDonationValue(_minimumDonation);
        deadline = _deadlineSeconds;
        destinationAddress = payable(_destinationAddr);
        representativeAddress = msg.sender; // set represnetative as owner by default
        startTimestamp = block.timestamp;
    }

    function donate() external payable {
        require(msg.value >= minimumDonation, string.concat(Strings.toString(minimumDonation), " is minimum value"));
        require(!isDeadline(), "Donation not allowed after deadline");

        donations[msg.sender] += msg.value;

        if (!_existsAddressItem(donatorAddresses, msg.sender)) {
            // instead if can check if record in donation is not zero
            donatorAddresses.push(msg.sender);
        }

        donationTotal += msg.value;
    }

    function getOwnerAdress() external view returns (address) {
        return ownerAdrr;
    }

    function getDonators() external view returns (address [] memory) {
        return donatorAddresses;
    }

    function getDonatedTotal() external view returns (uint256) {
        return donationTotal;
    }

    function getDonationValueByAddr(address addr) external view returns (uint256) {
        return donations[addr];
    }

    function setCherityDestinationAddress(address addr) external isOwner {
        destinationAddress = payable(addr);
    }

    function setCherityRepresentativeAddress(address addr) external isOwner {
        representativeAddress = addr;
    }

    function setDeadline(uint256 _deadline) external isOwner {
        deadline = _deadline;
    }

    function withdraw() external isRepresentative {
        require(destinationAddress != address(0), "Destination addr is not set");
        require(isDeadline(), "Is not deadline yet");

        uint balance = address(this).balance;
        (bool sent, bytes memory data) = destinationAddress.call{value: balance}("");
        require(sent, "Failed to send donations"); 
    }

    function setMinumumDonationValue(uint256 _minValue) public isOwner {
        // value is in WEI
        require(_minValue >= defaultMinimumDonation, string.concat(Strings.toString(defaultMinimumDonation), " is minimum value to set lower donation"));
        minimumDonation = _minValue;
    }

    function isDeadline() public view returns (bool) {
         return (block.timestamp >= startTimestamp + deadline);
    }

    function _existsAddressItem(address[] memory array, address addr) private pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == addr) {
                return true;
            }
        }

        return false;
    }

    modifier isOwner() {
        require(msg.sender == ownerAdrr, "Caller is not owner");
        _;
    }

    modifier isRepresentative() {
        require(msg.sender == representativeAddress, "Allowed only for representative");
        _;
    }

    modifier minimumDonationValueValidator() {
        require(minimumDonation >= defaultMinimumDonation, string.concat(Strings.toString(defaultMinimumDonation), " is minimum value for lower donation"));
        _;
    }
}