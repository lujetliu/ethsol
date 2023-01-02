// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/*
	函数类型
	function <function name>(<parameter types>) {internal|external|public|private} [pure|view|payable] [returns (<return types>)]
	[方括号中的是可写可不写的关键字]

	{internal|external|public|private}:	
		函数可见性说明符, 没标明的默认为public, 合约外的函数即"自由函数",
		始终具有隐含 internal 可见性;
	- public: 内部外部均可见
	- private: 只能从本合约内部访问, 继承的合约也不能访问
	- external: 只能从合约外部访问, 内部可以用 this.f()来调用
	- internal: 只能从合约内部访问, 继承的合约可以访问

	public|private|internal 可用于修饰状态变量, public 变量会自动生成同名的
	getter函数, 用于查询数值; 没有标明可见性类型的状态变量默认为 internal

	[pure|view|payable]: 决定函数权限/功能的关键字
	- payable: 可支付的, 运行的时候可以给合约转入ETH.
	- pure: 既不能读取也不能写入存储在链上的状态变量.
	- view: 能读取但不能写入状态变量.
	不写则默认既可以读取也可以写入状态变量.
	
	solodity 中使用pure 和 view 是因为 gas fee, 合约的状态变量存储在链上, 
	gas fee很贵, 如果不改变链上状态就不用付gas; 包含pure跟view关键字的函数
	是不改写链上状态的, 因此用户直接调用他们是不需要付gas的(合约中
	非pure/view函数调用它们则会改写链上状态, 需要付gas)

	在以太坊中, 以下语句被视为修改链上状态:
	- 写入状态变量.
	- 释放事件. TODO
	- 创建其他合约.
	- 使用selfdestruct. TODO
	- 通过调用发送以太币.
	- 调用任何未标记view或pure的函数.
	- 使用低级调用(low-level calls).
	- 使用包含某些操作码的内联汇编. TODO

*/

contract FunctionTypes{
    uint256 public number = 5;

    // 默认
    function add() external{
        number = number + 1;
    }

    // pure
    function addPure(uint256 _number) external pure returns(uint256 new_number){
        new_number = _number + 1;
    }

    // view
    function addView() external view returns(uint256 new_number) {
        new_number = number + 1;
    }

    // internal: 内部
    function minus() internal {
        number = number - 1;
    }

    // 合约内的函数可以调用内部函数
    function minusCall() external {
        minus();
    }


    // payable: 递钱, 能给合约支付eth的函数
    function minusPayable() external payable returns(uint256 balance) {
        minus();
        balance = address(this).balance;
    }


	// 返回多个变量
    function returnMultiple() public pure returns(uint256, bool, uint256[3] memory){
		// TODO: memory
        return(1, true, [uint256(1),2,5]);
    }

	// 命名式返回
    function returnNamed() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
        _number = 2;
        _bool = false;
        _array = [uint256(3),2,1];
    }

	// 解构式赋值
	// solidity使用解构式赋值的规则, 支持读取函数的全部或部分返回值.
	uint256 _number;
    bool _bool;
    uint256[3] memory _array;
    (_number, _bool, _array) = returnNamed();

	// 读取部分返回值
	(, _bool2, ) = returnNamed();
}


