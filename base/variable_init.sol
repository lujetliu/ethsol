// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	在solidity中, 声明但没赋值的变量都有它的初始值或默认值

	值类型初始值:
		boolean: false
		string: ""
		int: 0
		uint: 0
		enum: 枚举中的第一个元素
		address: 0x0000000000000000000000000000000000000000 (或 address(0))
		function:
			internal: 空白方程
			external: 空白方程
	
	引用类型初始值:
		映射mapping: 所有元素都为其默认值的mapping
		结构体struct: 所有成员设为其默认值的结构体
		数组array:
			动态数组: []
			静态数组(定长): 所有成员设为其类型的默认值

*/

contract VariableInit{
	 // Value Types
    bool public _bool; // false
    string public _string; // ""
    int public _int; // 0
    uint public _uint; // 0
    address public _address; // 0x0000000000000000000000000000000000000000

    enum ActionSet { Buy, Hold, Sell}
    ActionSet public _enum; // 第1个内容Buy的索引0

    function fi() internal{} // internal空白方程
    function fe() external{} // external空白方程

	 // Reference Types
    uint[8] public _staticArray; // 所有成员设为其默认值的静态数组[0,0,0,0,0,0,0,0]
    uint[] public _dynamicArray; // `[]`
    mapping(uint => address) public _mapping; // 所有元素都为其默认值的mapping
    // 所有成员设为其默认值的结构体 0, 0
    struct Student{
        uint256 id;
        uint256 score;
    }
    Student public student;

	// delete操作符
	// delete a会让变量a的值变为初始值。
    bool public _bool2 = true;
    function d() external {
        delete _bool2; // delete 会让_bool2变为默认值, false
    }
}
