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


/*
	修饰器的继承
	Solidity中的修饰器(Modifier)同样可以继承, 用法与函数继承类似, 
	在相应的地方加virtual和override关键字即可

	contract Base1 {
		modifier exactDividedBy2And3(uint _a) virtual {
			require(_a % 2 == 0 && _a % 3 == 0);
			_; // TODO:?
		}
	}

	contract Identifier is Base1 {
		//计算一个数分别被2除和被3除的值，但是传入的参数必须是2和3的倍数
		function getExactDividedBy2And3(uint _dividend) public exactDividedBy2And3(_dividend) pure returns(uint, uint) {
			return getExactDividedBy2And3WithoutModifier(_dividend);
		}

		//计算一个数分别被2除和被3除的值
		function getExactDividedBy2And3WithoutModifier(uint _dividend) public pure returns(uint, uint){
			uint div2 = _dividend / 2;
			uint div3 = _dividend / 3;
			return (div2, div3);
		}
	}

	Identifier合约可以直接在代码中使用父合约中的exactDividedBy2And3修饰器,
	也可以利用override关键字重写修饰器:
	modifier exactDividedBy2And3(uint _a) override {
        _;
        require(_a % 2 == 0 && _a % 3 == 0);
    }
*/

/*
	构造函数的继承
	子合约有两种方法继承父合约的构造函数, 以如下合约为例:

	// 构造函数的继承
	abstract contract A {
		uint public a;

		constructor(uint _a) {
			a = _a;
		}
	}

	- 在继承时声明父构造函数的参数, 例如: contract B is A(1)
	- 在子合约的构造函数中声明构造函数的参数，例如:

	contract C is A {
		constructor(uint _c) A(_c * _c) {}
	}
*/

/*
	子合约调用父合约的函数
	子合约有两种方式调用父合约的函数, 直接调用和利用super关键字;
	1. 直接调用

		子合约可以直接用父合约名.函数名()的方式来调用父合约函数, 例如Yeye.pop()
		 function callParent() public{
			Yeye.pop();
		}

	2. super 关键字
		子合约可以利用super.函数名()来调用最近的父合约函数, solidity继承关系
		按声明时从右到左的顺序是: contract Erzi is Yeye, Baba, 那么Baba是最
		近的父合约, super.pop()将调用Baba.pop()而不是Yeye.pop()

		function callParentSuper() public{
			// 将调用最近的父合约函数，Baba.pop()
			super.pop();
		}

*/

/*
	钻石继承
	在面向对象编程中, 钻石继承(菱形继承)指一个派生类同时有两个或两个以上的基类

	在多重+菱形继承链条上使用super关键字时, 需要注意的是使用super会调用继承
	链条上的每一个合约的相关函数, 而不是只调用最近的父合约;

	写一个合约God, 再写Adam和Eve两个合约继承God合约, 最后创建合约people继承
	自Adam和Eve, 每个合约都有foo和bar两个函数:

*/

/* 
	继承树：
	  God
	 /  \
	Adam Eve
	 \  /
	people
*/

contract God {
    event Log(string message);

    function foo() public virtual {
        emit Log("God.foo called");
    }

    function bar() public virtual {
        emit Log("God.bar called");
    }
}

contract Adam is God {
    function foo() public virtual override {
        emit Log("Adam.foo called");
		Adam.foo(); // TODO: 在函数的定义里调用函数?
    }

    function bar() public virtual override {
        emit Log("Adam.bar called");
        super.bar();
    }
}

contract Eve is God {
    function foo() public virtual override {
        emit Log("Eve.foo called");
        Eve.foo(); // TODO: 在函数的定义里调用函数?
    }

    function bar() public virtual override {
        emit Log("Eve.bar called");
        super.bar();
    }
}

contract people is Adam, Eve {
    function foo() public override(Adam, Eve) {
        super.foo();
    }

    function bar() public override(Adam, Eve) {
        super.bar();
    }
}


