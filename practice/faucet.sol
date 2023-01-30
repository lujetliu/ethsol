// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;  

/*
   ERC20水龙头合约
   实现一个简版的ERC20水龙头, 逻辑非常简单: 我们将一些ERC20代币转到水龙头
   合约里, 用户可以通过合约的requestToken()函数来领取100单位的代币, 每个地
   址只能领一次

*/

contract Facuet {
	uint256 public amountAllowed = 100; // 每次领 100 单位代币
	address public tokenContract;   // token合约地址
	mapping(address => bool) public requestedAddress;   // 记录领取过代币的地址


	// SendToken事件, 记录每次领取代币的地址和数量, 在requestTokens()函数
	// 被调用时释放
	event SendToken(address indexed Receiver, uint256 indexed Amount);

	// 部署时设定ERC2代币合约, 初始化tokenContract状态变量, 确定发放的ERC20代币地址
	constructor(address _tokenContract) {
		tokenContract = _tokenContract; // set token contract
	}

	// 用户领取代币函数
	function requestTokens() external {
		require(requestedAddress[msg.sender] == false, "Can't Request Multiple Times!"); // 每个地址只能领一次
		IERC20 token = IERC20(tokenContract); // 创建IERC20合约对象
		require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Empty!"); // 水龙头空了

		token.transfer(msg.sender, amountAllowed); // 发送token
		requestedAddress[msg.sender] = true; // 记录领取地址

		emit SendToken(msg.sender, amountAllowed); // 释放SendToken事件
	}
}
