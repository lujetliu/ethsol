// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	引用类型:
	引用类型(Reference Type): 包括数组(array), 结构体(struct)和映射(mapping),
	这类变量占空间大,赋值时候直接传递地址(类似指针); 由于这类变量比较复杂, 
	占用存储空间大, 我们在使用时必须要声明数据存储的位置.

	solidity数据存储位置有三类: storage, memory和calldata
	不同存储位置的gas成本不同, storage类型的数据存在链, 上类似计算机的硬盘, 消耗gas多;
	memory和calldata类型的临时存在内存里, 消耗gas少; 
	- storage: 合约里的状态变量默认都是 storage, 存储在链上
	- memory: 函数里的参数和临时变量一般用 memory, 存储在内存中, 不上链
	- calldata: 和 memory 类似, 存储在内存中, 不上链; 但是 calldata 变量不能
		修改(immutable), 一般用于函数的参数.

	function fCalldata(uint[] calldata _x) public pure returns(uint[] calldata){
        //参数为calldata数组，不能被修改
        // _x[0] = 0 //这样修改会报错
        return(_x);
    }

	数据位置和赋值规则
	在不同存储类型相互赋值的时候,有时会产生独立的副本(修改新变量不会影响原变量),
	有时会产生引用(修改新变量会影响原变量)
	1. storage(合约的状态变量)赋值给本地 storage(函数里的)时候会创建引用, 
		修改新变量会影响原变量
		
		uint[] x = [1,2,3]; // 状态变: 数组 x
		function fStorage() public{
			//声明一个storage的变量 xStorage, 指向x; 修改xStorage也会影响x
			uint[] storage xStorage = x;
			xStorage[0] = 100;
		}

	2. storage 赋值给 memory, 会创建独立的副本, 修改其中一个不会影响另一个

		uint[] x = [1,2,3]; // 状态变量: 数组 x
		function fMemory() public view{
			//声明一个Memory的变量xMemory, 复制x; 修改xMemory不会影响x
			uint[] memory xMemory = x;
			xMemory[0] = 100;
			xMemory[1] = 200;
			uint[] memory xMemory2 = x;
			xMemory2[0] = 300;
		}
			

	3. memory 赋值给 memory 会创建引用, 改变新变量会影响原变量

	4. 其他情况, 变量赋值给storage, 会创建独立的副本,修改其中一个不会影响另一个


	变量的作用域:
	Solidity中变量按作用域划分有三种, 分别是状态变量(state variable),
	局部变量(local variable)和全局变量(global variable)

	1. 状态变量
		状态变量是数据存储在链上的变量, 所有合约内函数都可以访问, gas消耗高;
		状态变量在合约内、函数外声明:
		contract Variables {
			uint public x = 1;
			uint public y;
			string public z;

			可以在函数里更改状态变量的值:
			function foo() external{
				// 可以在函数里更改状态变量的值
				x = 5;
				y = 2;
				z = "0xAA";
			}


	2. 局部变量
		局部变量是仅在函数执行过程中有效的变量, 函数退出后变量无效; 
		局部变量的数据存储在内存里, 不上链, gas低; 局部变量在函数内声明：
		function bar() external pure returns(uint){
			uint xx = 1;
			uint yy = 3;
			uint zz = xx + yy;
			return(zz);
		}

	3. 全局变量
		全局变量是全局范围工作的变量, 都是solidity预留关键字; 可以在函数内
		不声明直接使用:
		function global() external view returns(address, uint, bytes memory){
			address sender = msg.sender; // 请求发起地址
			uint blockNum = block.number; // 当前区块高度
			bytes memory data = msg.data; // 请求数据
			return(sender, blockNum, data);
		}

	   常用的全局变量: 
	   https://learnblockchain.cn/docs/solidity/units-and-global-variables.html#special-variables-and-functions

		- blockhash(uint blockNumber): (bytes32)给定区块的哈希值 – 只适用于256最近区块, 不包含当前区块。
		- block.coinbase: (address payable) 当前区块矿工的地址
		- block.gaslimit: (uint) 当前区块的gaslimit
		- block.number: (uint) 当前区块的number
		- block.timestamp: (uint) 当前区块的时间戳，为unix纪元以来的秒
		- gasleft(): (uint256) 剩余 gas
		- msg.data: (bytes calldata) 完整call data
		- msg.sender: (address payable) 消息发送者 (当前 caller)
		- msg.sig: (bytes4) calldata的前四个字节 (function identifier)
		- msg.value: (uint) 当前交易发送的wei值
*/



