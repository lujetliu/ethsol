// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/*
	数组(Array)是solidity常用的一种变量类型, 用来存储一组数据(整数, 字节,
	地址等等); 数组分为固定长度数组和可变长度数组两种;

	创建数组的规则
	- 对于 memory 修饰的动态数组, 可以用 new 操作符来创建, 但是必须声明长度, 
		并且声明后长度不能改变
		// memory动态数组
		uint[] memory array8 = new uint[](5);
		bytes memory array9 = new bytes(9);

	- 数组字面常数(Array Literals)是写作表达式形式的数组, 用方括号包着来初始
		化array的一种方式, 并且里面每一个元素的type是以第一个元素为准的, 
		例如[1,2,3]里面所有的元素都是uint8类型, 因为在solidity中如果一个值
		没有指定type的话, 默认就是最小单位的该type, 这里int的默认最小单位类
		型就是uint8; 而[uint(1),2,3]里面的元素都是uint类型, 因为第一个元素
		指定了是uint类型了, 都以第一个元素为准;  

	数组成员
	- length: 数组有一个包含元素数量的length成员, memory数组的长度在创建后是固定的
	- push(): 动态数组和bytes拥有push()成员, 可以在数组最后添加一个0元素
	- push(x): 动态数组和bytes拥有push(x)成员, 可以在数组最后添加一个x元素
	- pop(): 动态数组和bytes拥有pop()成员, 可以移除数组最后一个元素

*/

contract ArrayType{
	// 固定长度 Array
    uint[8] array1;
    bytes1[5] array2;
    address[100] array3;

	// 可变长度 Array
    uint[] array4;
    bytes1[] array5;
    address[] array6;
    bytes array7;

	// bytes比较特殊, 是数组, 但是不用加[]; 另外, 不能用byte[]声明单字节数组,
	// 可以使用bytes或bytes1[]; 在gas上, bytes比bytes1[]便宜; 因为bytes1[]在
	// memory中要增加31个字节进行填充, 会产生额外的gas; 但是在storage中, 
	// 由于内存紧密打包, 不存在字节填充



	// 下面的合约中, 对于f函数里面的调用, 如果没有显式对第一个元素进行uint
	// 强转的话是会报错的, 因为如上所述我们其实是传入了uint8类型的array, 
	// 可是g函数需要的却是uint类型的array, 就会报错
	function f() public pure {
        g([uint(1), 2, 3]);
    }

    function g(uint[3] memory) public pure {
        // ...
    }


	// 如果创建的是动态数组, 需要一个一个元素的赋值
	uint[] memory x = new uint[](3);
    x[0] = 1;
    x[1] = 3;
    x[2] = 4;

}

