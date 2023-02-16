// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	调用已部署的合约
	开发者写智能合约来调用其他合约, 这让以太坊网络上的程序可以复用, 从而建立
	繁荣的生态; 很多web3项目依赖于调用其他合约, 如收益农场(yield farming);


	本节主要介绍在已知合约代码(或接口)和地址情况下调用目标合约的函数
*/


interface IOtherContract {
    function getBalance() external returns(uint);
    function setX(uint256 x) external payable;
    function getX() external view returns(uint x);
}

contract OtherContract {
    uint256 private _x = 0; // 状态变量_x
    // 收到eth的事件, 记录amount和gas
    event Log(uint amount, uint gas);

    // 返回合约ETH余额
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }

    // 可以调整状态变量_x的函数, 并且可以往合约转ETH (payable)
    function setX(uint256 x) external payable{
        _x = x;
        // 如果转入ETH, 则释放Log事件
        if(msg.value > 0){
            emit Log(msg.value, gasleft()); // TODO: gasleft
			// TODO: 这是往合约转ETH?
        }
    }

    // 读取_x
    function getX() external view returns(uint x){
        x = _x;
    }
}


contract CallContract{
	// 传入合约地址
    function callSetX(address _Address, uint256 x) external{
        OtherContract(_Address).setX(x);
    }

	// 传入合约变量
    function callGetX(OtherContract _Address) external view returns(uint x){
        x = _Address.getX();
    }

	// 创建合约变量
    function callGetX2(address _Address) external view returns(uint x){
        OtherContract oc = OtherContract(_Address);
        x = oc.getX();
    }

	// 调用合约并发送ETH
    function setXTransferETH(address otherContract, uint256 x) payable external{
        OtherContract(otherContract).setX{value: msg.value}(x);
    }
}

contract MyContract {
	// 0xd9145CCE52D386f254917e481eB44e9943F39138 是 OtherContract 的合约地址
    /* IOtherContract other = IOtherContract(0xd9145CCE52D386f254917e481eB44e9943F39138); */
    OtherContract other = OtherContract(0xd9145CCE52D386f254917e481eB44e9943F39138);
	// 以上方法均可以调用其他合约, 和golang不同的是, 可以用 IOtherContract 创
	// 建合约变量 (TODO: 理解)
    function call_getX() external view returns(uint x){
        x = other.getX();
    }
    function call_setX(uint256 x) external{
        other.setX(x);
    }
}


