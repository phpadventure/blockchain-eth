// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./VolunteerNFT.sol";
import "./VolunteerCollectionNFT.sol";

contract Volunteer {
    address private ownerAdrr;

    mapping(address => uint256) private donations; 
    mapping(address => uint256) private donationsInADT; 

    address[] private donatorAddresses;
    address[] private donatorAddressesADT;

    uint256 private donationTotal;
    uint256 private donationTotalADT;

    uint256 private minimumDonation; 
    uint256 private deadline; // in seconds

    address payable private destinationAddress;
    address private representativeAddress;

    uint64 private constant defaultMinimumDonation = 1; // = 1 ether / 1000; // 0.001 ETH or ADT lets eq of 1 WEI

    uint private startTimestamp;

    IERC20 private immutable adToken;

    string private constant ETH_NAME = "ETH";
    string private constant ADT_NAME = "ADT";

    // REWARD for each donate
    VolunteerCollectionNFT private collectionNFT;
    uint private cheeringTokenId = 1; 

    // REWARD WITH NFT
    VolunteerNFT private vlnNFT;
    uint private constant amountOfTopDonators = 3;
    address[] private topDonnators;
    uint256 private minumTopRankDonate;

    event ActionEvent(string action, uint256 value, string currency, address userAddr);

    constructor(address _adtTokenAddr ) {
        ownerAdrr = msg.sender; // set owner address when contract is deployed
        setMinumumDonationValue(defaultMinimumDonation);
        deadline = 300; // 5 min in seconds
        address _destinationAddr = msg.sender; // set as owner
        destinationAddress = payable(_destinationAddr);
        representativeAddress = msg.sender; // set represnetative as owner by default
        startTimestamp = block.timestamp;
        adToken = IERC20(_adtTokenAddr);
        vlnNFT = new VolunteerNFT(address(this));
        collectionNFT = new VolunteerCollectionNFT(address(this));
    }

    function donate() external payable {
        require(msg.value >= minimumDonation, string.concat(Strings.toString(minimumDonation), " is minimum value"));
        require(!isDeadline(), "Donation not allowed after deadline");

        donations[msg.sender] += msg.value;

        if (!_existsAddressItem(donatorAddresses, msg.sender)) {
            // instead if can check if record in donation is not zero
            donatorAddresses.push(msg.sender);

            // cheering token
            collectionNFT.mint(msg.sender, cheeringTokenId, 1, "");
        }

        donationTotal += msg.value;

        emit ActionEvent("donate", msg.value, ETH_NAME, msg.sender);

        recordTopDonators(msg.sender, msg.value);
    }

    function insertTopDonatorsInSortedArray(address newDonatorAddr, uint256 donation) internal {
        if (topDonnators.length == 0) {
            topDonnators.push(newDonatorAddr);
            return;
        }

        address[] memory sortedDonnators = new address[](topDonnators.length+1);
        bool inserted = false;
        uint8 j;
        // insert in sorted order new donator
        for (uint8 i = 0; i < topDonnators.length; i++) {
            address currentTopDonnatorAddr = topDonnators[i];

            if (inserted == true) {
                sortedDonnators[j] = currentTopDonnatorAddr;
                j++;
                continue; 
            } 
        
            if (donations[currentTopDonnatorAddr] >= donation) {
                sortedDonnators[j] = currentTopDonnatorAddr;
                j++;
                // if it's last item and new donation is lowest add it to the end
                if (i+1 == topDonnators.length) {
                    sortedDonnators[j] = newDonatorAddr;
                    j++;
                    inserted = true;
                }
            } else {
                sortedDonnators[j] = newDonatorAddr;
                j++;
                sortedDonnators[j] = currentTopDonnatorAddr;
                j++;
                inserted = true;
            }
        }

        // reasign sorted array
        topDonnators = sortedDonnators;
    }

    function recordTopDonators(address donatorAddr, uint256 donation) internal {
        insertTopDonatorsInSortedArray(donatorAddr, donation);

        // remove last insertion if exceeded amount of top donators
        if (topDonnators.length > amountOfTopDonators) {
            topDonnators.pop();
        }
    }

    function donateADT(uint256 adtValue) external {
        require(adtValue >= minimumDonation, string.concat(Strings.toString(minimumDonation), " is minimum value in ADT"));
        require(!isDeadline(), "Donation not allowed after deadline");

        adToken.transferFrom(msg.sender, address(this), adtValue);

        donationsInADT[msg.sender] += adtValue;

        if (donationsInADT[msg.sender] == 0) {
            // instead if can check if record in donation is not zero
            donatorAddressesADT.push(msg.sender);
        }

        donationTotalADT += adtValue;

        emit ActionEvent("donate", adtValue, ADT_NAME, msg.sender);
    }

    function getOwnerAdress() external view returns (address) {
        return ownerAdrr;
    }

    function getDonators(string memory currency) isAllowedCurrency(currency) external view returns (address [] memory) {
        if (Strings.equal(currency, ETH_NAME) || Strings.equal(currency,'')) {
            return donatorAddresses;
        }
        return donatorAddressesADT;
    }

    function getDonatedTotal(string memory currency) isAllowedCurrency(currency) external view returns (uint256) {
        if (Strings.equal(currency, ETH_NAME) || Strings.equal(currency,'')) {
            return donationTotal;
        }
        return donationTotalADT;
    }

    function getDonationValueByAddr(address addr, string memory currency) isAllowedCurrency(currency) external view returns (uint256) {
        if (Strings.equal(currency, ETH_NAME) || Strings.equal(currency,'')) {
            return donations[addr];
        }

        return donationsInADT[addr];
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

         // award only first time withdraw when blance is present
        if (donationTotal > 0) {
            rewardTopETHDonators();
        }

        donationTotal = 0;

        emit ActionEvent("withdrawBalance", balance, ETH_NAME, destinationAddress);
    }

    function withdrawADT() external isRepresentative {
        require(destinationAddress != address(0), "Destination addr is not set");
        require(isDeadline(), "Is not deadline yet");

        bool sent = adToken.transfer(destinationAddress, donationTotalADT);
        require(sent, "Failed to tranfer ADT to destination address");

        donationTotalADT = 0;
        emit ActionEvent("withdrawBalance", donationTotalADT, ETH_NAME, destinationAddress);
    }

    function setMinumumDonationValue(uint256 _minValue) public isOwner {
        // value is in WEI
        require(_minValue >= defaultMinimumDonation, string.concat(Strings.toString(defaultMinimumDonation), " is minimum value to set lower donation"));
        minimumDonation = _minValue;
    }

    function isDeadline() public view returns (bool) {
         return (block.timestamp >= startTimestamp + deadline);
    }

    function getCollectionNft(address donator) public view returns (uint256) {
        return collectionNFT.balanceOf(donator, cheeringTokenId);
    }

    function getVlnt(address donator) public view returns (uint256) {
        return vlnNFT.balanceOf(donator);
    }

    function rewardTopETHDonators() private {
        for (uint i = 0; i < topDonnators.length; i++) {
            vlnNFT.safeMint(topDonnators[i]);
        }
    }

    function _existsAddressItem(address[] memory array, address addr) private pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == addr) {
                return true;
            }
        }

        return false;
    }

    modifier isAllowedCurrency(string memory currency) {
        require(Strings.equal(currency, "") || Strings.equal(currency, ADT_NAME) || Strings.equal(currency, ETH_NAME), "Invalid currency");
        _;
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