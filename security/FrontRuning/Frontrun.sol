// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	抢先交易 Front-running
	传统抢跑
	抢跑最初诞生于传统金融市场, 是一场单纯为了利益的竞赛; 在金融市场中, 信息
	差催生了金融中介机构, 他们可以通过最先了解某些行业信息并最先做出反应从而
	实现获利, 这些攻击主要发生在股票市场交易和早期的域名注册

	一个传统抢跑的例子是在代币上币安/coinbase等知名交易所之前, 会有得知内幕消
	息的老鼠仓提前买入; 在上币的公告发出后, 币价会大幅上涨, 这时抢跑者卖出盈利;

	链上抢跑
	链上抢跑指的是搜索者或矿工通过调高gas或其他方法将自己的交易安插在其他交
	易之前来攫取价值; 在区块链中, 矿工可以通过打包、排除或重新排序他们产生的
	区块中的交易来获得一定的利润, 而MEV(TODO)是衡量这种利润的指标;

	在用户的交易被矿工打包进以太坊区块链之前, 大部分交易会汇集到 Mempool(交易
	内存池)中, 矿工在这里寻找费用高的交易优先打包出块, 实现利益最大化; 通常来
	说 gas price越高的交易, 越容易被打包; 一些MEV机器人也会搜索mempool中有利
	可图的交易; 
	比如, 一笔在去中心化交易所中滑点(TODO: 滑点?)设置过高的swap交易可能会被
	三明治攻击:
	通过调整gas, 套利者会在这笔交易之前插一个买单, 再在之后发送一个卖单并从中
	盈利, 这等效于哄抬市价; (TODO)

	抢跑实践:
	抢跑需要用到的工具:
	- Foundry的anvil工具搭建本地测试链, 请提前安装好
		foundry(https://book.getfoundry.sh/getting-started/installation)
	- remix进行NFT合约的部署和铸造
	- etherjs脚本监听mempool并进行抢跑

	1. 启动 Foundry 本地测试链
		运行 anvil --chain-id -b 10(10s出一个块)
	2. 将Remix连接到测试链
		Environment 选Foundry Provider即可将 Remix 连接到测试链
	3. 部署NFT合约
		在 Remix 中部署 ./Frontrun.sol 合约用户免费铸造NFT
	4. 部署 ethers.js 抢跑脚本
		运行 node ./frontrun.js 
		frontrun.js脚本监听了测试链mempool中的未决交易, 筛选出调用了mint()的
		交易, 然后复制它并调高gas进行抢跑
	5. 调用mint()函数
	6. 脚本监听到交易并进行抢跑
		可以在终端看到 frontrun.js 脚本成功监听到了交易, 并进行了抢跑; 如果
		调用 NFT 合约的 ownerOf() 函数查看 tokenId 为 0 的持有者是抢跑脚本中
		的钱包地址, 证明抢跑成功

	预防方法:
	抢先交易是以太坊等公链上普遍存在的问题, 没法消除它, 但是可以通过减少交易
	顺序或时间的重要性, 减少被抢先交易的收益: TODO
	1. 使用预提交方案(commit-reveal scheme) 
	2. 使用暗池, 用户发出的交易将不进入公开的mempool, 而是直接到矿工手里; 
		例如 flashbots 和 TaiChi(TODO)

*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// 尝试frontrun一笔Free mint交易
contract FreeMint is ERC721 {
    uint256 public totalSupply;

    // 构造函数，初始化NFT合集的名称、代号
    constructor() ERC721("Free Mint NFT", "FreeMint"){}

    // 铸造函数
    function mint() external {
        _mint(msg.sender, totalSupply); // mint
        totalSupply++;
    }
}
