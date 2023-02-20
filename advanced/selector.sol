/*
	selector
	在调用智能合约的时候, 发送的 calldata 中前4个字节是 selector(函数选择器)

	msg.data
	msg.data是solidity中的一个全局变量, 值为完整的calldata(调用函数时传入的
	数据), 可以通过Log事件来输出调用mint函数的calldata
		// event 返回msg.data
		event Log(bytes data);

		function mint(address to) external{
			emit Log(msg.data);
		}

	method id
	method id定义为函数签名的Keccak哈希后的前4个字节, 当selector与method id相
	匹配时, 即表示调用该函数;

	函数签名
	函数签名为"函数名(逗号分隔的参数类型)", 在同一个智能合约中, 不同的函数
	有不同的函数签名, 因此我们可以通过函数签名来确定要调用哪个函数;
	注意: 在函数签名中, uint和int要写为uint256和int256
	
*/
