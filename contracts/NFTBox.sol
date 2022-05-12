pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract NFTBox is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _batchIds;
    Counters.Counter private _slotIds;

    //Batch - eg: 7 Batch
    struct Batch{
        string name;
        string thumb_img;
        uint256 total_slot;
        uint256 total_sold;
        string metadata_uri;//list of images
        uint start_time;//timestamp
        uint price;
        address owner;
        uint sold_out_time;
    }


    //Slot follow tokenID increment
    struct Slot{      
        address owner;  
        uint batchId;
    }


    //Both Array > uint > _batchIds.increment
    mapping(uint => Batch) BatchList;

    mapping(uint => Slot) TokenSlotList;

    //predefined random number for each batch
    uint[] private batchRandomId;


    
    constructor() ERC721("NFTBox", "NFTBox") {
    
    }

    /**
        AddBatch was to create batch with the list of metadata content (list of Token), 
        with define total slot for each batch by user
    */


    function addBatch(string memory name,  string memory thumb_img, uint256 total_slot,  
        string memory metadata_uri, uint price) public returns (uint256) {
       
        _batchIds.increment();

        uint256 newBatchId = _batchIds.current();

        BatchList[newBatchId] = Batch(name, thumb_img, total_slot, 0, metadata_uri, 
            block.timestamp, price, msg.sender, 0);

        batchRandomId[newBatchId] = 0;
        return newBatchId;
    }


    function setBatchReveal(uint256 batchId) public {
        require(isViewable(batchId), 'This batch has not fully sold out yet');
         if ( batchRandomId[batchId] == 0){
            batchRandomId[batchId] = (uint(keccak256(abi.encodePacked(batchId, block.timestamp, block.number-1))) 
                    % BatchList[batchId].total_slot)+1;
        }
    }
    


    function getTotalBatch() public view returns (uint256) {
        return _batchIds.current();
    }

    /**
        When user buy, it actually was to book a slot 
        be4 they can actually know what will they get

        each slot with state still masked
    */

    function buy(uint256 batchId) public payable {
        uint price = BatchList[batchId].price;

        require(price > 0, 'This token is not for sale');

        require(BatchList[batchId].total_sold < BatchList[batchId].total_slot, 
            'This Batch Was Totally Sold Out');

        address seller =  BatchList[batchId].owner;
        payable(seller).transfer(price); // send the ETH to the seller

        //reserve a slot in the batch for buyer
        bookSlot(batchId);
    }

    /**
        each booked slot with state still masked
    */

    function bookSlot(uint256 batchId) internal {  
        BatchList[batchId].total_sold+=1;

        if (BatchList[batchId].total_sold >= BatchList[batchId].total_slot){
            BatchList[batchId].sold_out_time = block.timestamp;
        }
        _slotIds.increment();

        uint256 newSlotId = _slotIds.current();
        TokenSlotList[newSlotId] = Slot(msg.sender, batchId);

        _mint(msg.sender, newSlotId);
        
    }



     /**
        when retrieving Item, it will check isViewable, 
        if yes then only will random pick the item to booked slot
    */

    function tokenURI(uint256 _tokenID)
        public
        view
        override
        returns (string memory)
    {
        uint256 batchId =  TokenSlotList[_tokenID].batchId;
         if (isViewable(batchId)){
            uint randomItemId = (_tokenID + batchRandomId[batchId]) % BatchList[batchId].total_slot;

            return string(abi.encodePacked(BatchList[batchId].metadata_uri,randomItemId));
         }

        return BatchList[batchId].thumb_img;
    }




    function isViewable(uint256 batchId) internal view returns (bool){
        //check if has set random number for reveal
        if (batchRandomId[batchId] != 0){
            return true;
        }

        //check if sold out
        if (BatchList[batchId].total_sold >= BatchList[batchId].total_slot){
            return true;
        }


        //after batch was sold out, after 3 day then only can views
        if (BatchList[batchId].sold_out_time != 0){
            uint viewable_time= addDays(BatchList[batchId].sold_out_time, 3);
            if (block.timestamp > viewable_time){
                return true;
            }
        }


        return false;
    }


    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    function addDays(uint256 timestamp, uint256 _days)
            internal
            pure
            returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
   


}