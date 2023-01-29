/*
	在以太坊中, 数据必须编码成字节码才能和智能合约交互

	ABI(Application Binary Interface, 应用程序二进制接口)是与以太坊智能合约
	交互的标准; 数据基于他们的类型编码, 并且由于编码后不包含类型信息, 解码
	时需要注明它们的类型

	Solidity中ABI编码有4个函数:
	abi.encode
	abi.encodePacked
	abi.encodeWithSignature
	abi.encodeWithSelector

	ABI解码有1个函数:
	abi.decode 用于解码 abi.encode 的数据



	abi.encode
		uint x = 10;
		address addr = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
		string name = "0xAA";
		uint[2] array = [5, 6];


		将给定参数利用ABI规则编码, ABI被设计出来跟智能合约交互, 他将每个参数填充
		为32字节的数据, 并拼接在一起; 如果要和合约交互, 就要使用 abi.encode 
		ABI规则: https://learnblockchain.cn/docs/solidity/abi-spec.html (TODO)
		function encode() public view returns(bytes memory result) {
			result = abi.encode(x, addr, name, array);
		}

		编码的结果: 0x000000000000000000000000000000000000000000000000000000
		000000000a0000000000000000000000007a58c0be72be218b41c608b7fe7c5bb630
		736c7100000000000000000000000000000000000000000000000000000000000000
		a0000000000000000000000000000000000000000000000000000000000000000500
		00000000000000000000000000000000000000000000000000000000000006000000
		00000000000000000000000000000000000000000000000000000000043078414100
		000000000000000000000000000000000000000000000000000000
		由于abi.encode将每个数据都填充为32字节, 中间有很多0
	 
	abi.encodePacked
		将给定参数根据其所需最低空间编码, 类似 abi.encode, 但是会把其中填充的
		很多0省略; 比如, 只用1字节来编码uint类型; 当你想省空间并且不与合约
		交互的时候, 可以使用abi.encodePacked, 例如算一些数据的hash

		function encodePacked() public view returns(bytes memory result) {
			result = abi.encodePacked(x, addr, name, array);
		}


	abi.encodeWithSignature
		与abi.encode功能类似, 只不过第一个参数为函数签名, 
		比如"foo(uint256,address)"; 当调用其他合约的时候可以使用:

		function encodeWithSignature() public view returns(bytes memory result) {
			result = abi.encodeWithSignature("foo(uint256,address,string,uint256[2])", x, addr, name, array);
		}


	abi.encodeWithSelector
		与abi.encodeWithSignature功能类似, 只不过第一个参数为函数选择器, 
		为函数签名Keccak哈希的前4个字节, 其编码结果与 encodeWithSignature 结
		果一样

		function encodeWithSelector() public view returns(bytes memory result) {
			result = abi.encodeWithSelector(bytes4(keccak256("foo(uint256,address,string,uint256[2])")), x, addr, name, array);
		}
		TODO: bytes4 函数

		
	ABI使用场景:
	1. 在合约开发中, ABI常配合call来实现对合约的底层调用
		bytes4 selector = contract.getValue.selector;

		bytes memory data = abi.encodeWithSelector(selector, _x);
		(bool success, bytes memory returnedData) = address(contract).staticcall(data);
		require(success);

		return abi.decode(returnedData, (uint256));

	2. ethers.js中常用ABI实现合约的导入和函数调用
		const wavePortalContract = new ethers.Contract(contractAddress, contractABI, signer);
        // Call the getAllWaves method from your Smart Contract
		const waves = await wavePortalContract.getAllWaves()
	
	3. 对不开源合约进行反编译后, 某些函数无法查到函数签名, 可通过ABI进行调用(TODO)

*/
