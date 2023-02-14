// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;  

/**
 * @dev 逻辑合约, 执行被委托的调用
 * 代理合约利用delegatecall将函数调用委托给了另一个逻辑合约, 使得数据和逻辑分
 * 别由不同合约负责; 并利用内联汇编让没有返回值的回调函数也可以返回数据 (TODO)
 */
contract Logic {
	// TODO: 插槽冲突
    address public implementation; // 占位变量, 与Proxy保持一致, 防止插槽冲突 

    uint public x = 99; 
    event CallSuccess(); // 调用成功事件

    // 这个函数会释放CallSuccess事件并返回一个uint
    // 函数selector: 0xd09de08a
    function increment() external returns(uint) {
        emit CallSuccess();
        return x + 1;
		// 如果直接调用 increment() 会返回 100, 但是通过 Proxy 调用会返回1
		// 当Caller合约通过Proxy合约来delegatecall Logic合约的时候, 如果
		// Logic合约函数改变或读取一些状态变量的时候都会在Proxy的对应变量上
		// 操作, 而这里Proxy合约的x变量的值是0(因为从来没有设置过x这个变量, 
		// 即Proxy合约的storage区域所对应位置值为0), 所以通过Proxy调用
		// increment()会返回1
    }
}
