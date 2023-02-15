/*
	选择器冲突
	智能合约中函数选择器(selector)是函数签名的哈希的前4个字节, 
	例如mint(address account)的选择器为bytes4(keccak256("mint(address)")),
	即0x6a627842;

	由于函数选择器仅有4个字节, 范围很小, 因此两个不同的函数可能会有相同的
	选择器, 例如下面两个函数:

	contract Foo {
		function burn(uint256) external {}
		function collate_propagate_storage(bytes16) external {}
	}
	函数burn()和collate_propagate_storage()的选择器都为0x42966c68, 是一样的,
	这种情况被称为"选择器冲突"; 在这种情况下, EVM无法通过函数选择器分辨用户
	调用哪个函数, 因此该合约无法通过编译

	由于代理合约和逻辑合约是两个合约, 就算他们之间存在"选择器冲突"也可以
	正常编译, 这可能会导致很严重的安全事故; 举个例子, 如果逻辑合约的a函数
	和代理合约的升级函数的选择器相同, 那么管理人就会在调用a函数的时候, 
	将代理合约升级成一个黑洞合约, 后果不堪设想(TODO: 实践)

	有两个可升级合约标准可解决该问题: 透明代理Transparent Proxy和通用可升
	级代理UUPS


	透明代理
	透明代理的逻辑非常简单: 管理员可能会因为"函数选择器冲突", 在调用逻辑合约
	的函数时, 误调用代理合约的可升级函数; 那么限制管理员的权限, 不让他调用
	任何逻辑合约的函数, 就能解决冲突:
	- 管理员变为工具人, 仅能调用代理合约的可升级函数对合约升级, 不能通过回调
		函数调用逻辑合约
	- 其它用户不能调用可升级函数, 但是可以调用逻辑合约的函数


*/

// 由OpenZeppelin的TransparentUpgradeableProxy简化而成, 不应用于生产
contract TransparentProxy {
    address implementation; // logic合约地址
    address admin; // 管理员
    string public words; // 字符串, 可以通过逻辑合约的函数改变

    // 构造函数, 初始化admin和逻辑合约地址
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // fallback函数, 将调用委托给逻辑合约
    // 不能被admin调用, 避免选择器冲突引发意外
    fallback() external payable {
        require(msg.sender != admin);
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }

    // 升级函数, 改变逻辑合约地址, 只能由admin调用
    function upgrade(address newImplementation) external {
        if (msg.sender != admin) revert(); // TODO: 这种条件语句的写法
        implementation = newImplementation;
    }
}


// 旧逻辑合约
contract Logic1 {
    // 状态变量和proxy合约一致, 防止插槽冲突
    address public implementation;
    address public admin;
    string public words; // 字符串, 可以通过逻辑合约的函数改变

    // 改变proxy中状态变量, 选择器: 0xc2985578
    function foo() public{
        words = "old";
    }
}

// 新逻辑合约
contract Logic2 {
    // 状态变量和proxy合约一致, 防止插槽冲突
    address public implementation;
    address public admin;
    string public words; // 字符串, 可以通过逻辑合约的函数改变

    // 改变proxy中状态变量，选择器: 0xc2985578
    function foo() public{
        words = "new";
    }
}
