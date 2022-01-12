//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FurnitureTokens is ERC1155PresetMinterPauser, Ownable {

    // Available Models from which user can choose
    mapping(uint256 => Furniture) public availableModels;
    // Furnitures id mapped to ownersOf 
    mapping(uint256 => address) public ownerOf;

    struct Color {
        uint256 red;
        uint256 green;
        uint256 blue;
    }

    struct Furniture {
        uint256 id;
        Color color;
        uint256 price;
        string modelUrl;
        bool isValue;
    }

    modifier setOwnerOfFurniture(uint256 furnitureId, address ownerAddress) {
        _;
        ownerOf[furnitureId] = ownerAddress;
    }

    // Initial models
    Furniture public MODEL_ONE = Furniture({
        id: 1,
        color: Color(231,73,44),
        price: 10**16, // 0.01ETH
        modelUrl: "link_to_download_a_model",
        isValue: true
    });
    
    constructor() ERC1155PresetMinterPauser("") {
        transferOwnership(msg.sender);
        _mint(msg.sender, MODEL_ONE.id, 10, "");

        availableModels[MODEL_ONE.id] = MODEL_ONE;    
    }

    // Allow the owner to add a new furniture model
    function addFurnitureModel( Furniture memory newFurniture ) internal onlyOwner {
        require(!availableModels[newFurniture.id].isValue, "Furniture with this id already exist. Reverting");
        availableModels[newFurniture.id] = newFurniture;
    }

    // Remove furniture model
    function removeFurnitureModel( uint256 furnitureId ) internal onlyOwner {
        require(availableModels[furnitureId].isValue, "Model with specified id does not exist");
        availableModels[furnitureId].isValue = true;
    }

    // Buy a model, so you can use it in game
    function buyFurniture( address _from, uint256 furnitureId ) setOwnerOfFurniture(furnitureId, msg.sender) public payable {
        require(availableModels[furnitureId].isValue, "Model with specified id does not exist");
        require(msg.value >= availableModels[furnitureId].price, "Funds are insufficent");
        require(balanceOf(_from, furnitureId) > 0, "We doesn't sell this model at the moment");

        (bool sent,) = _from.call{value: msg.value}("");
        require(sent, "Failed to sent ether");
        
        safeTransferFrom(_from, msg.sender, furnitureId, 1, "");
    }

    function transferFurniture( address _to, uint256 furnitureId ) setOwnerOfFurniture(furnitureId, _to) public {
        require(msg.sender == ownerOf[furnitureId], "You have to be the owner of furniture");
        require(_to != ownerOf[furnitureId], "You can't transfer furniture to yourself");
        
        safeTransferFrom(msg.sender, _to, furnitureId, 1, "");
    }

}