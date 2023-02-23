/*
	权限管理漏洞
	智能合约中的权限管理定义了不同角色在应用中的权限; 通常来说, 代币的铸造、
	提取资金、暂停等功能都需要较高权限的用户才能调用, 如果权限配置错误, 
	就可能造成意想不到的损失; 以下介绍两种常见的权限管理漏洞:

	1. 权限配置错误
		如果合约中特殊功能没有加上权限管理, 那么任何人都能铸造大量代币或将合
		约中的资金提光;

		// 错误的mint函数，没有限制权限
		function badMint(address to, uint amount) public {
			_mint(to, amount);
		}

	2. 授权检查错误
		没有在函数中检查调用者是否拥有足够的授权; BSC上DeFi项目 ShadowFi 的
		代币合约忘了在 burn() 销毁函数中检查调用者的授权额度, 导致攻击者可
		以任意的销毁其他地址的代币; 在黑客将流动性池子中的代币销毁之后, 仅需
		卖出一点代币就可以将池子里的所有 BNB 提走, 获利 $300,000 (TODO:了解)

		// 错误的burn函数，没有限制权限
		function badBurn(address account, uint amount) public {
			_burn(account, amount);
		}

	
	预防办法:
	1. 使用 Openzeppelin 的权限管理库给合约的特殊函数配置相应的权限, 比如
		使用OnlyOwner修饰器, 只有合约所有者才能调用

		// 正确的mint函数, 使用 onlyOwner 修饰器限制权限
		function goodMint(address to, uint amount) public onlyOwner {
			_mint(to, amount);
		}

	2. 在函数的逻辑中确保合约调用者拥有足够的授权

		// 正确的burn函数，如果销毁的不是自己的代币，则会检查授权
		function goodBurn(address account, uint amount) public {
			if(msg.sender != account){
				_spendAllowance(account, msg.sender, amount);
			}
			_burn(account, amount);
		}


*/
