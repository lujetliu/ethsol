// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	构造函数
	构造函数 constructor 是一种特殊的函数, 每个合约可以定义一个, 并在部署合约
	的时候自动运行一次; 可以用来初始化合约的一些参数, 例如初始化合约的 owner
	地址
	
	address owner; // 定义owner变量(状态变量)

	// 构造函数
	constructor() {
		owner = msg.sender; // 在部署合约的时候，将owner设置为部署者的地址
	}
	
	修饰器
	修饰器(modifier)是solidity特有的语法, 类似于面向对象编程中的decorator,
	声明函数拥有的特性, 并减少代码冗余;
	modifier的主要使用场景是运行函数前的检查, 例如地址, 变量, 余额等;
*/



contract Owner{
	address owner; // 定义owner变量

   // 构造函数
   constructor() {
      owner = msg.sender; // 在部署合约的时候，将owner设置为部署者的地址
   }

    // 定义modifier
   modifier onlyOwner {
      require(msg.sender == owner); // 检查调用者是否为owner地址
      _; // 如果是的话，继续运行函数主体；否则报错并revert交易
   }


   // 带有onlyOwner修饰符的函数只能被owner地址调用, 如下:
    function changeOwner(address _newOwner) external onlyOwner{
      owner = _newOwner; // 只有owner地址运行这个函数才能改变owner
   }

   // 定义了一个changeOwner函数, 运行他可以改变合约的owner, 
   // 但是由于onlyOwner修饰符的存在, 只有原先的owner可以调用,
   // 别人调用就会报错; 这也是最常用的控制智能合约权限的方法

   // OppenZepplin的Ownable标准实现 
   // OppenZepplin是一个维护solidity标准化代码库的组织，他的Ownable标准实现:
   // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
}
