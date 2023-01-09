// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;  


/*
	重载
	solidity中允许函数进行重载(overloading), 即名字相同但输入参数类型不同的函
	数可以同时存在, 被视为不同的函数; 但是solidity不允许修饰器(modifier)重载;


	实参匹配
	在调用重载函数时, 会把输入的实际参数和函数参数的变量类型做匹配; 
	如果出现多个匹配的重载函数, 则会报错; 
	下面这个例子有两个叫f()的函数, 一个参数为uint8，另一个为uint256:
	    function f(uint8 _in) public pure returns (uint8 out) {
			out = _in;
		}

		function f(uint256 _in) public pure returns (uint256 out) {
			out = _in;
		}
	调用f(50), 因为50既可以被转换为uint8, 也可以被转换为uint256, 因此会报错;
*/


contract Overloading{
    function saySomething() public pure returns(string memory){
      return("Nothing");
    }

	function saySomething(string memory something) public pure returns(string memory){
        return(something);
    }
}

