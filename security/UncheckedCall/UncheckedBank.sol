// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	低级调用:
	以太坊的低级调用包括 call(), delegatecall(), staticcall(), 和send(); 
	这些函数与 Solidity 其他函数不同, 当出现异常时, 它并不会向上层传递, 
	也不会导致交易完全回滚; 它只会返回一个布尔值 false, 传递调用失败的信息;
	因此如果未检查低级函数调用的返回值, 则无论低级调用失败与否, 上层函数
	的代码会继续运行;

	最容易出错的是send(): 
		一些合约使用 send() 发送 ETH, 但是 send() 限制 gas 要低于 2300(TODO:
	为何有这种限制), 否则会失败; 当目标地址的回调函数比较复杂时, 花费的 gas 将
	高于 2300, 从而导致 send() 失败; 如果此时在上层函数没有检查返回值的话, 
	交易继续执行, 就会出现意想不到的问题

	Remix 复现: TODO: 未在Remix验证
	1. 部署 UncheckedBank 合约
	2. 部署 Attack 合约, 构造函数填入 UncheckedBank 合约地址
	3. 调用 Attack 合约的 deposit() 存款函数, 存入1 ETH
	4. 调用 Attack 合约的 withdraw() 提款函数, 进行提款, 调用成功
	5. 分别调用 UncheckedBank 合约的 balanceOf() 函数和 Attack 合约的 
		getBalance() 函数, 尽管上一步调用成功并且储户余额被清空, 但是提款失败了

	预防:
	1. 检查低级调用的返回值, 在银行合约中, 可以改正 withdraw()
		bool success = payable(msg.sender).send(balance);
		require(success, "Failed Sending ETH!")
	2. 合约转账ETH时, 使用 call(), 并做好重入保护
	3. 使用OpenZeppelin的Address库, 它将检查返回值的低级调用封装好了(TODO)

*/

contract UncheckedBank {
    mapping (address => uint256) public balanceOf;    // 余额mapping

    // 存入ether, 并更新余额
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // 提取msg.sender的全部ether
    function withdraw() external {
        // 获取余额
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");
        balanceOf[msg.sender] = 0;
        // Unchecked low-level call
        bool success = payable(msg.sender).send(balance);
		// 函数没有检查 send() 的返回值, 提款失败但余额会清零
    }

    // 获取银行合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// 攻击合约
contract Attack {
	/*
		TODO: 在 Remix 未能验证
		该攻击合约刻画了一个倒霉的储户, 取款失败但是银行余额清零: 合约回调函数 
		receive() 中的 revert() 将回滚交易, 因此它无法接收 ETH; 但是提款函数 
		withdraw() 却能正常调用, 清空余额
	*/
    UncheckedBank public bank; // Bank合约地址

    // 初始化Bank合约地址
    constructor(UncheckedBank _bank) {
        bank = _bank;
    }

    // 回调函数, 转账ETH时会失败
    receive() external payable {
        revert();
    }

    // 存款函数, 调用时 msg.value 设为存款数量
    function deposit() external payable {
        bank.deposit{value: msg.value}();
    }

    // 取款函数, 虽然调用成功, 但实际上取款失败
    function withdraw() external payable {
        bank.withdraw();
    }

    // 获取本合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
