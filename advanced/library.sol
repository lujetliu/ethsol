// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;  

/*
	库合约
	
	库函数: (TODO: 库不需要导入?)
	库函数是一种特殊的合约, 为了提升solidity代码的复用性和减少gas而存在; 
	库合约一般都是一些好用的函数合集(库函数), 其和普通合约主要有以下几点
	不同:
	- 不能存在状态变量
	- 不能继承或被继承
	- 不能接收以太币
	- 不可以被销毁

	String 库合约: 将uint256类型转换为相应的string类型的代码库, 样例代码:

	library Strings {

		bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

		**
		* @dev Converts a `uint256` to its ASCII `string` decimal representation.
		*
		function toString(uint256 value) public pure returns (string memory) {
			// Inspired by OraclizeAPI's implementation - MIT licence
			// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

			if (value == 0) {
				return "0";
			}
			uint256 temp = value;
			uint256 digits;
			while (temp != 0) {
				digits++;
				temp /= 10;
			}
			bytes memory buffer = new bytes(digits);
			while (value != 0) {
				digits -= 1;
				buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
				value /= 10;
			}
			return string(buffer);
		}


		**
		* @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
		*
		function toHexString(uint256 value) public pure returns (string memory) {
			if (value == 0) {
				return "0x00";
			}
			uint256 temp = value;
			uint256 length = 0;
			while (temp != 0) {
				length++;
				temp >>= 8;
			}
			return toHexString(value, length);
		}

		**
		* @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
		*
		function toHexString(uint256 value, uint256 length) public pure returns (string memory) {
			bytes memory buffer = new bytes(2 * length + 2);
			buffer[0] = "0";
			buffer[1] = "x";
			for (uint256 i = 2 * length + 1; i > 1; --i) {
				buffer[i] = _HEX_SYMBOLS[value & 0xf];
				value >>= 4;
			}
			require(value == 0, "Strings: hex length insufficient");
			return string(buffer);
		}
	}


	使用库合约:
	1. 利用 using for 指令
		指令using A for B; 可用于附加库函数(从库 A)到任何类型(B); 
		添加完指令后, 库A中的函数会自动添加为B类型变量的成员, 可以直接调用; 
		注意: 在调用的时候, 这个变量会被当作第一个参数传递给函数

		using Strings for uint256;
		function getString1(uint256 _number) public pure returns(string memory){
			// 库函数会自动添加为uint256型变量的成员
			return _number.toHexString();
		}
	
	2. 通过库合约名称调用库函数
		function getString2(uint256 _number) public pure returns(string memory){
			return Strings.toHexString(_number);
		}

	常用库合约:
	- String: 将uint256转换为String
	- Address: 判断某个地址是否为合约地址
	- Create2: 更安全的使用Create2 EVM opcode
	- Arrays: 跟数组相关的库函数

*/




