// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	去中心化NFT交易所(TODO: 重点学习)

	设计逻辑
	卖家: 出售NFT的一方, 可以挂单list、撤单revoke、修改价格update
	买家: 购买NFT的一方, 可以购买purchase
	订单: 卖家发布的NFT链上订单, 一个系列的同一tokenId最多存在一个订单, 
		其中包含挂单价格price和持有人owner信息; 当一个订单交易完成或被撤单后,
		其中信息清零
*/

contract NFTSwap is IERC721Receiver{
	// 挂单事件(list), 撤单事件(revoke), 修改价格(update), 购买(purchase)
	event List(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    event Purchase(address indexed buyer, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    event Revoke(address indexed seller, address indexed nftAddr, uint256 indexed tokenId);
    event Update(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 newPrice);


	// 定义order结构体
    struct Order{
        address owner;
        uint256 price;
    }

    // NFT Order映射
    mapping(address => mapping(uint256 => Order)) public nftList;


    // 实现{IERC721Receiver}的onERC721Received, 能够接收ERC721代币
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external override returns (bytes4){
        return IERC721Receiver.onERC721Received.selector; // TODO: 选择器
    }

	// 回退函数
	// 在NFTSwap中, 用户使用ETH购买NFT合约需要实现fallback()函数来接收ETH
	fallback() external payable{}

	
    // 实现{IERC721Receiver}的onERC721Received, 能够接收ERC721代币
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external override returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
    }


	//--------------------------------------------------------------------交易
	// 挂单: 卖家上架NFT
	// 合约地址为_nftAddr, tokenId为_tokenId, 价格_price为以太坊(单位是wei)
    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public{
        IERC721 _nft = IERC721(_nftAddr); // 声明IERC721接口合约变量
        require(_nft.getApproved(_tokenId) == address(this), "Need Approval"); // 合约得到授权
        require(_price > 0); // 价格大于0

        Order storage _order = nftList[_nftAddr][_tokenId]; //设置NFT持有人和价格
        _order.owner = msg.sender;
        _order.price = _price;
        // 将NFT转账到合约, TODO
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        // 释放List事件
        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }

	// 撤单: 卖家取消挂单
    function revoke(address _nftAddr, uint256 _tokenId) public {
        Order storage _order = nftList[_nftAddr][_tokenId]; // 取得Order        
        require(_order.owner == msg.sender, "Not Owner"); // 必须由持有人发起
        // 声明IERC721接口合约变量
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFT在合约中
        
        // 将NFT转给卖家
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        delete nftList[_nftAddr][_tokenId]; // 删除order
      
        // 释放Revoke事件
        emit Revoke(msg.sender, _nftAddr, _tokenId);
    }

	// 调整价格: 卖家调整挂单价格
    function update(address _nftAddr, uint256 _tokenId, uint256 _newPrice) public {
        require(_newPrice > 0, "Invalid Price"); // NFT价格大于0
        Order storage _order = nftList[_nftAddr][_tokenId]; // 取得Order
        require(_order.owner == msg.sender, "Not Owner"); // 必须由持有人发起
        // 声明IERC721接口合约变量
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFT在合约中

        // 调整NFT价格
        _order.price = _newPrice;

        // 释放Update事件
        emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
    }

	// 购买: 买家购买NFT
	// 合约为_nftAddr, tokenId为_tokenId, 调用函数时要附带ETH
    function purchase(address _nftAddr, uint256 _tokenId) payable public {
        Order storage _order = nftList[_nftAddr][_tokenId]; // 取得Order        
        require(_order.price > 0, "Invalid Price"); // NFT价格大于0
        require(msg.value >= _order.price, "Increase price"); // 购买价格大于标价
        // 声明IERC721接口合约变量
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFT在合约中

        // 将NFT转给买家
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);

        // 将ETH转给卖家, 多余ETH给买家退款
        payable(_order.owner).transfer(_order.price);
        payable(msg.sender).transfer(msg.value-_order.price);

        delete nftList[_nftAddr][_tokenId]; // 删除order

        // 释放Purchase事件
        emit Purchase(msg.sender, _nftAddr, _tokenId, msg.value);
    }

}
