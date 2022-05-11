pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract NFTBox is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _batchIds;

    //Batch - eg: 7 Batch
    struct Batch{
        string name;
        string desc;
        string thumb_img;
        uint256 total_slot;
        string content_json;//list of images in json array
        uint create_time;//timestamp
        uint start_time;//timestamp
        uint campaign_days;//in days
        uint price;
        bool isPublish;
        address owner;
    }


    //Each Batch has it own array of Slot - eg each batch has 1,111 slot
    struct Slot{ 
        uint purchase_time;       
        address owner;  
        uint itemId;
        int itemState;
    }

    int constant STATE_MASK = 0;
    int constant STATE_UNMASK = 1;

    struct SlotList{
         Slot[] slot;
    }



    //Buyer History/Purchased Token
    struct MyItem{
        uint256 batchId;
        uint256 slotId;
        uint purchase_time;
    }

    struct MyBox{
        MyItem[] myItems;
    }

    //Both Array > uint > _batchIds.increment
    mapping(uint => Batch) BatchList;
    mapping(uint => SlotList) BatchSlotList;

    //predefined random number for each batch
    uint[] private batchRandomId;


    //Purchaser Purchased Slot
    mapping(address => MyBox) MyHistory;

    
    constructor() ERC721("NFTBox", "NFTBox") {
    
    }

    /**
        AddBatch was to create batch with the list of metadata content (list of Token), 
        with define total slot for each batch by user
    */


    function addBatch(string memory name, string memory desc, string memory thumb_img, uint256 total_slot,  
        string memory content_json,  uint campaign_days, uint price, bool isPublish) public returns (uint256) {
       
        _batchIds.increment();

        uint256 newBatchId = _batchIds.current();

        BatchList[newBatchId] = Batch(name, desc, thumb_img, total_slot, content_json, 
            block.timestamp, block.timestamp, campaign_days, price, isPublish, msg.sender);

        batchRandomId[newBatchId] = uint(keccak256(abi.encodePacked(newBatchId, block.timestamp, block.number-1))) % total_slot;

        return newBatchId;
    }


    function publish(uint256 batchId, uint campaign_days, bool isPublish) public {
        BatchList[batchId].campaign_days = campaign_days;
        BatchList[batchId].isPublish = isPublish;
    }




    function getBatch(uint256 batchId ) public view returns (Batch memory) {
        return BatchList[batchId];
    }



    function getTotalBatch() public view returns (uint256) {
        return _batchIds.current();
    }






    function getCurrentBatchSlotIndex(uint256 batchId) public view returns (uint256) {  
        return  BatchSlotList[batchId].slot.length;
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
   


   



    /**
        When user buy, it actually was to book a slot in the batch 
        be4 they can actually know what will they get

        each slot with state still masked
    */

    function buy(uint256 batchId) public payable {
        uint price = BatchList[batchId].price;

        require(price > 0, 'This token is not for sale');

        require(BatchList[batchId].isPublish, 'This Batch was not publish');

        uint256 close_time= addDays(BatchList[batchId].start_time, BatchList[batchId].campaign_days);
        require(block.timestamp < close_time, 'This Campaign Was Closed');


        require(BatchSlotList[batchId].slot.length < BatchList[batchId].total_slot, 
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
        BatchSlotList[batchId].slot.push(
               Slot(block.timestamp, msg.sender, 0, STATE_MASK) //itemId = -1 mean still unknown which item they will get
        );
        uint slotId = BatchSlotList[batchId].slot.length - 1;
        addMyHistory(batchId, slotId);
        
    }



     /**
        when retrieving Item, it will check isViewable, 
        if yes then only will random pick the item to booked slot, and unmask the state
    */

    function getItemId(uint256 batchId, uint slotId) public payable returns (uint){

        require(slotId < BatchSlotList[batchId].slot.length, 'No Found');

        require(isViewable(batchId, slotId), 'No Found');

        if (BatchSlotList[batchId].slot[slotId].itemState == STATE_MASK){
            uint randomItemId = (slotId + batchRandomId[batchId]) % BatchList[batchId].total_slot;
            
            BatchSlotList[batchId].slot[slotId].itemId = randomItemId;
            BatchSlotList[batchId].slot[slotId].itemState = STATE_UNMASK;
        }

        return BatchSlotList[batchId].slot[slotId].itemId;
          

    }



    function isViewable(uint256 batchId, uint slotId) internal view returns (bool){

        //check if campaign end
        uint256 close_time= addDays(BatchList[batchId].start_time, BatchList[batchId].campaign_days);
        if (block.timestamp > close_time){
            return true;
        }

        //check if sold out
        if (BatchSlotList[batchId].slot.length >= BatchList[batchId].total_slot){
            return true;
        }


        //After 3 days purchased, buyer can view the token
        uint256 viewable_time= addDays(BatchSlotList[batchId].slot[slotId].purchase_time, 3);
        
        if (block.timestamp > viewable_time){
            return true;
        }

        return false;
    }






    function addMyHistory(uint256 batchId, uint256 slotId) internal {
        MyHistory[msg.sender].myItems.push(
            MyItem(batchId, slotId, block.timestamp)
        );

    }

    function getMyHistory() public view returns (MyBox memory){
        return MyHistory[msg.sender];
    }



}