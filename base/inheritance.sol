// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	继承
	继承是面向对象编程很重要的组成部分, 可以显著减少重复代码; 如果把合约看作
	是对象的话, solidity也是面向对象的编程, 也支持继承

	规则:
	- virtual: 父合约中的函数, 如果希望子合约重写, 需要加上virtual关键字
	- override: 子合约重写了父合约中的函数, 需要加上override关键字

	用override修饰public变量, 会重写与变量同名的getter函数:
	mapping(address => uint256) public override balanceOf;

*/

/*
	简单继承
	contract Yeye { // 爷爷合约
		event Log(string msg);

		// 定义3个function: hip(), pop(), man(), Log值为Yeye。
		function hip() public virtual{
			emit Log("Yeye");
		}

		function pop() public virtual{
			emit Log("Yeye");
		}

		function yeye() public virtual {
			emit Log("Yeye");
		}
	}

	contract Baba is Yeye{ // 爸爸合约继承爷爷合约
		// 继承两个function: hip()和pop(), 输出改为Baba
		function hip() public virtual override{
			emit Log("Baba");
		}

		function pop() public virtual override{
			emit Log("Baba");
		}

		function baba() public virtual{
			emit Log("Baba");
		}
	}

*/

/*
	多重继承
	solidity的合约可以继承多个合约;
	规则:
	- 继承时要按辈分最高到最低的顺序排, 比如我们写一个Erzi合约, 继承Yeye合约
		和Baba合约, 那么就要写成contract Erzi is Yeye, Baba, 而不能写成
		contract Erzi is Baba, Yeye, 不然就会报错

	- 如果某一个函数在多个继承的合约里都存在, 比如例子中的hip()和pop(), 在
		子合约里必须重写, 不然会报错

	- 重写在多个父合约中都重名的函数时, override关键字后面要加上所有父合约
		名字, 例如override(Yeye, Baba)
	
	TODO: 释放的事件也可以从父合约里继承吗?

	contract Erzi is Yeye, Baba{
		// 继承两个function: hip()和pop(), 输出值为Erzi
		function hip() public virtual override(Yeye, Baba){
			emit Log("Erzi");
		}

		function pop() public virtual override(Yeye, Baba) {
			emit Log("Erzi");
		}
	}



*/

contract Inheritance{
}
