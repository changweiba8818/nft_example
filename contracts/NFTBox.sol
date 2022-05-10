pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract NFTBox is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _collectionIds;

    //Collection - eg: 7 Batch of Collection
    struct CollectionBox{
        string name;
        string desc;
        string thumb_img;
        uint256 total_item;
        string content_json;
        uint create_time;//timestamp
        uint start_time;//timestamp
        uint campaign_days;//in days
        uint price;
        bool isPublish;
        address owner;
    }


    //Each collection has it own array of CollectionItem - eg each collection has 1,111 items
    struct CollectionItem{ 
        uint purchase_time;       
        string img_url;    
        address owner;  
        uint256 itemId;
    }

    struct CollectionBoxList{
         CollectionItem[] items;
    }



    //Buyer History/Purchased Token
    struct MyItem{
        uint256 collectionId;
        uint256 itemsId;
        string img_url;
        uint purchase_time;
    }

    struct MyBox{
        MyItem[] myItems;
    }

    //Both Collection Array > uint > _collectionIds.increment
    mapping(uint => CollectionBox) CollectionList;
    mapping(uint => CollectionBoxList) CollectionItemList;


    //Purchaser Purchased Items
    mapping(address => MyBox) MyHistory;

    
    constructor() ERC721("NFTBox", "NFTBox") {
    
    }

    function addCollection(string memory name, string memory desc, string memory thumb_img, uint256 total_item,  
        string memory content_json,  uint campaign_days, uint price, bool isPublish) public returns (uint256) {
       
        _collectionIds.increment();

        uint256 newCollectionId = _collectionIds.current();

        CollectionList[newCollectionId] = CollectionBox(name, desc, thumb_img, total_item, content_json, 
            block.timestamp, block.timestamp, campaign_days, price, isPublish, msg.sender);

        return newCollectionId;
    }


    function publish(uint256 collectionId, uint campaign_days, bool isPublish) public {
        CollectionList[collectionId].campaign_days = campaign_days;
        CollectionList[collectionId].isPublish = isPublish;
    }


    function updateCollectionTotalItems(uint256 collectionId, uint total_item) public {
        CollectionList[collectionId].total_item = total_item;
    }


    function getCollection(uint256 collectionId ) public view returns (CollectionBox memory) {
        return CollectionList[collectionId];
    }



    function getTotalCollections() public view returns (uint256) {
        return _collectionIds.current();
    }



    function getTest(uint256 collectionId) public payable returns (CollectionItem memory){ 
        uint currentId=CollectionItemList[collectionId].items.length;
        uint randomId = uint(keccak256(abi.encodePacked(currentId, block.number-1))) % CollectionList[collectionId].total_item;
        CollectionItemList[collectionId].items.push(
            CollectionItem(block.timestamp, "img_url", msg.sender, randomId)
        );
        uint lastid = CollectionItemList[collectionId].items.length - 1;

        MyHistory[msg.sender].myItems.push(
            MyItem(collectionId, lastid, "img_url", block.timestamp)
        );
        return CollectionItemList[collectionId].items[lastid];
    }

    function addCollectionItem(uint256 collectionId, string memory img_url) public {  
         uint currentId=CollectionItemList[collectionId].items.length; 
         uint256 randomId = uint256(keccak256(abi.encodePacked(currentId, block.number-1))) % CollectionList[collectionId].total_item;


        CollectionItemList[collectionId].items.push(
               CollectionItem(block.timestamp, "img_url", msg.sender, randomId)
        );
        uint lastId = CollectionItemList[collectionId].items.length - 1;
        addMyHistory(collectionId, lastId, img_url);
        
    }


    function getCurrentCollectionItemIndex(uint256 collectionId) public view returns (uint256) {  
        return  CollectionItemList[collectionId].items.length;
    }



    function addMyHistory(uint256 collectionId, uint256 itemId, string memory img_url) internal {
        MyHistory[msg.sender].myItems.push(
            MyItem(collectionId, itemId, img_url, block.timestamp)
        );

    }

    function getMyHistory() public view returns (MyBox memory){
        return MyHistory[msg.sender];
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
   


    function isViewable(uint256 collectionId, uint itemId) public view returns (bool){

        //check if campaign end
        uint256 close_time= addDays(CollectionList[collectionId].start_time, CollectionList[collectionId].campaign_days);
        if (block.timestamp > close_time){
            return true;
        }

        //check if sold out
        if (CollectionItemList[collectionId].items.length >= CollectionList[collectionId].total_item){
            return true;
        }


        //After 3 days purchased, buyer can view the token
        uint256 viewable_time= addDays(CollectionItemList[collectionId].items[itemId].purchase_time, 3);
        
        if (block.timestamp > viewable_time){
            return true;
        }

        return false;
    }


    function buy(uint256 collectionId, string memory img_url) public payable {
        uint price = CollectionList[collectionId].price;

        require(price > 0, 'This token is not for sale');

        require(CollectionList[collectionId].isPublish, 'This Collection was not publish');

        uint256 close_time= addDays(CollectionList[collectionId].start_time, CollectionList[collectionId].campaign_days);
        require(block.timestamp < close_time, 'This Campaign Was Closed');


        require(CollectionItemList[collectionId].items.length < CollectionList[collectionId].total_item, 
            'This Collection Was Totally Sold Out');

        address seller =  CollectionList[collectionId].owner;
        payable(seller).transfer(price); // send the ETH to the seller

        //give owner items
        addCollectionItem(collectionId, img_url);

        
    }







}