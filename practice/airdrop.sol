/*

	空投是币圈中一种营销策略, 项目方将代币免费发放给特定用户群体; 为了拿到
	空投资格, 用户通常需要完成一些简单的任务，如测试产品、分享新闻、介绍朋友
	等; 项目方通过空投可以获得种子用户, 而用户可以获得一笔财富;

	因为每次接收空投的用户很多, 项目方不可能一笔一笔的转账; 利用智能合约
	批量发放ERC20代币, 可以显著提高空投效率


	空投代币合约
	Airdrop空投合约逻辑:
	利用循环, 一笔交易将ERC20代币发送给多个地址; 合约中包含2个函数:
	- getSum() 函数: 返回 uint 数组的和
		// 数组求和函数
		function getSum(uint256[] calldata _arr) public pure returns(uint sum)
		{
			for(uint i = 0; i < _arr.length; i++)
				sum = sum + _arr[i];
		}

	- multiTransferToken()函数: 发送ERC20代币空投, 包含3个参数
		- _token: 代币合约地址(address类型)
		- _addresses: 接收空投的用户地址数组(address[]类型)
		- _amounts: 空投数量数组, 对应_addresses里每个地址的数量（uint[]类型）

		// 向多个地址转账ERC20代币, 使用前需要先授权
		function multiTransferToken(
			address _token,
			address[] calldata _addresses,
			uint256[] calldata _amounts
			) external {
			// 检查: _addresses和_amounts数组的长度相等
			require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
			IERC20 token = IERC20(_token); // 声明IERC合约变量
			uint _amountSum = getSum(_amounts); // 计算空投代币总量

			// 检查: 授权代币数量 >= 空投代币总量
			require(token.allowance(msg.sender, address(this)) >= _amountSum, "Need Approve ERC20 token");
			
			// for循环, 利用transferFrom函数发送空投
			for (uint8 i; i < _addresses.length; i++) {
				token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
			}
		}


	发送 ETH 空投
	- multiTransferETH()函数: 发送ETH空投, 包含2个参数
		- _addresses: 接收空投的用户地址数组(address[]类型)
		- _amounts: 空投数量数组, 对应_addresses里每个地址的数量(uint[]类型)

		// 向多个地址转账ETH
		function multiTransferETH(
			address payable[] calldata _addresses,
			uint256[] calldata _amounts
		) public payable {
			// 检查: _addresses和_amounts数组的长度相等
			require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
			uint _amountSum = getSum(_amounts); // 计算空投ETH总量
			// 检查转入ETH等于空投总量
			require(msg.value == _amountSum, "Transfer amount error");
			// for循环, 利用transfer函数发送ETH
			for (uint256 i = 0; i < _addresses.length; i++) {
				_addresses[i].transfer(_amounts[i]);
			}
		}
	
*/

