// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// each ADT equal 1 ETH
contract ADToken is ERC20 {
    //mapping(address => uint256) private ethLiquidityMap; 

    uint64 private constant minimumTokenToBuy = 1; // 1 ether / 1000; // 0.001 ETH - don't play with ETH just use WEI

    uint256 private balance;

    constructor() ERC20("ADToken", "ADT") {
    }

    // user can buy token in equivalent to ETH
    // so ETH balance increase
    // use ADT for calculating how many token user has as it's 1 to 1, no need for separate mapping
    function buyADT() external payable returns (uint256) {
        require(msg.value >= minimumTokenToBuy, string.concat(Strings.toString(minimumTokenToBuy), " WEI is minimum value to buy token, eq 1 ETH to 1 ADT"));

        _mint(msg.sender, msg.value);

        balance += msg.value;

        return balanceOf(msg.sender);
    }

    function sellADT(uint256 ADTamound) external {
        _burn(msg.sender, ADTamound);

        // as it's 1 to 1 user ETH should be equal to ADT balance he bought or received 
        (bool sent, bytes memory data) = msg.sender.call{value: ADTamound}(""); // send ETH form balance
        require(sent, "Failed to sell ADT"); 

        balance -= ADTamound; // reduced ETH balance in eq of ADT
    }
}
