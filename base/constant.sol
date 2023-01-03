// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	constant(常量) 和 immutable(不变量)
	状态变量声明这个两个关键字之后, 不能在合约后更改数值; 并且还可以节省gas; 
	另外, 只有数值变量可以声明constant和immutable; string和bytes可以声明
	为constant, 但不能为immutable;

	constant:
		constant变量必须在声明的时候初始化, 之后再也不能改变, 尝试改变则编译不通过

		// constant变量必须在声明的时候初始化，之后不能改变
		uint256 constant CONSTANT_NUM = 10;
		string constant CONSTANT_STRING = "0xAA";
		bytes constant CONSTANT_BYTES = "WTF";
		address constant CONSTANT_ADDRESS = 0x0000000000000000000000000000000000000000;

	immutable:
		immutable变量可以在声明时或构造函数中初始化, 因此更加灵活

	    // immutable变量可以在constructor里初始化, 之后不能改变
		uint256 public immutable IMMUTABLE_NUM = 9999999999;
		address public immutable IMMUTABLE_ADDRESS;
		uint256 public immutable IMMUTABLE_BLOCK;
		uint256 public immutable IMMUTABLE_TEST;


*/

contract ConstantAndImmutable{
	IMMUTABLE_ADDRESS = address(this);
	IMMUTABLE_BLOCK = block.number;
	IMMUTABLE_TEST = test();

    function test() public pure returns(uint256){
        uint256 what = 9;
        return(what);
    }
}
