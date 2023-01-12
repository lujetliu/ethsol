// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	Solidity有三种方法向其他合约发送ETH: transfer(), send()和call(), 其中
	call()是推荐的用法

	接收ETH合约
	先部署一个接收ETH合约ReceiveETH, ReceiveETH合约里有一个事件Log, 
	记录收到的ETH数量和gas剩余; 
	有两个函数
	receive(): 收到ETH被触发, 并发送Log事件;
	getBalance(): 查询合约ETH余额

	contract ReceiveETH {
		// 收到eth事件, 记录amount和gas
		event Log(uint amount, uint gas);
		
		// receive方法, 接收eth时被触发
		receive() external payable{
			emit Log(msg.value, gasleft());
		}
		
		// 返回合约ETH余额
		function getBalance() view public returns(uint) {
			return address(this).balance;
		}
	}

	发送ETH合约
	先在发送ETH合约SendETH中实现payable的构造函数和receive(), 使得能够在部署
	时和部署后向合约转账
	contract SendETH {
		// 构造函数, payable使得部署的时候可以转eth进去
		constructor() payable{}

		// receive方法, 接收eth时被触发
		receive() external payable{}
	}

	transfer
	- 接收方地址.transfer(发送ETH数额)
	- transfer()的gas限制是2300, 足够用于转账, 但对方合约的fallback()
		或receive()函数不能实现太复杂的逻辑(TODO)
	- transfer()如果转账失败, 会自动revert(回滚交易)

	send
	- 接收方地址.send(发送ETH数额)
	- send()的gas限制是2300, 足够用于转账, 但对方合约的fallback()或receive()函数不能实现太复杂的逻辑
	- send()如果转账失败, 不会revert
	- send()的返回值是bool, 代表着转账成功或失败, 需要额外代码处理一下
	
	call
	- 接收方地址.call{value: 发送ETH数额}("")
	- call()没有gas限制, 可以支持对方合约fallback()或receive()函数实现复杂逻辑
	- call()如果转账失败, 不会revert(TODO: 如何处理回滚)
	- call()的返回值是(bool, data), 其中bool代表着转账成功或失败, 需要额外
		代码处理一下
*/

error SendFailed(); // 用send发送ETH失败error
error CallFailed(); // 用call发送ETH失败error

contract SendETH {
	// transfer: 2300 gas, revert
	// send: 2300 gas, return bool
	// call: all gas, return (bool, data)

    // 构造函数, payable使得部署的时候可以转eth进去
    constructor() payable{}

    // receive方法, 接收eth时被触发
    receive() external payable{}

    // transfer()发送ETH
    function transferETH(address payable _to, uint256 amount) external payable{
        _to.transfer(amount);
    }

    // send()发送ETH
    function sendETH(address payable _to, uint256 amount) external payable{
        // 处理下send的返回值, 如果失败, revert交易并发送error
        bool success = _to.send(amount);
         if(!success){
            revert SendFailed();
         }
    }

    // call()发送ETH
    function callETH(address payable _to, uint256 amount) external payable{
        // 处理下call的返回值, 如果失败, revert交易并发送error
        (bool success,) = _to.call{value: amount}("");
        if(!success){
            revert CallFailed();
        }
    }
}

