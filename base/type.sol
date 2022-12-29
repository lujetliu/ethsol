// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	变量类型:
	- 数值类型(Value Type):
		包括布尔型, 整数型等等, 这类变量赋值时候直接传递数值.
	- 引用类型(Reference Type):
		包括数组和结构体, 这类变量占空间大, 赋值时候直接传递地址(类似指针).
	- 映射类型(Mapping Type): Solidity里的哈希表.
	- 函数类型(Function Type)
*/

// 数值类型
contract HelloWeb3{
    string public _string = "Hello Web3!";

    // 布尔值
    bool public _bool = true;

    // 布尔运算
    bool public _bool1 = !_bool; //取非
    bool public _bool2 = _bool && _bool1; //与
    bool public _bool3 = _bool || _bool1; //或
    bool public _bool4 = _bool == _bool1; //相等
    bool public _bool5 = _bool != _bool1; //不相等

    // 整型
    int public _int = -1; // 整数，包括负数
    uint public _uint = 1; // 正整数
    uint256 public _number = 20220330; // 256位正整数

    // 整数运算
    uint256 public _number1 = _number + 1; // +，-，*，/
    uint256 public _number2 = 2**2; // 指数
    uint256 public _number3 = 7 % 2; // 取余数
    bool public _numberbool = _number2 > _number3; // 比大小

    // 地址
    // 地址类型(address)存储一个 20 字节的值（以太坊地址的大小）。地址类型也有成员变量，并作为所有合约的基础。
    // 有普通的地址和可以转账ETH的地址（payable）。其中，payable修饰的地址相对普通地址多了transfer和send两个成员。
    // 在payable修饰的地址中，send执行失败不会影响当前合约的执行（但是返回false值，需要开发人员检查send返回值）。
    // balance和transfer()，可以用来查询ETH余额以及安全转账（内置执行失败的处理）。
    address public _address = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
    address payable public _address1 = payable(_address); // payable address，可以转账、查余额
    // 地址类型的成员
    uint256 public balance = _address1.balance; // balance of address


    // 固定长度的字节数组
    bytes32 public _byte32 = "MiniSolidity";
    bytes1 public _byte = _byte32[0];

    // 枚举类型
    // 用enum将uint 0， 1， 2表示为Buy, Hold, Sell
    enum ActionSet { Buy, Hold, Sell }
    // 创建enum变量 action
    ActionSet action = ActionSet.Buy;

    // enum可以和uint显式的转换
    function enumToUint() external view returns(uint){
        return uint(action);
    }
}
