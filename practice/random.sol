// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	很多以太坊上的应用都需要用到随机数, 例如NFT随机抽取tokenId、抽盲盒、gamefi
	战斗中随机分胜负等等; 但是由于以太坊上所有数据都是公开透明(public)且确定性
	(deterministic)的, 它没法像其他编程语言一样给开发者提供生成随机数的方法;
	本节介绍链上(哈希函数)和链下(chainlink预言机)随机数生成的两种方法, 并实现
	一款tokenId随机铸造的NFT

	链上随机数生成
		可以将一些链上的全局变量作为种子, 利用keccak256()哈希函数来获取伪随机数;
		这是因为哈希函数具有灵敏性和均一性, 可以得到"看似"随机的结果; 下面的
		getRandomOnchain()函数利用全局变量block.number, msg.sender和
		blockhash(block.timestamp-1)作为种子来获取随机数:

		// 链上伪随机数生成
		// 利用keccak256()打包一些链上的全局变量/自定义变量
		// 返回时转换成uint256类型
		//
		function getRandomOnchain() public view returns(uint256){
			// remix运行blockhash会报错
			bytes32 randomBytes = keccak256(abi.encodePacked(block.number, msg.sender, blockhash(block.timestamp-1)));

			return uint256(randomBytes);
		}

		这个方法并不安全, 首先 block.number, msg.sender和blockhash(block.timestamp-1)
		这些变量都是公开的, 使用者可以预测出用这些种子生成出的随机数, 并挑出他们
		想要的随机数执行合约; 其次矿工可以操纵blockhash和block.timestamp, 使得生
		成的随机数符合他的利益; (TODO: 实践证明)

		由于这种方法是最便捷的链上随机数生成方法, 大量项目方依靠它来生成不安全的
		随机数, 包括知名的项目meebits, loots等(TODO: 阅读项目代码); 这些项目也无
		一例外的被攻击了: 攻击者可以铸造任何他们想要的稀有NFT, 而非随机抽取.


	链下随机数生成
		可以在链下生成随机数, 然后通过预言机把随机数上传到链上;  Chainlink提供
		VRF(可验证随机函数)服务, 链上开发者可以支付LINK代币来获取随机数;
		Chainlink VRF有两个版本, 因为第二个版本需要官网注册并预付费且用法类似,
		本节只介绍第一个版本VRF v1

*/


import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol"; // TODO

contract RandomNumberConsumer is VRFConsumerBase {
    bytes32 internal keyHash; // VRF唯一标识符
    uint256 internal fee; // VRF使用手续费

    uint256 public randomResult; // 存储随机数

    /**
     * 使用chainlink VRF, 构造函数需要继承 VRFConsumerBase  TODO: 构造函数继承
     * 不同链参数填的不一样
     * 网络: Rinkeby测试网
	 * Link 水龙头: https://faucets.chain.link
     * Chainlink VRF Coordinator 地址: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
     * LINK 代币地址: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
     */
    constructor()
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (VRF使用费, Rinkeby测试网)
    }

	/**
     * 向VRF合约申请随机数
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        // 合约中需要有足够的LINK
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");

        return requestRandomness(keyHash, fee);
    }

	/**
     * VRF合约的回调函数, 验证随机数有效之后会自动被调用
     * 消耗随机数的逻辑写在这里
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }

	// 用户申请随机数时调用的requestRandomness()和VRF合约返回随机数时调用的
	// 回退函数fulfillRandomness()是两笔交易, 调用者分别是用户合约和VRF合约,
	// 后者比前者晚几分钟(不同链延迟不一样)
}


/*
	tokenId随机铸造的NFT

	利用链上和链下随机数来做一款tokenId随机铸造的NFT, Random合约继承
	ERC721和VRFConsumerBase合约
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Random is ERC721, VRFConsumerBase {
	// NFT相关
    uint256 public totalSupply = 100; // 总供给
    uint256[100] public ids; // 用于计算可供mint的tokenId
    uint256 public mintCount; // 已mint数量
    // chainlink VRF相关
    bytes32 internal keyHash;
    uint256 internal fee;
    // 记录VRF申请标识对应的mint地址
    mapping(bytes32 => address) public requestToSender; 


	// 构造函数
	// 初始化继承的VRFConsumerBase和ERC721合约的相关变量

   /**
     * 使用chainlink VRF, 构造函数需要继承 VRFConsumerBase 
     * 不同链参数填的不一样
     * 网络: Rinkeby测试网
     * Chainlink VRF Coordinator 地址: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
     * LINK 代币地址: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
     */
    constructor() 
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        )
        ERC721("WTF Random", "WTF")
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (VRF使用费，Rinkeby测试网)
    }

   /**
    * 输入uint256数字, 返回一个可以mint的tokenId
    * 算法过程可理解为: totalSupply个空杯子(0初始化的ids)排成一排, 每个杯子
		旁边放一个球, 编号为[0, totalSupply - 1]; 每次从场上随机拿走一个球(球可
		能在杯子旁边, 这是初始状态; 也可能是在杯子里, 说明杯子旁边的球已经被拿
		走过, 则此时新的球从末尾被放到了杯子里再把末尾的一个球(依然是可能在杯子
		里也可能在杯子旁边)放进被拿走的球的杯子里, 循环totalSupply次; 相比传统的
		随机排列，省去了初始化ids[]的gas; TODO
    */
    function pickRandomUniqueId(uint256 random) private returns (uint256 tokenId) {
        uint256 len = totalSupply - mintCount++; // 可mint数量
        require(len > 0, "mint close"); // 所有tokenId被mint完了
        uint256 randomIndex = random % len; // 获取链上随机数

        //随机数取模, 得到tokenId, 作为数组下标, 同时记录value为len-1, 
		// 如果取模得到的值已存在, 则tokenId取该数组下标的value
        tokenId = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex; // 获取tokenId
        ids[randomIndex] = ids[len - 1] == 0 ? len - 1 : ids[len - 1]; // 更新ids 列表
        ids[len - 1] = 0; // 删除最后一个元素，能返还gas
    }

   /**
    * 链上伪随机数生成
    * keccak256(abi.encodePacked()中填上一些链上的全局变量/自定义变量
    * 返回时转换成uint256类型
    */
    function getRandomOnchain() public view returns(uint256){
        // remix跑blockhash会报错
        bytes32 randomBytes = keccak256(abi.encodePacked(block.number, msg.sender, blockhash(block.timestamp-1)));
        return uint256(randomBytes);
    }

    // 利用链上伪随机数铸造NFT
    function mintRandomOnchain() public {
        uint256 _tokenId = pickRandomUniqueId(getRandomOnchain()); // 利用链上随机数生成tokenId
        _mint(msg.sender, _tokenId);
    }

	/**
     * 调用VRF获取随机数, 并mintNFT
     * 要调用requestRandomness()函数获取, 消耗随机数的逻辑写在VRF的
	 * 回调函数fulfillRandomness()中, 调用前把LINK代币转到本合约里
     */
    function mintRandomVRF() public returns (bytes32 requestId) {
        // 检查合约中LINK余额
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        // 调用requestRandomness获取随机数
        requestId = requestRandomness(keyHash, fee);
        requestToSender[requestId] = msg.sender;
        return requestId;
    }

    /**
     * VRF的回调函数, 由VRF Coordinator调用
     * 消耗随机数的逻辑写在本函数中
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        address sender = requestToSender[requestId]; // 从requestToSender中获取minter用户地址
        uint256 _tokenId = pickRandomUniqueId(randomness); // 利用VRF返回的随机数生成tokenId

        _mint(sender, _tokenId);
    }
}



