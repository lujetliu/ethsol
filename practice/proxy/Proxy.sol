// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;  

/*
	代理模式
	Solidity合约部署在链上之后代码是不可变的(immutable), 这样既有优点也有缺点:
	- 优点: 安全, 用户知道会发生什么(大部分时候)
	- 坏处: 就算合约中存在bug也不能修改或升级, 只能部署新合约; 但是新合约的
		地址与旧的不一样, 且合约的数据也需要花费大量gas进行迁移

	使用代理模式可以在合约部署后进行修改和升级


	代理合约将数据和逻辑分开:
                                        代理合约                逻辑合约
		调用者 ---------call--------->   Proxy  ------------> Implementation
									存储逻辑合约地址

	代理模式将合约数据和逻辑分开, 分别保存在不同合约中; 以上图中简单的代理
	合约为例, 数据(状态变量)存储在代理合约中, 而逻辑(函数)保存在另一个逻辑
	合约中; 代理合约(Proxy)通过delegatecall, 将函数调用全权委托给逻辑合约
	(Implementation)执行, 再把最终的结果返回给调用者(Caller) TODO

	代理模式的优点:
	1. 可升级: 当我们需要升级合约的逻辑时, 只需要将代理合约指向新的逻辑合约
	2. 省gas: 如果多个合约复用一套逻辑, 只需部署一个逻辑合约, 然后再部署多
		个只保存数据的代理合约, 指向逻辑合约 TODO


	代理合约例子
	由 OpenZeppelin的Proxy合约, 由三个部分组成: 代理合约(Proxy), 
	逻辑合约(Logic), 和一个调用示例(Caller);
	- 首先部署逻辑合约Logic
	- 创建代理合约Proxy, 状态变量implementation记录Logic合约地址
	- Proxy合约利用回调函数fallback, 将所有调用委托给Logic合约
	- 最后部署调用示例Caller合约, 调用Proxy合约

	Logic合约和Proxy合约的状态变量存储结构必须相同, 不然delegatecall会产生意
	想不到的行为, 有安全隐患 (TODO: 实验)
*/


contract Proxy {
    address public implementation; // 逻辑合约地址
	// implementation合约同一个位置的状态变量类型必须和Proxy合约的相同, 
	// 不然会报错

    /**
     * @dev 初始化逻辑合约地址
     */
    constructor(address implementation_){
        implementation = implementation_;
    }

   /** TODO: 内联汇编
	* @dev 回调函数, 将本合约的调用委托给 `implementation` 合约
	* 这个回调函数很别致, 它利用内联汇编(inline assembly), 让本来不能有返
	* 回值的回调函数有了返回值 
	*/
	fallback() external payable {
		address _implementation = implementation;
		assembly {
			// 将msg.data拷贝到内存里
			// calldatacopy操作码的参数: 内存起始位置, calldata起始位置, calldata长度
			calldatacopy(0, 0, calldatasize())

			// 利用delegatecall调用implementation合约
			// delegatecall操作码的参数: gas,  目标合约地址, input mem起始位置,
			//		input mem长度, output area mem起始位置, output area mem长度
			// output area起始位置和长度位置, 所以设为0 ???
			// delegatecall成功返回1, 失败返回0
			let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

			// 将return data拷贝到内存
			// returndata操作码的参数: 内存起始位置, returndata起始位置, returndata长度
			returndatacopy(0, 0, returndatasize())

			switch result
			// 如果delegate call失败, revert
			case 0 {
				revert(0, returndatasize())
			}
			// 如果delegate call成功, 返回mem起始位置为0, 长度为
			// returndatasize()的数据(格式为bytes)
			default {
				return(0, returndatasize())
			}
		}
	}

