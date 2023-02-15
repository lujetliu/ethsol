// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;  

/*
	通用可升级代理(UUPS, universal upgradeable proxy standard)

	UUPS 将升级函数放在逻辑合约中, 如果有其它函数与升级函数存在"选择器冲突",
	编译时就会报错, 虽然UUPS相比透明代理更省gas, 但同时其实现也更复杂


	UUPS合约
	如果用户A通过合约B(代理合约)去delegatecall合约C(逻辑合约), 语境仍是
	合约B的语境, msg.sender仍是用户A而不是合约B; 因此, UUPS合约可以将
	升级函数放在逻辑合约中, 并检查调用者是否为管理员
*/

contract UUPSProxy {
    address public implementation; // 逻辑合约地址
    address public admin; // admin地址
    string public words; // 字符串, 可以通过逻辑合约的函数改变

    // 构造函数, 初始化admin和逻辑合约地址
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // fallback函数, 将调用委托给逻辑合约
    fallback() external payable {
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }
}

// UUPS逻辑合约(升级函数写在逻辑合约内)
contract UUPS1{
    // 状态变量和proxy合约一致, 防止插槽冲突
    address public implementation;
    address public admin;
    string public words; // 字符串, 可以通过逻辑合约的函数改变

    // 改变proxy中状态变量, 选择器: 0xc2985578
    function foo() public{
        words = "old";
    }

    // 升级函数, 改变逻辑合约地址, 只能由admin调用; 选择器：0x0900f010
    // UUPS中, 逻辑函数中必须包含升级函数, 不然就不能再升级了
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}

// 新的UUPS逻辑合约
contract UUPS2{
    // 状态变量和proxy合约一致，防止插槽冲突
    address public implementation;
    address public admin;
    string public words; // 字符串，可以通过逻辑合约的函数改变

    // 改变proxy中状态变量, 选择器: 0xc2985578
    function foo() public{
        words = "new";
    }

    // 升级函数, 改变逻辑合约地址, 只能由admin调用; 选择器：0x0900f010
    // UUPS中, 逻辑函数中必须包含升级函数, 不然就不能再升级了
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}
