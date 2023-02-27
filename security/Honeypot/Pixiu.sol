// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*

	本节介绍貔貅合约和预防方法(英文习惯叫蜜罐代币 honeypot token)

	在Web3中, 貔貅为不详之兽, 韭菜的天敌;
	貔貅盘的特点: 投资人只能买不能卖, 仅有项目方地址能卖出;

	通常一个貔貅盘有如下的生命周期:
	1. 恶意项目方部署貔貅代币合约
	2. 宣传貔貅代币让散户上车, 由于只能买不能卖, 代币价格会一路走高
	3. 项目方rug pull卷走资金

	Pixiu 有一个状态变量pair, 用于记录uniswap中 Pixiu-ETH LP的币对地址;
	它主要有三个函数:
	1. 构造函数: 初始化代币的名称和代号, 并根据 uniswap 和 create2 的原理
		计算LP合约地址(TODO), 这个地址会在 _beforeTokenTransfer() 函数中用到;
	2. mint(): 铸造函数, 仅 owner 地址可以调用, 用于铸造 Pixiu 代币
	3. _beforeTokenTransfer(): ERC20代币在被转账前会调用的函数, 在其中限制
		了当转账的目标地址 to 为 LP 的时候, 也就是韭菜卖出的时候, 交易会
		revert; 只有调用者为owner的时候能够成功, 这也是貔貅合约的核心;

	Remix 复现:
	在 Goerli 测试网上部署 Pixiu 合约, 并在 uniswap 交易所中演示

	1. 部署 Pixiu 合约(在metamask添加 Goerli 网络,  Remix 环境选 Injected
		Provider - Metamask)
	2. 调用 mint() 函数, 给自己铸造 100000 枚貔貅币
	(TODO: 不能访问 uniswap 致后面几步未能验证)
	3. 进入 uniswap(https://app.uniswap.org/#/add/v2/ETH)交易所, 为貔貅币
		创造流动性(v2), 提供 10000貔貅币和 0.1 ETH
	4. 出售 100 貔貅币, 能够操作成功
	5. 切换到另一个账户, 使用 0.01ETH 购买貔貅币, 能够操作成功
	6. 出售貔貅币, 无法弹出交易

	预防:
	貔貅币是韭菜在链上梭哈最容易遇到的骗局, 并且形式多变, 预防非常有难度; 有以
	下几点建议, 可以降低被貔貅盘割韭菜的风险:
	1. 在区块链浏览器上(比如etherscan: https://etherscan.io/)查看合约是否开源, 
		如果开源, 则分析它的代码看是否有貔貅漏洞
	2. 如果没有编程能力, 可以使用貔貅识别工具, 比如 
		Token Sniffer (https://tokensniffer.com/)
		和 Ave Check(https://ave.ai/check),
		分低的话大概率是貔貅(TODO:熟练使用工具)
	3. 看项目是否有审计报告
	4. 仔细检查项目的官网和社交媒体

*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 极简貔貅ERC20代币, 只能买不能卖
contract HoneyPot is ERC20, Ownable {
    address public pair;

    // 构造函数: 初始化代币名称和代号
    constructor() ERC20("HoneyPot", "Pi Xiu") {
        address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // goerli uniswap v2 factory
        address tokenA = address(this); // 貔貅代币地址
        address tokenB = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; //  goerli WETH
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); //将tokenA和tokenB按大小排序
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // calculate pair address
        pair = address(uint160(uint(keccak256(abi.encodePacked(
        hex'ff', // == bytes1(0xff)
        factory,
        salt,
        hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
        )))));
    }

    /**
     * 铸造函数, 只有合约所有者可以调用
     */
    function mint(address to, uint amount) public onlyOwner {
        _mint(to, amount);
    }

	/**
     * @dev See {ERC20-_beforeTokenTransfer}.
     * 貔貅函数: 只有合约拥有者可以卖出
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        // 当转账的目标地址为 LP 时, 会revert
        if(to == pair){
            require(from == owner(), "Can not Transfer");
        }
    }
}
