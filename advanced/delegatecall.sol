

/*
	delegatecall 委托调用
	delegatecall 与 call 类似, 也是solidity中address类型的低级成员函数; 

	当用户A通过合约B来call合约C的时候, 执行的是合约C的函数, 语境(Context, 
	可以理解为包含变量和状态的环境)也是合约C的:
	msg.sender是B的地址, 并且如果函数改变一些状态变量, 产生的效果会作用于
	合约C的变量上

			 call                  call
	用户A ------------> 合约B ---------------> 合约C
	              Context: 合约B          Context: 合约C
				  msg.sender=A            msg.sender=B
				  msg.value=A给的         msg.value=B给的


	当用户A通过合约B来delegatecall合约C的时候, 执行的是合约C的函数, 
	但是语境仍是合约B的:
	msg.sender是A的地址, 并且如果函数改变一些状态变量, 产生的效果会作用
	于合约B的变量上
	
			 call               delegatecall
	用户A ------------> 合约B ---------------> 合约C
	              Context: 合约B          Context: 合约B
				  msg.sender=A            msg.sender=A
				  msg.value=A给的         msg.value=A给的

	delegatecall 调用规则:
	目标合约地址.delegatecall(二进制编码), 其中二进制编码利用结构化编码函数
	abi.encodeWithSignature获得:
	abi.encodeWithSignature("函数签名", 逗号分隔的具体参数) 
	如: abi.encodeWithSignature("f(uint256,address)", _x, _addr)

	和call不一样, delegatecall在调用合约时可以指定交易发送的gas, 但不能指定
	发送的ETH数额
	注意: delegatecall有安全隐患, 使用时要保证当前合约和目标合约的状态变量
	存储结构相同, 并且目标合约安全, 不然会造成资产损失;

	目前delegatecall主要有两个应用场景:
	1. 代理合约Proxy Contract: 
		将智能合约的存储合约和逻辑合约分开: 
		代理合约(Proxy Contract)存储所有相关的变量, 并且保存逻辑合约的地址;
		所有函数存在逻辑合约(Logic Contract)里, 通过delegatecall执行;
		当升级时, 只需要将代理合约指向新的逻辑合约即可

	2. EIP-2535 Diamonds(钻石): 钻石是一个支持构建可在生产中扩展的模块化
		智能合约系统的标准; 钻石是具有多个实施合同的代理合同; 
		钻石标准简介: (TODO)
		https://eip2535diamonds.substack.com/p/introduction-to-the-diamond-standard

	
	调用结构: 你(A)通过合约B调用目标合约C

	被调用的合约C
	有两个public变量: num和sender, 分别是uint256和address类型; 
	有一个函数, 可以将num设定为传入的_num, 并且将sender设为msg.sender

	// 被调用的合约C
	contract C {
		uint public num;
		address public sender;

		function setVars(uint _num) public payable {
			num = _num;
			sender = msg.sender;
		}
	}

	// 发起调用的合约B
	首先, 合约B和目标合约C的变量存储布局必须相同, 两个变量, 并且顺序为num和sender

	contract B {
		uint public num;
		address public sender

	分别用call和delegatecall来调用合约C的setVars函数, callSetVars函数通过 call
	来调用setVars; 有两个参数_addr和_num, 分别对应合约C的地址和setVars的参数


	// 通过call来调用C的setVars()函数, 将改变合约C里的状态变量
    function callSetVars(address _addr, uint _num) external payable{
        // call setVars()
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
	
	而delegatecallSetVars函数通过delegatecall来调用setVars, 与上面的callSetVars
	函数相同, 有两个参数_addr和_num, 分别对应合约C的地址和setVars的参数

	TODO: Remix 实验
*/
