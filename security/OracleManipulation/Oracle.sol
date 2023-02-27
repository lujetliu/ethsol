// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	价格预言机
	出于安全性的考虑, 以太坊虚拟机(EVM)是一个封闭孤立的沙盒; 在EVM上运行的
	智能合约可以接触链上信息, 但无法主动和外界沟通获取链下信息; 但是, 这类
	信息对去中心化应用非常重要; 预言机(oracle)可以解决这个问题, 它从链下数
	据源获得信息, 并将其添加到链上, 供智能合约使用;

	其中最常用的就是价格预言机(price oracle), 可以指代任何可以让你查询币价
	的数据源; 典型案例:
	- 去中心借贷平台(AAVE)使用它来确定借款人是否已达到清算阈值
	- 合成资产平台(Synthetix)使用它来确定资产最新价格, 并支持 0 滑点交易
	- MakerDAO使用它来确定抵押品的价格, 并铸造相应的稳定币 $DAI

	使用 Foundry 复现
	https://github.com/AmazingAng/WTF-Solidity/blob/main/S15_OracleManipulation/readme.md
	输出:
	Running 1 test for test/OracleTest.sol:OracleTest
	[PASS] testOracleAttack() (gas: 356494)
	Logs:
	  1. ETH Price (before attack): 1216
	  2. Swap 1,000,000 BUSD to WETH to manipulate the oracle
	  3. ETH price (after attack): 17979841782699
	  4. Minted 1797984178269 oUSD with 1 ETH (after attack)

	Test result: ok. 1 passed; 0 failed; finished in 16.26s


	预防:
	1. 不要使用流动性差的池子做价格预言机
	2. 不要使用现货/瞬时价格做价格预言机, 要加入价格延迟, 例如时间加权平均
		价格(TWAP) TODO
	3. 使用去中心化的预言机
	4. 使用多个数据源, 每次选取最接近价格中位数的几个作为预言机, 避免极端情况
	5. 仔细阅读第三方价格预言机的使用文档及参数设置

*/

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract oUSD is ERC20{
    // 主网合约
    address public constant FACTORY_V2 =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;

    IUniswapV2Factory public factory = IUniswapV2Factory(FACTORY_V2);
    IUniswapV2Pair public pair = IUniswapV2Pair(factory.getPair(WETH, BUSD));
    IERC20 public weth = IERC20(WETH);
    IERC20 public busd = IERC20(BUSD);

    constructor() ERC20("Oracle USD","oUSD"){}

    // 获取ETH price
    function getPrice() public view returns (uint256 price) {
        // pair 交易对中储备
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        // ETH 瞬时价格
        price = reserve0/reserve1;
    }

	/*
		针对有漏洞的价格预言机 getPrice() 函数进行攻击
		攻击思路:
		1. 准备一些 BUSD, 可以是自有资金, 也可以是闪电贷借款; 在实现中, 
			利用 Foundry 的 deal cheatcode 在本地网络上给自己铸造了 1,000,000 BUSD
		2. 在 UniswapV2 的 WETH-BUSD 池中大量买入 WETH; 具体实现见攻击代
			码的 swapBUSDtoWETH() 函数
		3. WETH 瞬时价格暴涨, 这时调用 swap() 函数将 ETH 转换为 oUSD
		4. 可选: 在 UniswapV2 的 WETH-BUSD 池中卖出第2步买入的 WETH, 收回本金
		这4步可以在一个交易中完成

	*/

    function swap() external payable returns (uint256 amount){
        // 获取价格
        uint price = getPrice();
        // 计算兑换数量
        amount = price * msg.value;
        // 铸造代币
        _mint(msg.sender, amount);
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);
}

interface IUniswapV2Router {
    //  swap相关
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    //  流动性相关
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function factory() external view returns (address);
}

