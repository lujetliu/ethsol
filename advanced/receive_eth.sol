// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	Solidity支持两种特殊的回调函数: receive()和fallback(), 主要在两种情况下被使用
	1. 接收ETH
	2. 处理合约中不存在的函数调用(代理合约proxy contract) TODO


	接收ETH函数 receive
	receive()只用于处理接收ETH, 一个合约最多有一个receive()函数, 声明时不需要
	function关键字: 
	receive() external payable { ... }
	receive()函数不能有任何的参数, 不能返回任何值, 必须包含external和payable

	TODO
	当合约接收ETH的时候, receive()会被触发; receive()最好不要执行太多的逻辑
	因为如果别人用send和transfer方法发送ETH的话, gas会限制在2300, receive()太复
	杂可能会触发Out of Gas报错; 如果用call就可以自定义gas执行更复杂的逻辑

    // 定义事件
    event Received(address Sender, uint Value);

    // 接收ETH时释放Received事件
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

	注意: 有些恶意合约, 会在receive() 函数嵌入恶意消耗gas的内容或者使得执行
	故意失败的代码, 导致一些包含退款和转账逻辑的合约不能正常工作, 因此写包含
	退款等逻辑的合约时应格外注意


	回退函数 fallback
	fallback()函数会在调用合约不存在的函数时被触发; 可用于接收ETH, 
	也可以用于代理合约proxy contract(TODO)
	fallback()声明时不需要function关键字, 必须由external修饰, 一般也会
	用payable修饰, 用于接收ETH:
	fallback() external payable { ... }    // fallback


	// 定义 fallback 函数, 被触发时会释放 fallbackCalled 事件
    fallback() external payable{
        emit fallbackCalled(msg.sender, msg.value, msg.data);
    }

	receive 和 fallback 的区别
	receive和fallback都能够用于接收ETH, 触发的规则如下:

			触发fallback() 还是 receive()?
				   接收ETH
					  |
				 msg.data是空？
					/  \
				  是    否
				  /      \
		receive()存在?   fallback()
				/ \
			   是  否
			  /     \
		receive()   fallback()

	合约接收ETH时, msg.data为空且存在receive()时, 会触发receive(), msg.data
	不为空或不存在receive()时, 会触发fallback(), 此时fallback()必须为payable


	receive()和payable fallback()均不存在的时候, 向合约直接发送ETH将会报错
	(仍可以通过带有payable的函数向合约发送ETH) TODO
*/

contract Fallback {
    // 定义事件
    event receivedCalled(address Sender, uint Value);
    event fallbackCalled(address Sender, uint Value, bytes Data);

    // 接收ETH时释放Received事件
    receive() external payable {
        emit receivedCalled(msg.sender, msg.value);
    }

    // fallback
    fallback() external payable{
        emit fallbackCalled(msg.sender, msg.value, msg.data);
    }
}
