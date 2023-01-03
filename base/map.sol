// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	声明映射的格式为mapping(_KeyType => _ValueType), 其中_KeyType和_ValueType
	分别是Key和Value的变量类型
	mapping(uint => address) public idToAddress; // id映射到地址
    mapping(address => address) public swapPair; // 币对的映射，地址到地址(交易对)

	映射规则:
	1. 映射的_KeyType只能选择solidity默认的类型, 比如uint，address等, 
		不能用自定义的结构; 而_ValueType可以使用自定义的类型;
		下面这个例子会报错, 因为_KeyType使用了我们自定义的结构体
		// 定义一个结构体 Struct
		struct Student{
			uint256 id;
			uint256 score;
		}
		mapping(Student => uint) public testVar;

	2. 映射的存储位置必须是 storage, 因此可以用于合约的状态变量; 函数中的
		storage 变量, 和 library 函数的参数, 不能用于 public 函数的参数和
		返回结果中, 因为 mapping 记录的是一种关系(key-value pair)

	3. 如果映射声明为public, 那么solidity会自动创建一个getter函数, 
		可以通过Key来查询对应的Value

	4. 给映射新增的键值对的语法为_Var[_Key] = _Value, 其中_Var是映射变量名,
		_Key和_Value对应新增的键值对


	映射的原理:
		1. 映射不存储任何键(key)的信息, 也没有length的信息
		2. 映射使用 keccak256(key) 当成 offset 存取 value
		3. 因为Ethereum会定义所有未使用的空间为0, 所以未赋值(Value)的键(Key)
			初始值都是各个type的默认值, 如uint的默认值是0
*/

contract MapType{
	mapping(uint => address) public idToAddress; // id映射到地址
    mapping(address => address) public swapPair; // 币对的映射，地址到地址(交易对)

	function writeMap (uint _Key, address _Value) public{
		idToAddress[_Key] = _Value;
	}
}
