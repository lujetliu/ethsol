// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	中心化风险
	中心化风险指智能合约的所有权是中心化的, 例如合约的owner由一个地址控制, 
	它可以随意修改合约参数, 甚至提取用户资金; 中心化的项目存在单点风险, 
	可以被恶意开发者(内鬼)或黑客利用, 只需要获取具有控制权限地址的私钥之后, 
	就可以通过rug-pull, 无限铸币或其他类型方法盗取资金;

	伪去中心化风险
	伪去中心化的项目通常对外鼓吹自己是去中心化的, 但实际上和中心化项目一样
	存在单点风险; 比如使用多签钱包来管理智能合约, 但几个多签人是一致行动人, 
	背后由一个人控制; 这类项目由于包装的很去中心化, 容易得到投资者信任, 
	所以当黑客事件发生时, 被盗金额也往往更大;


	中心化风险通过分析合约代码就可以发现, 而伪去中心化风险藏的更深, 需要对
	项目进行细致的尽职调查才能发现


	减少中心化/伪去中心化风险
	1. 使用多签钱包管理国库和控制合约参数(TODO); 为了兼顾效率和去中心化, 
		可以选择 4/7 或 6/9 多签; 
	2. 多签的持有人要多样化, 分散在创始团队、投资人、社区领袖之间, 并且不要相
		互授权签名
	3. 使用时间锁控制合约, 在黑客或项目内鬼修改合约参数/盗取资产时, 项目方
		和社区有一些时间来应对, 将损失最小化

*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 漏洞合约
// owner地址可以任意铸造代币的ERC20合约; 当项目内鬼或黑客取得owner的私钥后, 
// 可以无限铸币造成投资人大量损失
contract Centralization is ERC20, Ownable {
    constructor() ERC20("Centralization", "Cent") {
        address exposedAccount = 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2;
        transferOwnership(exposedAccount);
    }

    function mint(address to, uint256 amount) external onlyOwner{
        _mint(to, amount);
    }
}
