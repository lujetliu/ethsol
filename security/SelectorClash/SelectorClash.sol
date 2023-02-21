// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	选择器碰撞
	在以太坊合约中, 函数选择器是函数签名 "<function name>(<function input types>)"
	的哈希值的前4个字节(8位十六进制), 当用户调用智能合约的函数时, calldata 的
	前4个字节就是目标函数的选择器, 决定了调用哪些函数;

	由于函数选择器只有4字节, 非常短, 很容易被碰撞出来: 即很容易找到两个不同
	的函数, 但是他们有着相同的函数选择器; 比如:
	transferFrom(address,address,uint256)
	gasprice_bit_ether(int128)
	就有相同的选择器: 0x23b872dd, 当然也可以写个脚本暴力破解


	以下网站可以查询同一个选择器对应的不同函数:
	1. https://www.4byte.directory/
	2. https://sig.eth.samczsun.com/

	也可以使用以下工具进行暴力破解:
	1. PowerClash: https://github.com/AmazingAng/power-clash

	
	注意: 
	1. 函数选择器很容易被碰撞, 即使改变参数类型, 依然能构造出具有相同选择器的函数
	2. 应该管理好合约函数的权限, 确保拥有特殊权限的合约的函数不能被用户调用

*/

contract SelectorClash {
    bool public solved; // 攻击是否成功

    // 攻击者需要调用这个函数, 但是调用者 msg.sender 必须是本合约
    function putCurEpochConPubKeyBytes(bytes memory _bytes) public {
        require(msg.sender == address(this), "Not Owner");
        solved = true;
    }

    // 有漏洞, 攻击者可以通过改变 _method 变量碰撞函数选择器, 调用目标函数
	// 并完成攻击
    function executeCrossChainTx(
			bytes memory _method, 
			bytes memory _bytes, 
			bytes memory _bytes1, 
			uint64 _num
	) public returns(bool success){

        (success, ) = address(this).call(
			abi.encodePacked(
				bytes4(keccak256(abi.encodePacked(_method, "(bytes,bytes,uint64)"))), 
				abi.encode(_bytes, _bytes1, _num))
		);
    }

	// 攻击方法:
	// 攻击的目标是利用executeCrossChainTx()函数调用合约中的putCurEpochConPubKeyBytes(),
	// 目标函数的选择器为: 0x41973cd9, 观察到executeCrossChainTx()中是利用
	// _method参数和"(bytes,bytes,uint64)"作为函数签名计算的选择器; 因此只需
	// 要选择恰当的_method, 让这里算出的选择器等于0x41973cd9, 通过选择器碰
	// 撞调用目标函数

	// Poly Network黑客事件中, 黑客碰撞出的_method为 f1121318093, 
	// 即f1121318093(bytes,bytes,uint64)的哈希前4位也是 0x41973cd9, 
	// 可以成功的调用函数; 接下来将 f1121318093 转换为bytes类型(字符串
	// 转16进制): 0x6631313231333138303933, 然后作为参数输入到
	// executeCrossChainTx()中; executeCrossChainTx()函数另3个参数不重要,
	// 依次填 0x, 0x, 0 就可以
	// 16进制转换工具: https://www.sojson.com/hexadecimal.html

	// Remix 实验:
	// 1. 部署SelectorClash合约 
	// 2. 调用executeCrossChainTx(), 参数填0x6631313231333138303933, 0x, 0x, 0 发起攻击
	// 3. 查看solved变量的值, 被修改为ture, 攻击成功
}
