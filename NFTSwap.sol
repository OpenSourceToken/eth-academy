// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTSwap is ReentrancyGuard {
    struct Order {
        address owner;
        uint256 price;
    }
    mapping(address => mapping(uint256 => Order)) public orders;

    event Listed(address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event Revoked(address indexed nftAddress, uint256 indexed tokenId);
    event Updated(address indexed nftAddress, uint256 indexed tokenId, uint256 newPrice);
    event Purchased(address indexed nftAddress, uint256 indexed tokenId, address buyer);

    function list(address nftAddress, uint256 tokenId, uint256 price) external {
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Not approved");

        orders[nftAddress][tokenId] = Order(msg.sender, price);
        emit Listed(nftAddress, tokenId, price);
    }

    function revoke(address nftAddress, uint256 tokenId) external {
        require(orders[nftAddress][tokenId].owner == msg.sender, "Not the owner");

        delete orders[nftAddress][tokenId];
        emit Revoked(nftAddress, tokenId);
    }

    function update(address nftAddress, uint256 tokenId, uint256 newPrice) external {
        require(orders[nftAddress][tokenId].owner == msg.sender, "Not the owner");

        orders[nftAddress][tokenId].price = newPrice;
        emit Updated(nftAddress, tokenId, newPrice);
    }
  
    function purchase(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Order storage order = orders[nftAddress][tokenId];
        require(order.owner != address(0), "Order does not exist");
        require(msg.value >= order.price, "Insufficient payment");

        IERC721 nft = IERC721(nftAddress);
        nft.safeTransferFrom(order.owner, msg.sender, tokenId);

        payable(order.owner).transfer(order.price);
        if (msg.value > order.price) {
            payable(msg.sender).transfer(msg.value - order.price);
        }

        delete orders[nftAddress][tokenId];
        emit Purchased(nftAddress, tokenId, msg.sender);
    }
}
