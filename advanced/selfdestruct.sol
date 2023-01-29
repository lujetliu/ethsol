/*
	selfdestruct
	selfdestruct命令可以用来删除智能合约, 并将该合约剩余ETH转到指定地址;
	selfdestruct是为了应对合约出错的极端情况而设计的.
	用法:
	selfdestruct(_addr) // 其中_addr是接收合约中剩余ETH的地址


	contract DeleteContract {
		uint public value = 10;
		constructor() payable {}
		receive() external payable {}
		function deleteContract() external {
			// 调用selfdestruct销毁合约，并把剩余的ETH转给msg.sender
			selfdestruct(payable(msg.sender));
		}

		function getBalance() external view returns(uint balance){
			balance = address(this).balance;
		}
	}

	在DeleteContract合约中, 写了一个public状态变量value, 两个函数:
	getBalance()用于获取合约ETH余额, deleteContract()用于自毁合约, 并把ETH
	转入给发起人￼

	注意:
	1. 对外提供合约销毁接口时, 最好设置为只有合约所有者可以调用, 可以使用
		函数修饰符onlyOwner进行函数声明
	2. 当合约被销毁后与智能合约的交互也能成功, 并且返回0
	3. 当合约中有selfdestruct功能时常常会带来安全问题和信任问题, 合约中的
		Selfdestruct功能会为攻击者打开攻击向量(例如使用selfdestruct向一个
		合约频繁转入token进行攻击, 这将大大节省了GAS的费用, 虽然很少人这么做),
		此外此功能还会降低用户对合约的信心(TODO)


	selfdestruct是智能合约的紧急按钮, 销毁合约并将剩余ETH转移到指定账户; 
	当著名的The DAO攻击发生时, 以太坊的创始人们一定后悔过没有在合约里加入
	selfdestruct来停止黑客的攻击.
*/
