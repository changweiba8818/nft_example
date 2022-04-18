// contracts/NFTItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract NFTItem is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    
    constructor() ERC721("NFTItem", "MNFT") {
    
    }


    function add(string memory _img) public returns (uint256) {
       
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _img);

        return newItemId;
    }

    function exists(uint256 itemId) public  view returns (bool){
        return _exists(itemId);
    }

    function remove(uint256 itemId) public {
        if (_exists(itemId)){
            _burn(itemId);
        }
    }
   

    function update(uint256 itemId , string memory _img) public {
        _setTokenURI(itemId, _img);
    }

    function get(uint256 itemId ) public view returns (string memory) {
        return tokenURI(itemId);
    }

    function lastIndex() public view returns (uint256){
       return _tokenIds.current();
    }


}
