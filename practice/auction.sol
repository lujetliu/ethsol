// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4

/*
	荷兰拍卖(Dutch Auction)是一种特殊的拍卖形式, 亦称"减价拍卖", 它是指
	拍卖标的的竞价由高到低依次递减直到第一个竞买人应价(达到或超过底价)时
	击槌成交的一种拍卖;

	举例来说: 卖家有1OO朵鲜花, 必须在一天内卖完否则花就谢了; 首先, 卖家设
	定最高价为每朵100元, 每两个小时降价10元; 拍卖开始后没有人竞价, 过了两
	个小时, 降到每朵9O元时, 有个竞买人竞价, 如果他买100朵则拍卖到此结束, 
	此竞买人成为买受人, 1OO朵鲜花以每朵9O元成交; 如果他只买7O朵, 那么剩
	下的30朵继续拍卖; 如果一天过去了, 不再有人竞价, 那么拍卖的结果是唯一
	的竞买人成为买受人, 以每朵9O元的成交价买走7O朵花; 但是如果过了两小时
	又有人来竞买剩下的3O朵花, 而价格为每朵8O元, 这时结束拍卖, 两个竞买人
	都成为买受人, 都以每朵8O元的价格成交;

	项目方非常喜欢这种拍卖形式, 主要有两个原因:
	- 荷兰拍卖的价格由最高慢慢下降, 能让项目方获得最大的收入
	- 拍卖持续较长时间(通常6小时以上), 可以避免gas war
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/ERC721.sol";

contract DutchAuction is Ownable, ERC721 {
	// 代码基于Azuki的代码简化而成, DucthAuction合约继承了ERC721和Ownable合约

	uint256 public constant COLLECTOIN_SIZE = 10000; // NFT总数
    uint256 public constant AUCTION_START_PRICE = 1 ether; // 起拍价(最高价)
    uint256 public constant AUCTION_END_PRICE = 0.1 ether; // 结束价(最低价/地板价)
    uint256 public constant AUCTION_TIME = 10 minutes; // 拍卖时间, 为了测试方便设为10分钟
    uint256 public constant AUCTION_DROP_INTERVAL = 1 minutes; // 每过多久时间价格衰减一次
    uint256 public constant AUCTION_DROP_PER_STEP =
        (AUCTION_START_PRICE - AUCTION_END_PRICE) /
        (AUCTION_TIME / AUCTION_DROP_INTERVAL); // 每次价格衰减步长

    uint256 public auctionStartTime; // 拍卖开始时间戳
    string private _baseTokenURI;   // metadata URI
    uint256[] private _allTokens; // 记录所有存在的tokenId

	// 设定拍卖起始时间: 构造函数中会声明当前区块时间为起始时间, 项目方也
	// 可以通过setAuctionStartTime()函数来调整
	constructor() ERC721("WTF Dutch Auctoin", "WTF Dutch Auctoin") {
        auctionStartTime = block.timestamp;
    }

    // auctionStartTime setter函数, onlyOwner
    function setAuctionStartTime(uint32 timestamp) external onlyOwner {
        auctionStartTime = timestamp;
    }


	// 获取拍卖实时价格
    function getAuctionPrice()
        public
        view
        returns (uint256)
    {
        if (block.timestamp < auctionStartTime) {
			return AUCTION_START_PRICE;
        }else if (block.timestamp - auctionStartTime >= AUCTION_TIME) {
			return AUCTION_END_PRICE;
        } else {
			uint256 steps = (block.timestamp - auctionStartTime) /
				AUCTION_DROP_INTERVAL;
			return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }

	// 用户拍卖并铸造NFT: 用户通过调用auctionMint()函数, 支付ETH参加荷兰拍
	// 卖并铸造NFT, 该函数首先检查拍卖是否开始/铸造是否超出NFT总量; 接着, 
	// 合约通过getAuctionPrice()和铸造数量计算拍卖成本, 并检查用户支付的
	// ETH是否足够: 如果足够则将NFT铸造给用户, 并退回超额的ETH; 反之则回退交易
	// 拍卖mint函数
    function auctionMint(uint256 quantity) external payable{
        uint256 _saleStartTime = uint256(auctionStartTime); // 建立local变量，减少gas花费
        require( _saleStartTime != 0 && block.timestamp >= _saleStartTime,
        "sale has not started yet"
        ); // 检查是否设置起拍时间, 拍卖是否开始

        require( totalSupply() + quantity <= COLLECTOIN_SIZE,
        "not enough remaining reserved for auction to support desired mint amount"
        ); // 检查是否超过NFT上限

        uint256 totalCost = getAuctionPrice() * quantity; // 计算mint成本
        require(msg.value >= totalCost, "Need to send more ETH."); // 检查用户是否支付足够ETH

        // Mint NFT
        for(uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            _mint(msg.sender, mintIndex);
            _addTokenToAllTokensEnumeration(mintIndex);
        }
        // 多余ETH退款
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost); //注意一下这里是否有重入的风险
        }
    }

	// 项目方取出筹集的ETH: 项目方可以通过withdrawMoney()函数提走拍卖筹集的ETH
	// 提款函数，onlyOwner
    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}


