1. Create contract
2. compile and deploy in remix
3. to sync with local run 'remixd .' "." - path to folder to sync  and select in workspace localhost. Do this before start work.
4. to deploy in testnet :
4.1 flatten contract
4.2 compile
4.3 enable remix in metamask. In ext select sites and click connect to account
4.4 go to deploy in remix and selec metamask. Deploy.
4.5 go to etherscanner and add flattened contract to show decompiled code
4.6 if code is TOKEN you can add in metamask by copping contract address and add as a token
4.7 connect to wev3 in etherscan with metamask to buy some own tokens
5. when flatting group of files added manually SPDX(maybe corner case)
6. Durring deployed list of flattened files added EBI encoded cunstuctor args to publish and verify code

Home task:
- https://docs.openzeppelin.com/contracts/4.x/erc721 - erc721 docs
- https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol - erc721 source code
- use https://testnets.opensea.io/ to create nft, connect with metamask manualy
- https://testnet.rarible.com/ instead of tesnet https://testnets.opensea.io
- https://wizard.openzeppelin.com/#erc1155 - wizzard to generate contract
- https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol github with contract
- generated EBI encoded constuct arguments
https://abi.hashex.org/


- my contract deployed 0xB5E34ba5033D4D579Ea0B1de6d2c471fB798edd5 with nft
https://sepolia.etherscan.io/address/0xb5e34ba5033d4d579ea0b1de6d2c471fb798edd5#code
- internatl contract for collection nft https://sepolia.etherscan.io/address/0xb342dc595a2f6a600f5386223b75120a74467b5a#code
- for 721 nft https://sepolia.etherscan.io/address/0xa7baf70aea59f82320a61846b19a0b332a329792#code
- nft awards only for ETH donations